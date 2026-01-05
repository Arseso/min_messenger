class ValidationService {
  static String? validateUsername(String? value) {
    final val = value?.trim() ?? "";
    if (val.isEmpty) return "Введите никнейм";
    if (val.length < 3) return "Минимум 3 символа";

    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!regex.hasMatch(val)) {
      return "Только английские буквы и цифры";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final val = value?.trim() ?? "";
    if (val.isEmpty) return "Введите пароль";
    if (val.length < 6) return "Минимум 6 символов";
    return null;
  }
}
