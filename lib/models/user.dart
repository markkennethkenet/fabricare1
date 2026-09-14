class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.location = '',
    required this.createdAt,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phone: (map['phone'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'];
    final createdAt = createdAtRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw)
        : DateTime.parse(createdAtRaw as String);

    return User(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: (json['phone'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap({String? passwordHash}) {
    return {
      if (id != 0) 'id': id,
      'full_name': fullName,
      'email': email.toLowerCase().trim(),
      if (passwordHash != null) 'password_hash': passwordHash,
      'phone': phone,
      'location': location,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
