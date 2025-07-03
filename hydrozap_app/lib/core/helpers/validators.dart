// core/helpers/validators.dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return "Please enter your email";
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return "Enter a valid email address";
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return "Please enter your password";
  }
  if (value.length < 6) {
    return "Password must be at least 6 characters";
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return "Please enter your name";
  }
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return "Please enter your phone number";
  }
  
  // Remove the "+63 " prefix if it exists for validation
  String phoneNumber = value;
  if (phoneNumber.startsWith("+63 ")) {
    phoneNumber = phoneNumber.substring(4); // Remove "+63 "
  }
  
  // Validate the actual phone number (should be 10 digits for Philippine numbers)
  if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber)) {
    return "Enter a valid Philippine phone number (10 digits)";
  }
  return null;
}
String? validateIdentifier(String? value) {
  if (value == null || value.isEmpty) {
    return "Please enter your email or username";
  }

  // Check if it's an email
  bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  
  // Check if it's a valid username (alphanumeric, at least 3 characters)
  bool isUsername = RegExp(r'^[a-zA-Z0-9_]{3,}$').hasMatch(value);

  if (!isEmail && !isUsername) {
    return "Enter a valid email or username";
  }
  return null;
}
