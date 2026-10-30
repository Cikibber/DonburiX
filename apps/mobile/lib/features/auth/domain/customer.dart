class Customer {
  const Customer({required this.name, required this.email});

  final String name;
  final String email;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama wajib diisi.';
    if (name.length > 40) return 'Nama maksimal 40 karakter.';
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid.';
    return null;
  }

  Map<String, Object?> toJson() => {'name': name, 'email': email};

  factory Customer.fromJson(Map<String, Object?> json) =>
      Customer(name: json['name']! as String, email: json['email']! as String);
}
