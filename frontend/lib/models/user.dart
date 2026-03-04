/// User model representing a Clerk-authenticated user.
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? phoneNumber;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.phoneNumber,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromClerkSession(Map<String, dynamic> json) {
    // Parse from Clerk's session user object
    final emailAddresses = json['email_addresses'] as List? ?? [];
    final primaryEmail = emailAddresses.isNotEmpty
        ? emailAddresses[0]['email_address'] as String? ?? ''
        : '';

    final phoneNumbers = json['phone_numbers'] as List? ?? [];
    final primaryPhone = phoneNumbers.isNotEmpty
        ? phoneNumbers[0]['phone_number'] as String? ?? ''
        : null;

    return User(
      id: json['id'] as String? ?? '',
      email: primaryEmail,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      phoneNumber: primaryPhone,
    );
  }

  factory User.fromBackendProfile(Map<String, dynamic> json) {
    // Parse from our Django backend profile endpoint
    final nameParts = (json['full_name'] as String? ?? '').split(' ');
    return User(
      id: json['clerk_user_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: nameParts.isNotEmpty ? nameParts.first : '',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      imageUrl: json['image_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'image_url': imageUrl,
    'phone_number': phoneNumber,
  };

  @override
  String toString() => 'User(id: $id, email: $email, name: $fullName)';
}
