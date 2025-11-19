/// Language model with name, code, and flag
class LanguageModel {
  final String name;
  final String code;
  final String flag;

  const LanguageModel({
    required this.name,
    required this.code,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LanguageModel &&
              runtimeType == other.runtimeType &&
              code == other.code;

  @override
  int get hashCode => code.hashCode;
}