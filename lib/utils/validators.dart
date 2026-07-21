class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? minMaxPax(String? value, int minPax) {
    if (value == null || value.trim().isEmpty) {
      return 'Maximum passengers is required';
    }
    final int? pax = int.tryParse(value);
    if (pax == null) {
      return 'Please enter a valid number';
    }
    if (pax < minPax) {
      return 'Maximum cannot be less than minimum ($minPax)';
    }
    if (pax > 14) {
      return 'Maximum cannot exceed 14 passengers';
    }
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pattern = r'^\+?254[0-9]{9}$';
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Enter valid Kenyan phone (e.g., 254712345678)';
    }
    return null;
  }
}
