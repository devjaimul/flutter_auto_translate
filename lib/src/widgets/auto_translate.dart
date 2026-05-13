import 'package:flutter/material.dart';

import '../services/translation_service.dart';

/// Wrapper widget that adds automatic translation to its child.
///
/// Supported children:
///   * [Text] — the displayed string is replaced with its translation while
///     preserving all styling.
///   * [TextField] — `hintText`, `labelText`, `helperText`, `errorText`,
///     `prefixText`, `suffixText` and `counterText` from the wrapped field's
///     [InputDecoration] are translated.
///
/// For form fields (or whenever you need finer control over the input
/// constructor), use [AutoTranslateField] instead.
///
/// [AutoTranslate] no longer renders a per-widget loading indicator by
/// default. It reads the cached translation synchronously during build
/// (no flicker) and asynchronously fetches missing translations in the
/// background. Once a translation is available it rebuilds in place. Use
/// [AutoTranslateScope] to show a single, full-screen loader while
/// translations for a screen are being fetched for the first time.
class AutoTranslate extends StatefulWidget {
  /// The child widget to wrap. Supported widgets are [Text] and [TextField].
  /// Other widgets are returned unchanged.
  final Widget child;

  /// Override the target language code. Uses
  /// [TranslationService.currentLanguage] when `null`.
  final String? languageCode;

  /// When `false`, translation is bypassed and [child] is returned as-is.
  final bool enable;

  /// Whether to show an inline loading indicator while the very first
  /// translation for a text is being fetched. Defaults to `false` so the UI
  /// no longer flickers between a spinner and the final text.
  final bool showInlineLoader;

  /// Custom widget shown while loading when [showInlineLoader] is `true`.
  final Widget? loadingWidget;

  const AutoTranslate({
    super.key,
    required this.child,
    this.languageCode,
    this.enable = true,
    this.showInlineLoader = false,
    this.loadingWidget,
  });

  @override
  State<AutoTranslate> createState() => _AutoTranslateState();
}

