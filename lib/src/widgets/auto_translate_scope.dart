import 'dart:async';

import 'package:flutter/material.dart';

import '../services/translation_service.dart';

/// Wraps a screen (or a section of it) and displays a single full-screen
/// loader while translations for the visible widgets are being fetched
/// for the first time, or while the language is changing.
///
/// This replaces the per-widget loading/shimmer effect previously rendered
/// by [AutoTranslate] when a translation was being fetched, providing a
/// much smoother UX when the language changes.
///
/// Typical usage:
///
/// ```dart
/// Scaffold(
///   body: AutoTranslateScope(
///     child: MyScreenContents(),
///   ),
/// )
/// ```
///
/// You can customize the loader via [loaderBuilder]. Override
/// [minLoaderDuration] / [maxLoaderDuration] to fine-tune the timing.
class AutoTranslateScope extends StatefulWidget {
  /// The protected subtree. Translation requests issued by descendants
  /// drive the loader visibility.
  final Widget child;

  /// Builder for the loader widget. If `null`, a default centered
  /// [CircularProgressIndicator] over a scaffold-colored background is used.
  final WidgetBuilder? loaderBuilder;

  /// Minimum amount of time the loader stays visible after appearing. Helps
  /// avoid quick "flash" effects when translations resolve immediately from
  /// cache. Defaults to 250 ms.
  final Duration minLoaderDuration;

  /// Maximum amount of time the loader stays visible. After this duration,
  /// the loader is dismissed even if translations are still pending so the
  /// UI never gets stuck. Defaults to 8 seconds.
  final Duration maxLoaderDuration;

  /// If `false`, the scope behaves as a transparent pass-through and never
  /// shows the loader.
  final bool enabled;

  /// Whether to show the loader the very first time the scope is built (in
  /// addition to language-change transitions). Useful to mask the initial
  /// cache miss when entering a screen. Defaults to `true`.
  final bool showOnFirstBuild;

  const AutoTranslateScope({
    super.key,
    required this.child,
    this.loaderBuilder,
    this.minLoaderDuration = const Duration(milliseconds: 250),
    this.maxLoaderDuration = const Duration(seconds: 8),
    this.enabled = true,
    this.showOnFirstBuild = true,
  });

  @override
  State<AutoTranslateScope> createState() => _AutoTranslateScopeState();
}

class _AutoTranslateScopeState extends State<AutoTranslateScope> {
  TranslationService get _service => TranslationService();

  bool _showLoader = false;
  bool _minElapsed = false;
  String? _lastLang;
  Timer? _minTimer;
  Timer? _maxTimer;

  @override
  void initState() {
    super.initState();
    _lastLang = _service.currentLanguage;
    _service.addListener(_onServiceChanged);
    _service.pendingCount.addListener(_onPendingChanged);
    if (widget.enabled && widget.showOnFirstBuild) {
      _startLoading();
    }
  }

  @override
  void didUpdateWidget(covariant AutoTranslateScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _hideLoader();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.pendingCount.removeListener(_onPendingChanged);
    _minTimer?.cancel();
    _maxTimer?.cancel();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    // Detect language changes; that's when we want to flash the loader.
    if (_lastLang != _service.currentLanguage) {
      _lastLang = _service.currentLanguage;
      if (widget.enabled) _startLoading();
    }
  }

  void _onPendingChanged() {
    if (!mounted) return;
    _tryHideLoader();
  }

  void _startLoading() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _minElapsed = false;

    if (!_showLoader) {
      setState(() => _showLoader = true);
    }

    _minTimer = Timer(widget.minLoaderDuration, () {
      _minElapsed = true;
      _tryHideLoader();
    });
    _maxTimer = Timer(widget.maxLoaderDuration, _hideLoader);

    // Allow descendants to register their translation requests before we
    // evaluate whether to dismiss the loader.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryHideLoader());
  }

  void _tryHideLoader() {
    if (!mounted || !_showLoader) return;
    if (_minElapsed && _service.pendingCount.value == 0) {
      _hideLoader();
    }
  }

  void _hideLoader() {
    if (!mounted) return;
    _minTimer?.cancel();
    _maxTimer?.cancel();
    if (_showLoader) {
      setState(() => _showLoader = false);
    }
  }

  Widget _buildLoader(BuildContext context) {
    if (widget.loaderBuilder != null) {
      return widget.loaderBuilder!(context);
    }
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      color: scaffoldColor,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: <Widget>[
        // Always build the subtree so descendant [AutoTranslate] widgets
        // can request their translations even while the loader is visible.
        widget.child,
        if (_showLoader)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: AbsorbPointer(child: _buildLoader(context)),
            ),
          ),
      ],
    );
  }
}
