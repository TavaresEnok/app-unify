class AppUser {
  final String uid;
  final String email;
  final bool isSuperAdmin;

  const AppUser({
    required this.uid,
    required this.email,
    this.isSuperAdmin = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      isSuperAdmin: json['isSuperAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'email': email, 'isSuperAdmin': isSuperAdmin};
  }
}
