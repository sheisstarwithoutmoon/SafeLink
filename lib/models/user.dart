import 'emergency_contact.dart';

class User {
  final String id;
  final String name;
  final String phone;
  final String? fcmToken;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.fcmToken,
    List<EmergencyContact>? emergencyContacts,
    DateTime? createdAt,
  })  : emergencyContacts = emergencyContacts ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      fcmToken: json['fcmToken'],
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
              ?.map((contact) => EmergencyContact.fromJson(contact))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'fcmToken': fcmToken,
      'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