class _AutoTranslateState extends State<AutoTranslate> {
  TranslationService get _service => TranslationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_handleServiceChanged);
    // Kick off any required translation work after the first frame so any
    // surrounding [AutoTranslateScope] can observe the pending request
    // before deciding to dismiss the screen loader.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestTranslationIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant AutoTranslate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child ||
        oldWidget.languageCode != widget.languageCode ||
        oldWidget.enable != widget.enable) {
      _requestTranslationIfNeeded();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_handleServiceChanged);
    super.dispose();
  }

  void _handleServiceChanged() {
    if (!mounted) return;
    _requestTranslationIfNeeded();
    setState(() {});
  }

  String? _effectiveLanguage() {
    if (!widget.enable) return null;
    return widget.languageCode ?? _service.currentLanguage;
  }

  /// Collects every translatable string contained in [widget.child] so they
  /// can be pre-fetched in a single batch.
  List<String> _collectTexts() {
    final child = widget.child;
    final texts = <String>[];

    if (child is Text) {
      final t = child.data ?? child.textSpan?.toPlainText();
      if (t != null && t.isNotEmpty) texts.add(t);
    } else if (child is TextField) {
      _collectFromDecoration(child.decoration, texts);
    }

    return texts;
  }

  void _collectFromDecoration(InputDecoration? decoration, List<String> out) {
    if (decoration == null) return;
    void add(String? v) {
      if (v != null && v.isNotEmpty) out.add(v);
    }

    add(decoration.hintText);
    add(decoration.labelText);
    add(decoration.helperText);
    add(decoration.errorText);
    add(decoration.prefixText);
    add(decoration.suffixText);
    add(decoration.counterText);
  }

  void _requestTranslationIfNeeded() {
    final lang = _effectiveLanguage();
    if (lang == null) return;
    final texts = _collectTexts();
    if (texts.isEmpty) return;

    for (final text in texts) {
      if (!_service.isCached(text, targetLang: lang)) {
        // Fire and forget. The service deduplicates concurrent requests and
        // notifies listeners (including us) once new entries land in the
        // cache, which triggers a rebuild.
        _service.translate(text, targetLang: lang);
      }
    }
  }

  String? _resolve(String? text) {
    if (text == null || text.isEmpty) return text;
    final lang = _effectiveLanguage();
    if (lang == null) return text;
    return _service.getCached(text, targetLang: lang) ?? text;
  }

  bool get _hasPendingTranslation {
    final lang = _effectiveLanguage();
    if (lang == null) return false;
    for (final t in _collectTexts()) {
      if (!_service.isCached(t, targetLang: lang)) return true;
    }
    return false;
  }

  Widget _buildTranslatedChild() {
    final child = widget.child;

    if (child is Text) {
      final originalText = child.data ?? child.textSpan?.toPlainText();
      final translated = _resolve(originalText) ?? originalText;
      if (translated == null) return child;
      return Text(
        translated,
        key: child.key,
        style: child.style,
        strutStyle: child.strutStyle,
        textAlign: child.textAlign,
        textDirection: child.textDirection,
        locale: child.locale,
        softWrap: child.softWrap,
        overflow: child.overflow,
        textScaler: child.textScaler,
        maxLines: child.maxLines,
        semanticsLabel: child.semanticsLabel,
        textWidthBasis: child.textWidthBasis,
        textHeightBehavior: child.textHeightBehavior,
      );
    }

    if (child is TextField) {
      return _rebuildTextField(child);
    }

    return child;
  }

  InputDecoration? _translateDecoration(InputDecoration? decoration) {
    if (decoration == null) return decoration;
    return decoration.copyWith(
      hintText: _resolve(decoration.hintText),
      labelText: _resolve(decoration.labelText),
      helperText: _resolve(decoration.helperText),
      errorText: _resolve(decoration.errorText),
      prefixText: _resolve(decoration.prefixText),
      suffixText: _resolve(decoration.suffixText),
      counterText: _resolve(decoration.counterText),
    );
  }

  Widget _rebuildTextField(TextField field) {
    return TextField(
      key: field.key,
      controller: field.controller,
      focusNode: field.focusNode,
      decoration: _translateDecoration(field.decoration),
      keyboardType: field.keyboardType,
      textInputAction: field.textInputAction,
      textCapitalization: field.textCapitalization,
      style: field.style,
      strutStyle: field.strutStyle,
      textAlign: field.textAlign,
      textAlignVertical: field.textAlignVertical,
      textDirection: field.textDirection,
      readOnly: field.readOnly,
      showCursor: field.showCursor,
      autofocus: field.autofocus,
      obscuringCharacter: field.obscuringCharacter,
      obscureText: field.obscureText,
      autocorrect: field.autocorrect,
      smartDashesType: field.smartDashesType,
      smartQuotesType: field.smartQuotesType,
      enableSuggestions: field.enableSuggestions,
      maxLines: field.maxLines,
      minLines: field.minLines,
      expands: field.expands,
      maxLength: field.maxLength,
      maxLengthEnforcement: field.maxLengthEnforcement,
      onChanged: field.onChanged,
      onEditingComplete: field.onEditingComplete,
      onSubmitted: field.onSubmitted,
      onAppPrivateCommand: field.onAppPrivateCommand,
      inputFormatters: field.inputFormatters,
      enabled: field.enabled,
      cursorWidth: field.cursorWidth,
      cursorHeight: field.cursorHeight,
      cursorRadius: field.cursorRadius,
      cursorColor: field.cursorColor,
      selectionHeightStyle: field.selectionHeightStyle,
      selectionWidthStyle: field.selectionWidthStyle,
      keyboardAppearance: field.keyboardAppearance,
      scrollPadding: field.scrollPadding,
      dragStartBehavior: field.dragStartBehavior,
      enableInteractiveSelection: field.enableInteractiveSelection,
      selectionControls: field.selectionControls,
      onTap: field.onTap,
      onTapOutside: field.onTapOutside,
      mouseCursor: field.mouseCursor,
      buildCounter: field.buildCounter,
      scrollController: field.scrollController,
      scrollPhysics: field.scrollPhysics,
      autofillHints: field.autofillHints,
      restorationId: field.restorationId,
      // ignore: deprecated_member_use
      scribbleEnabled: field.scribbleEnabled,
      enableIMEPersonalizedLearning: field.enableIMEPersonalizedLearning,
      contextMenuBuilder: field.contextMenuBuilder,
      canRequestFocus: field.canRequestFocus,
      spellCheckConfiguration: field.spellCheckConfiguration,
      magnifierConfiguration: field.magnifierConfiguration,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enable) return widget.child;

    if (widget.showInlineLoader && _hasPendingTranslation) {
      return widget.loadingWidget ??
          const SizedBox(
            height: 20,
            width: 20,
            child: Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
    }

    return _buildTranslatedChild();
  }
}
