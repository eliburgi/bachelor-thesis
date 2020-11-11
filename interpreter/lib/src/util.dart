class Util {
  static bool isWhiteSpace(String char) {
    return char.trim().isEmpty;
  }

  static bool isDigit(String char) {
    return RegExp(r'^[0-9]$').hasMatch(char);
  }

  static bool isLetter(String char) {
    return RegExp(r'^[A-Za-z]$').hasMatch(char);
  }
}

typedef LogPrinter = Function(String message);
