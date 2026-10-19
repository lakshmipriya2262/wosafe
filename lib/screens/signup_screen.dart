import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart' show EmergencyContact;
import 'login_screen.dart' show LoginScreen;

/// Dynamic Contact Item Controller Helper
class DynamicContactItem {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  String relation;

  DynamicContactItem({
    required String name,
    required String phone,
    this.relation = 'Family',
  })  : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Core User Controllers (Empty - No demo prefilled values)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 2. Dynamic Emergency Contacts List (Clean initial inputs, unlimited additions)
  final List<DynamicContactItem> _contacts = [
    DynamicContactItem(name: '', phone: '', relation: 'Father'),
    DynamicContactItem(name: '', phone: '', relation: 'Mother'),
  ];

  final List<String> _relations = [
    'Father',
    'Mother',
    'Sibling',
    'Friend',
    'Guardian',
    'Colleague',
    'Doctor',
    'Neighbor',
    'Friend • Tambaram',
  ];

  // 3. Medical Profile Fields (Backend processed for Emergency Kit Advisory)
  String _selectedBloodGroup = 'O+';
  String _selectedBpStatus = 'Normal'; // Normal, High (Hypertension), Low (Hypotension)
  bool _hasDiabetes = false;
  bool _hasAsthma = false;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _bpStatuses = ['Normal', 'High (Hypertension)', 'Low (Hypotension)'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    for (var c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  /// Adds a new contact card dynamically (Unlimited contacts)
  void _addEmergencyContact() {
    setState(() {
      _contacts.add(
        DynamicContactItem(
          name: '',
          phone: '',
          relation: 'Friend',
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ New Emergency Contact #${_contacts.length} added!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF5B21B6),
      ),
    );
  }

  /// Removes a dynamic contact
  void _removeEmergencyContact(int index) {
    if (_contacts.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 emergency contacts are required for women safety.'),
          backgroundColor: Color(0xFFFF1744),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      final removed = _contacts.removeAt(index);
      removed.dispose();
    });
  }

  /// Live BMI Calculator
  double? _calculateBmi() {
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_weightController.text.trim());
    if (h != null && w != null && h > 0) {
      final hMeters = h / 100.0;
      return w / (hMeters * hMeters);
    }
    return null;
  }

  /// Generates the live Emergency Medical Kit Advisory list
  List<String> _generateAdvisories() {
    final List<String> advisories = [];
    advisories.add('Blood Transfusion Kit: Blood Group $_selectedBloodGroup');

    if (_hasAsthma) {
      advisories.add('🚑 Asthma Alert: Bring Inhaler, Portable Nebulizer & Oxygen Kit');
    }
    if (_selectedBpStatus.toLowerCase().contains('high')) {
      advisories.add('🩺 Hypertension Alert: Prepare Anti-hypertensive meds & BP cuff');
    } else if (_selectedBpStatus.toLowerCase().contains('low')) {
      advisories.add('💧 Hypotension Alert: Prepare IV Normal Saline / Elevation Kit');
    }
    if (_hasDiabetes) {
      advisories.add('🩸 Diabetes Alert: Prepare Glucometer & Fast-acting Glucose / Insulin Kit');
    }
    return advisories;
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please re-enter.'),
          backgroundColor: Color(0xFFFF1744),
        ),
      );
      return;
    }

    // Validate that at least 2 contacts have name and phone
    final validContacts = _contacts
        .where((c) => c.nameController.text.trim().isNotEmpty && c.phoneController.text.trim().isNotEmpty)
        .toList();

