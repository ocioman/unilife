class PasswordValidator {
  static String? validatePassword(String password, {int minLength=8}) {
    final checks={
      'minLength':     password.length >= minLength,
      'hasUppercase':  password.contains(RegExp(r'[A-Z]')),
      'hasLowercase':  password.contains(RegExp(r'[a-z]')),
      'hasDigit':      password.contains(RegExp(r'[0-9]')),
      'hasSpecialChar': password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    };

    if(!checks['minLength']!)    return 'La password deve essere di almeno $minLength caratteri';
    if(!checks['hasUppercase']!)  return 'La password deve contenere almeno una lettera maiuscola';
    if(!checks['hasLowercase']!)  return 'La password deve contenere almeno una lettera minuscola';
    if(!checks['hasDigit']!)      return 'La password deve contenere un numero';
    if(!checks['hasSpecialChar']!) return 'La password deve contenere un carattere speciale';
    return null;
  }
}