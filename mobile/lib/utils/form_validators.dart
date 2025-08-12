import 'package:formz/formz.dart';

/// Validation errors for email field
enum EmailValidationError {
  empty,
  invalid,
}

/// Validation errors for password field
enum PasswordValidationError {
  empty,
  tooShort,
  tooWeak,
}

/// Validation errors for confirm password field
enum ConfirmPasswordValidationError {
  empty,
  mismatch,
}

/// Validation errors for name fields
enum NameValidationError {
  empty,
  tooShort,
  invalid,
}

/// Validation errors for phone field
enum PhoneValidationError {
  empty,
  invalid,
}

/// Email form input validation
class Email extends FormzInput<String, EmailValidationError> {
  const Email.pure() : super.pure('');
  const Email.dirty([super.value = '']) : super.dirty();

  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  @override
  EmailValidationError? validator(String? value) {
    if (value == null || value.isEmpty) return EmailValidationError.empty;
    return _emailRegExp.hasMatch(value) ? null : EmailValidationError.invalid;
  }
}

/// Password form input validation
class Password extends FormzInput<String, PasswordValidationError> {
  const Password.pure() : super.pure('');
  const Password.dirty([super.value = '']) : super.dirty();

  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  @override
  PasswordValidationError? validator(String? value) {
    if (value == null || value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 8) return PasswordValidationError.tooShort;
    if (!_passwordRegExp.hasMatch(value)) return PasswordValidationError.tooWeak;
    return null;
  }
}

/// Simple password validation for login (less strict)
class LoginPassword extends FormzInput<String, PasswordValidationError> {
  const LoginPassword.pure() : super.pure('');
  const LoginPassword.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String? value) {
    if (value == null || value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 6) return PasswordValidationError.tooShort;
    return null;
  }
}

/// Confirm password form input validation
class ConfirmPassword extends FormzInput<String, ConfirmPasswordValidationError> {
  const ConfirmPassword.pure({this.password = ''}) : super.pure('');
  const ConfirmPassword.dirty({required this.password, String value = ''}) : super.dirty(value);

  final String password;

  @override
  ConfirmPasswordValidationError? validator(String? value) {
    if (value == null || value.isEmpty) return ConfirmPasswordValidationError.empty;
    return password == value ? null : ConfirmPasswordValidationError.mismatch;
  }
}

/// First name form input validation
class FirstName extends FormzInput<String, NameValidationError> {
  const FirstName.pure() : super.pure('');
  const FirstName.dirty([super.value = '']) : super.dirty();

  static final RegExp _nameRegExp = RegExp(r"^[a-zA-Z]+(?:[\s\-'][a-zA-Z]+)*$");

  @override
  NameValidationError? validator(String? value) {
    if (value == null || value.isEmpty) return NameValidationError.empty;
    if (value.trim().length < 2) return NameValidationError.tooShort;
    return _nameRegExp.hasMatch(value.trim()) ? null : NameValidationError.invalid;
  }
}

/// Last name form input validation
class LastName extends FormzInput<String, NameValidationError> {
  const LastName.pure() : super.pure('');
  const LastName.dirty([super.value = '']) : super.dirty();

  static final RegExp _nameRegExp = RegExp(r"^[a-zA-Z]+(?:[\s\-'][a-zA-Z]+)*$");

  @override
  NameValidationError? validator(String? value) {
    if (value == null || value.isEmpty) return NameValidationError.empty;
    if (value.trim().length < 2) return NameValidationError.tooShort;
    return _nameRegExp.hasMatch(value.trim()) ? null : NameValidationError.invalid;
  }
}

/// Phone number form input validation
class Phone extends FormzInput<String, PhoneValidationError> {
  const Phone.pure() : super.pure('');
  const Phone.dirty([super.value = '']) : super.dirty();

  static final RegExp _phoneRegExp = RegExp(
    r'^\+?1?[-.\s]?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}$',
  );

  @override
  PhoneValidationError? validator(String? value) {
    // Phone is optional, so empty is valid
    if (value == null || value.isEmpty) return null;
    return _phoneRegExp.hasMatch(value.replaceAll(RegExp(r'\s+'), '')) ? null : PhoneValidationError.invalid;
  }
}

/// Extension methods for validation error messages
extension EmailValidationErrorX on EmailValidationError {
  String get text {
    switch (this) {
      case EmailValidationError.empty:
        return 'Email is required';
      case EmailValidationError.invalid:
        return 'Please enter a valid email address';
    }
  }
}

extension PasswordValidationErrorX on PasswordValidationError {
  String get text {
    switch (this) {
      case PasswordValidationError.empty:
        return 'Password is required';
      case PasswordValidationError.tooShort:
        return 'Password must be at least 8 characters';
      case PasswordValidationError.tooWeak:
        return 'Password must contain uppercase, lowercase, number, and special character';
    }
  }
}

extension ConfirmPasswordValidationErrorX on ConfirmPasswordValidationError {
  String get text {
    switch (this) {
      case ConfirmPasswordValidationError.empty:
        return 'Confirm password is required';
      case ConfirmPasswordValidationError.mismatch:
        return 'Passwords do not match';
    }
  }
}

extension NameValidationErrorX on NameValidationError {
  String get text {
    switch (this) {
      case NameValidationError.empty:
        return 'Name is required';
      case NameValidationError.tooShort:
        return 'Name must be at least 2 characters';
      case NameValidationError.invalid:
        return 'Please enter a valid name';
    }
  }
}

extension PhoneValidationErrorX on PhoneValidationError {
  String get text {
    switch (this) {
      case PhoneValidationError.empty:
        return 'Phone number is required';
      case PhoneValidationError.invalid:
        return 'Please enter a valid phone number';
    }
  }
}

/// Helper class for form validation utilities
class FormValidationHelpers {
  static bool isFormValid(List<FormzInput> inputs) {
    return inputs.every((input) => input.isValid);
  }

  static bool hasAnyError(List<FormzInput> inputs) {
    return inputs.any((input) => input.isNotValid);
  }

  static String? getFirstError(List<FormzInput> inputs) {
    for (final input in inputs) {
      if (input.isNotValid && input.error != null) {
        return _getErrorText(input);
      }
    }
    return null;
  }

  static String? _getErrorText(FormzInput input) {
    final error = input.error;
    if (error is EmailValidationError) return error.text;
    if (error is PasswordValidationError) return error.text;
    if (error is ConfirmPasswordValidationError) return error.text;
    if (error is NameValidationError) return error.text;
    if (error is PhoneValidationError) return error.text;
    return null;
  }
}

/// Basic form validators for simple use cases
class FormValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'Please enter a valid positive number';
    }
    return null;
  }
}