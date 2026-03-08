class UserProfile {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String citizenshipNumber;
  final String? createdAt;

  UserProfile({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.citizenshipNumber,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'citizenship_number': citizenshipNumber,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      citizenshipNumber: map['citizenship_number'] as String? ?? '',
      createdAt: map['created_at'] as String?,
    );
  }

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? citizenshipNumber,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      citizenshipNumber: citizenshipNumber ?? this.citizenshipNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
