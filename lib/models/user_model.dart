// ==========================================
// 1. EMERGENCY CONTACT MODEL
// ==========================================
class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Family',
    );
  }

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relation,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
    );
  }
}

// ==========================================
// 2. USER MODEL (WITH MEDICAL ADVISORY)
// ==========================================
class UserModel {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String bloodGroup;
  final String bloodPressure;
  final bool hasDiabetes;
  final bool hasAsthma;
  final double height;
  final double weight;
  final List<EmergencyContact> emergencyContacts;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.bloodGroup = 'O+',
    this.bloodPressure = 'Normal',
    this.hasDiabetes = false,
    this.hasAsthma = false,
    this.height = 160.0,
    this.weight = 55.0,
    List<EmergencyContact>? emergencyContacts,
  }) : emergencyContacts = emergencyContacts ?? [];

  /// Generates tailored medical kit advisories for emergency responders
  List<String> getEmergencyKitAdvisories() {
    final List<String> advisories = [];

    // Blood Group Advisory
    advisories.add('Blood Transfusion Prep: Blood Group $bloodGroup');

    // Asthma kit advisory
    if (hasAsthma) {
      advisories.add('Asthma / Respiratory Alert: Bring Inhaler & Portable Nebulizer / Oxygen Kit');
    }

    // Blood Pressure advisory
    if (bloodPressure.toLowerCase().contains('high')) {
      advisories.add('Hypertension Alert: Prepare Anti-hypertensive kit & BP cuff');
    } else if (bloodPressure.toLowerCase().contains('low')) {
      advisories.add('Hypotension Alert: Prepare IV Fluids / Elevation kit');
    }

    // Diabetes advisory
    if (hasDiabetes) {
      advisories.add('Diabetes Alert: Prepare Glucometer & Fast-acting Glucose / Insulin Kit');
    }

    return advisories;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'bloodGroup': bloodGroup,
      'bloodPressure': bloodPressure,
      'hasDiabetes': hasDiabetes,
      'hasAsthma': hasAsthma,
      'height': height,
      'weight': weight,
      'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var contactsJson = json['emergencyContacts'] as List? ?? [];
    List<EmergencyContact> contacts = contactsJson
        .map((c) => EmergencyContact.fromJson(Map<String, dynamic>.from(c)))
        .toList();

    return UserModel(
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      password: json['password'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? 'O+',
      bloodPressure: json['bloodPressure'] as String? ?? 'Normal',
      hasDiabetes: json['hasDiabetes'] as bool? ?? false,
      hasAsthma: json['hasAsthma'] as bool? ?? false,
      height: (json['height'] as num?)?.toDouble() ?? 160.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 55.0,
      emergencyContacts: contacts,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? password,
    String? bloodGroup,
    String? bloodPressure,
    bool? hasDiabetes,
    bool? hasAsthma,
    double? height,
    double? weight,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasAsthma: hasAsthma ?? this.hasAsthma,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}