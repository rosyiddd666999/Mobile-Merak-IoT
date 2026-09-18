String? requiredField(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName tidak boleh kosong';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(value)) return 'Email tidak valid';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.trim().isEmpty) return 'Password tidak boleh kosong';
  if (value.length < 6) return 'Password minimal 6 karakter';
  return null;
}

String? validateSuhu(String? value) {
  if (value == null || value.trim().isEmpty) return 'Tidak boleh kosong';
  final suhu = double.tryParse(value);
  if (suhu == null) return 'Harus berupa angka';
  if (suhu < 0 || suhu > 50) return 'Suhu harus antara 0-50°C';
  return null;
}