    if (validContacts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 2 emergency contacts with names and phone numbers.'),
          backgroundColor: Color(0xFFFF1744),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Save all dynamic contacts, medical profile, asthma advisory, and user info to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsData = validContacts
          .map((c) => {
                'name': c.nameController.text.trim(),
                'phone': c.phoneController.text.trim(),
                'relation': c.relation,
              })
          .toList();

      await prefs.setString('homesafe_emergency_contacts', json.encode(contactsData));
      await prefs.setString('homesafe_user_area', _areaController.text.trim());
      await prefs.setString('wosafe_contacts_json', json.encode(contactsData));
      await prefs.setString('wosafe_user_name', _nameController.text.trim());
      await prefs.setString('wosafe_user_email', _emailController.text.trim());
      await prefs.setString('wosafe_user_phone', _phoneController.text.trim());
      await prefs.setString('wosafe_user_area', _areaController.text.trim());
      await prefs.setString('wosafe_area_name', _areaController.text.trim());
      await prefs.setString('wosafe_user_password', _passwordController.text);
      await prefs.setString('wosafe_password', _passwordController.text);
      await prefs.setString('wosafe_blood_group', _selectedBloodGroup);
      await prefs.setString('wosafe_bp_status', _selectedBpStatus);
      await prefs.setBool('wosafe_has_diabetes', _hasDiabetes);
      await prefs.setBool('wosafe_has_asthma', _hasAsthma);
      await prefs.setDouble('wosafe_height', double.tryParse(_heightController.text.trim()) ?? 160.0);
      await prefs.setDouble('wosafe_weight', double.tryParse(_weightController.text.trim()) ?? 55.0);
      await prefs.setStringList('wosafe_medical_advisories', _generateAdvisories());
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }

    final contactsList = validContacts
        .map((c) => EmergencyContact(
              name: c.nameController.text.trim(),
              phone: c.phoneController.text.trim(),
              relation: c.relation,
            ))
        .toList();

