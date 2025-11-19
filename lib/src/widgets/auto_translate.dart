import 'package:flutter/material.dart';
import '../services/translation_service.dart';

/// Wrapper widget that adds automatic translation to any child widget
class AutoTranslate extends StatefulWidget {
  /// The child widget to wrap (usually a Text widget)
  final Widget child;

  /// Override language code (optional, uses global language if not provided)
  final String? languageCode;

  /// Enable or disable translation
  final bool enable;

  /// Custom loading widget while translating
  final Widget? loadingWidget;

  const AutoTranslate({
    super.key,
    required this.child,
    this.languageCode,
    this.enable = true,
    this.loadingWidget,
  });

  @override
  State<AutoTranslate> createState() => _AutoTranslateState();
}

class _AutoTranslateState extends State<AutoTranslate> {
  String? _translatedText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _translateChild();
  }

  @override
  void didUpdateWidget(AutoTranslate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child ||
        oldWidget.languageCode != widget.languageCode ||
        oldWidget.enable != widget.enable) {
      _translateChild();
    }
  }

  Future<void> _translateChild() async {
    if (!widget.enable) {
      setState(() {
        _translatedText = null;
        _isLoading = false;
      });
      return;
    }

    // Extract text from child widget
    final text = _extractTextFromWidget(widget.child);

    if (text == null || text.isEmpty) {
      setState(() {
        _translatedText = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final translated = await TranslationService().translate(
      text,
      targetLang: widget.languageCode,
    );

    if (mounted) {
      setState(() {
        _translatedText = translated;
        _isLoading = false;
      });
    }
  }

  String? _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      if (widget.data != null) {
        return widget.data;
      } else if (widget.textSpan != null) {
        return widget.textSpan!.toPlainText();
      }
    }
    return null;
  }

  Widget _buildTranslatedChild() {
    if (_translatedText == null) {
      return widget.child;
    }

    final child = widget.child;

    // If child is Text widget, create new Text with translated text
    if (child is Text) {
      return Text(
        _translatedText!,
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

    return widget.child;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enable) {
      return widget.child;
    }

    if (_isLoading) {
      return widget.loadingWidget ??
          SizedBox(
            height: 20,
            width: 20,
            child: const Center(
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