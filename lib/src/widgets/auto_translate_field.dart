import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/translation_service.dart';

/// A [TextField]-shaped widget that automatically translates the strings in
/// its [InputDecoration] (`hintText`, `labelText`, `helperText`, `errorText`,
/// `prefixText`, `suffixText`, `counterText`).
///
/// This is the recommended way to translate input field hints. Use it as a
/// drop-in replacement for [TextField]:
///
/// ```dart
/// AutoTranslateField(
///   controller: searchController,
///   decoration: const InputDecoration(
///     hintText: 'Search products',
///     labelText: 'Search',
///   ),
/// )
/// ```
///
/// The widget listens to [TranslationService] and rebuilds automatically
/// when the language changes — there is no need to call [State.setState]
/// from the surrounding screen.
///
/// To translate form fields, use [AutoTranslateFormField] which exposes the
/// same `decoration` translation behaviour on top of [TextFormField].
class AutoTranslateField extends StatefulWidget {
  /// Override the global language code. Falls back to the service's
  /// current language when `null`.
  final String? languageCode;

  /// Disable translation entirely (renders the field as a plain
  /// [TextField]).
  final bool enableTranslation;

  /// All standard [TextField] properties. They are forwarded as-is.
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool? showCursor;
  final bool autofocus;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final MouseCursor? mouseCursor;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;

  const AutoTranslateField({
    super.key,
    this.languageCode,
    this.enableTranslation = true,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.onTap,
    this.onTapOutside,
    this.mouseCursor,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
  });

  @override
  State<AutoTranslateField> createState() => _AutoTranslateFieldState();
}

class _AutoTranslateFieldState extends State<AutoTranslateField> {
  TranslationService get _service => TranslationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPendingTranslations();
    });
  }

  @override
  void didUpdateWidget(covariant AutoTranslateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decoration != widget.decoration ||
        oldWidget.languageCode != widget.languageCode ||
        oldWidget.enableTranslation != widget.enableTranslation) {
      _requestPendingTranslations();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    _requestPendingTranslations();
    setState(() {});
  }

  String? _effectiveLanguage() {
    if (!widget.enableTranslation) return null;
    return widget.languageCode ?? _service.currentLanguage;
  }

  void _requestPendingTranslations() {
    final lang = _effectiveLanguage();
    if (lang == null) return;
    final decoration = widget.decoration;
    if (decoration == null) return;
    for (final text in <String?>[
      decoration.hintText,
      decoration.labelText,
      decoration.helperText,
      decoration.errorText,
      decoration.prefixText,
      decoration.suffixText,
      decoration.counterText,
    ]) {
      if (text == null || text.isEmpty) continue;
      if (!_service.isCached(text, targetLang: lang)) {
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

  InputDecoration? _translatedDecoration() {
    final decoration = widget.decoration;
    if (decoration == null) return decoration;
    if (!widget.enableTranslation) return decoration;
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: _translatedDecoration(),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      mouseCursor: widget.mouseCursor,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      restorationId: widget.restorationId,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
    );
  }
}

/// A [TextFormField]-shaped widget that translates strings in its
/// [InputDecoration] the same way [AutoTranslateField] does.
///
/// Forwards the most common [TextFormField] properties so it can be used as
/// a drop-in replacement in `Form` widgets.
class AutoTranslateFormField extends StatefulWidget {
  final String? languageCode;
  final bool enableTranslation;

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final bool readOnly;
  final bool? showCursor;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final AutovalidateMode? autovalidateMode;
  final ScrollController? scrollController;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  final MouseCursor? mouseCursor;

  const AutoTranslateFormField({
    super.key,
    this.languageCode,
    this.enableTranslation = true,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.scrollPhysics,
    this.autofillHints,
    this.autovalidateMode,
    this.scrollController,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.mouseCursor,
  });

  @override
  State<AutoTranslateFormField> createState() => _AutoTranslateFormFieldState();
}

class _AutoTranslateFormFieldState extends State<AutoTranslateFormField> {
  TranslationService get _service => TranslationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPendingTranslations();
    });
  }

  @override
  void didUpdateWidget(covariant AutoTranslateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decoration != widget.decoration ||
        oldWidget.languageCode != widget.languageCode ||
        oldWidget.enableTranslation != widget.enableTranslation) {
      _requestPendingTranslations();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    _requestPendingTranslations();
    setState(() {});
  }

  String? _effectiveLanguage() {
    if (!widget.enableTranslation) return null;
    return widget.languageCode ?? _service.currentLanguage;
  }

  void _requestPendingTranslations() {
    final lang = _effectiveLanguage();
    if (lang == null) return;
    final decoration = widget.decoration;
    if (decoration == null) return;
    for (final text in <String?>[
      decoration.hintText,
      decoration.labelText,
      decoration.helperText,
      decoration.errorText,
      decoration.prefixText,
      decoration.suffixText,
      decoration.counterText,
    ]) {
      if (text == null || text.isEmpty) continue;
      if (!_service.isCached(text, targetLang: lang)) {
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

  InputDecoration? _translatedDecoration() {
    final decoration = widget.decoration;
    if (decoration == null) return decoration;
    if (!widget.enableTranslation) return decoration;
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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      decoration: _translatedDecoration() ?? const InputDecoration(),
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      autovalidateMode: widget.autovalidateMode,
      scrollController: widget.scrollController,
      restorationId: widget.restorationId,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      mouseCursor: widget.mouseCursor,
    );
  }
}