    final success = await auth.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      bloodGroup: _selectedBloodGroup,
      bloodPressure: _selectedBpStatus,
      hasDiabetes: _hasDiabetes,
      hasAsthma: _hasAsthma,
      height: double.tryParse(_heightController.text.trim()) ?? 160.0,
      weight: double.tryParse(_weightController.text.trim()) ?? 55.0,
      emergencyContacts: contactsList,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✓ Profile & Medical Emergency Kit saved! Please login.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00C853),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed. Please try again.'),
          backgroundColor: const Color(0xFFFF1744),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBmi();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E1B4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account (சைன் அப்)',
          style: TextStyle(
            color: Color(0xFF5B21B6),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B21B6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Wosafe IoT Safety Registration',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Data used for dynamic GPS tracking & hospital medical kit advisories',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============================================================
                // 1. PERSONAL DETAILS (நேம், ஈமெயில், போன், ஏரியா)
                // ============================================================
                const Text(
                  '1. Personal Details (தனிப்பட்ட விவரங்கள்)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name (முழு பெயர்)',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email ID (மின்னஞ்சல் முகவரி)',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your email';
                    if (!val.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number (மொபைல் எண்)',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _areaController,
                  labelText: 'Area Name / Route (ஏரியா பெயர் - e.g. Tambaram / OMR)',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your current area / locality' : null,
                ),
                const SizedBox(height: 24),

                // ============================================================
                // 2. EMERGENCY CONTACTS (அன்லிமிட்டட் எமர்ஜென்சி காண்டாக்ட்ஸ்)
                // ============================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. Emergency Contacts (அவசர தொடர்புகள்)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          '${_contacts.length} Contacts Added (Unlimited Support)',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // + Add Contact Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _addEmergencyContact,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dynamic Contact Cards List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final isMandatory = index < 2;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEDE9FE),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF5B21B6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMandatory ? 'Contact #${index + 1} (Required)' : 'Contact #${index + 1} (Custom)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isMandatory ? const Color(0xFF1E1B4B) : const Color(0xFF7C3AED),
                                ),
                              ),
                              const Spacer(),
                              if (!isMandatory)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF1744), size: 20),
                                  onPressed: () => _removeEmergencyContact(index),
                                  tooltip: 'Delete Contact',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Name Field
                          CustomTextField(
                            controller: contact.nameController,
                            labelText: 'Contact Name (பெயர் - e.g. Dad, Mom, Friend)',
                            prefixIcon: Icons.person_rounded,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter contact name' : null,
                          ),
                          const SizedBox(height: 10),

                          // Phone & Relation in Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: CustomTextField(
                                  controller: contact.phoneController,
                                  labelText: 'Phone (எண்)',
                                  prefixIcon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _relations.contains(contact.relation) ? contact.relation : _relations.first,
                                  decoration: InputDecoration(
                                    labelText: 'Relation',
                                    labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11.5)))).toList(),
                                  onChanged: (val) => setState(() => contact.relation = val ?? 'Family'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // ============================================================
                // 3. MEDICAL PROFILE (ஆஸ்துமா, ஐபிபி, சுகர், ஹைட், வெயிட், பிளட் குரூப்)
                // ============================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.medical_services_rounded, color: Color(0xFF7C3AED), size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '3. Medical Profile & Hospital Advisory (மருத்துவ விவரங்கள்)',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This data is processed by the backend during an SOS alert so responding ambulances carry the exact medical kit needed.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 16),

                      // Blood Group & Blood Pressure
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBloodGroup,
                              decoration: InputDecoration(
                                labelText: 'Blood Group (இரத்த வகை)',
                                labelStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                filled: true,
                                fillColor: const Color(0xFFFBFBFE),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (val) => setState(() => _selectedBloodGroup = val ?? 'O+'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBpStatus,
                              decoration: InputDecoration(
                                labelText: 'BP Level (இரத்த அழுத்தம்)',
                                labelStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                filled: true,
                                fillColor: const Color(0xFFFBFBFE),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              items: _bpStatuses.map((bp) => DropdownMenuItem(value: bp, child: Text(bp, style: const TextStyle(fontSize: 11.5)))).toList(),
                              onChanged: (val) => setState(() => _selectedBpStatus = val ?? 'Normal'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Height & Weight
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _heightController,
                              labelText: 'Height (செ.மீ / cm)',
                              prefixIcon: Icons.height_rounded,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter height' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _weightController,
                              labelText: 'Weight (கிலோ / kg)',
                              prefixIcon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter weight' : null,
                            ),
                          ),
                        ],
                      ),
                      if (bmi != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Calculated BMI: ${bmi.toStringAsFixed(1)} (${bmi < 18.5 ? "Underweight" : bmi < 25 ? "Normal Weight" : "Overweight"})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Asthma Toggle (ஆஸ்துமா இருக்கா இல்லையா)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hasAsthma ? const Color(0xFFFFF0F5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _hasAsthma ? const Color(0xFFE91E63) : const Color(0xFFE2E8F0)),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Asthma / Respiratory Condition? (ஆஸ்துமா உள்ளதா?)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                          ),
                          subtitle: Text(
                            _hasAsthma
                                ? 'YES: Responders will bring Inhaler & Portable Nebulizer'
                                : 'NO: Standard respiratory support',
                            style: TextStyle(
                              fontSize: 11,
                              color: _hasAsthma ? const Color(0xFFE91E63) : const Color(0xFF6B7280),
                              fontWeight: _hasAsthma ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: _hasAsthma,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (val) => setState(() => _hasAsthma = val),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Diabetes / Sugar Toggle (சுகர் உள்ளதா?)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hasDiabetes ? const Color(0xFFFFF0F5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _hasDiabetes ? const Color(0xFFE91E63) : const Color(0xFFE2E8F0)),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Diabetes / Sugar Condition? (சுகர் உள்ளதா?)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                          ),
                          subtitle: Text(
                            _hasDiabetes
                                ? 'YES: Responders prepare Glucometer & Fast Glucose Kit'
                                : 'NO: Normal glucose protocols',
                            style: TextStyle(
                              fontSize: 11,
                              color: _hasDiabetes ? const Color(0xFFE91E63) : const Color(0xFF6B7280),
                              fontWeight: _hasDiabetes ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: _hasDiabetes,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (val) => setState(() => _hasDiabetes = val),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ============================================================
                // 4. ACCOUNT SECURITY (பாஸ்வேர்ட் & கன்பர்ம் பாஸ்வேர்ட்)
                // ============================================================
                const Text(
                  '4. Account Security (பாதுகாப்பு)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(0, 206, 8, 94),
                  ),
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password (கடவுச்சொல்)',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter a password';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password (மீண்டும் கடவுச்சொல்)',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please confirm your password';
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 26),

                // Submit Button
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return GradientButton(
                      text: 'Create Account (பதிவு செய்க)',
                      isLoading: auth.isLoading,
                      onPressed: _handleSignUp,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Already have account? Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13.5),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login (உள்நுழைக)',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SELF-CONTAINED REUSABLE WIDGETS (NO EXTERNAL WIDGET DEPENDENCY ERRORS)
// ============================================================================

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText || isPassword,
      keyboardType: keyboardType,
      validator: validator ??
          (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter ${labelText ?? hintText ?? 'this field'}';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFFE91E63), size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFE91E63)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}