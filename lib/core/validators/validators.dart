class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email address.';
    }
    if (email.length > 254 || email.contains(' ')) {
      return 'Please enter a valid email address.';
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return 'Please enter a valid email address.';
    }

    final localPart = parts[0];
    final domainPart = parts[1].toLowerCase();

    if (localPart.length < 3) {
      return 'Please enter a valid email address.';
    }
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9._]{2,}$').hasMatch(localPart)) {
      return 'Please enter a valid email address.';
    }
    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return 'Please enter a valid email address.';
    }

    if (domainPart != 'gmail.com') {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    if (password.length < 8) {
      return 'The password must be at least 8 characters long.';
    }
    return null;
  }

  static String? validatePasswordForSignIn(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    if (password.length < 8) {
      return 'The password must be at least 8 characters long.';
    }
    return null;
  }

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter your full name.';
    }
    if (name.length < 2 || name.length > 50) {
      return 'Please enter a valid name.';
    }
    if (!RegExp(r"^[A-Za-z][A-Za-z\s\-']*$").hasMatch(name)) {
      return 'Please enter a valid name.';
    }
    return null;
  }
}
