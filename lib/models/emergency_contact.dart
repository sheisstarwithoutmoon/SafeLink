class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
    this.isPrimary = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phoneNumber'] ?? json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isPrimary': isPrimary,
    };
  }
}
