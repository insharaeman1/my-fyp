/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Iske liye 'intl' package pubspec.yaml mein add hona chahiye
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatefulWidget {
  const VaccinatorScreen({super.key});

  @override
  State<VaccinatorScreen> createState() => _VaccinatorScreenState();
}

class _VaccinatorScreenState extends State<VaccinatorScreen> {
  static const Color primaryBlue = Color(0xFF004AAD);
  static const Color accentBlue = Color(0xFFEBF2FF);
  static const Color surfaceWhite = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  // Selection Variables
  String? _selectedVaccine;
  String? _selectedDose;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Dropdown Lists
  final List<String> _vaccines = ['BCG', 'Polio', 'Hepatitis B', 'Measles', 'Pentavalent'];
  final List<String> _doses = ['Dose 1', 'Dose 2', 'Dose 3', 'Booster'];

  // --- Date Picker Function ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // --- Time Picker Function ---
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _showVaccinatorDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder for inner state updates
        builder: (context, setPopupState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Session Details", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Vaccinator ID", _idController, Icons.badge),
                  _buildTextField("Vaccinator Name", _nameController, Icons.person),
                  
                  // Vaccine Dropdown
                  _buildDropdown("Select Vaccine", _selectedVaccine, _vaccines, (val) {
                    setPopupState(() => _selectedVaccine = val);
                  }),

                  // Dose Dropdown
                  _buildDropdown("Select Dose", _selectedDose, _doses, (val) {
                    setPopupState(() => _selectedDose = val);
                  }),

                  // Date Picker Trigger
                  _buildPickerTile(
                    _selectedDate == null ? "Select Date" : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                    Icons.calendar_month, 
                    () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setPopupState(() => _selectedDate = picked);
                    }
                  ),

                  // Time Picker Trigger
                  _buildPickerTile(
                    _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                    Icons.access_time, 
                    () async {
                      TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (picked != null) setPopupState(() => _selectedTime = picked);
                    }
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Details Saved")));
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- Helper Widget: Text Field ---
  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // --- Helper Widget: Dropdown ---
  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.list_alt, color: primaryBlue, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        hint: Text(hint),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // --- Helper Widget: Picker Tile ---
  Widget _buildPickerTile(String text, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryBlue, size: 20),
              const SizedBox(width: 12),
              Text(text, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Baaki functions deleteRecord, buildHeader, buildStatCard, etc. same rahengy)

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('vaccinations').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted"), backgroundColor: Colors.redAccent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {
              if (!childSnapshot.hasData || !vacSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              final childrenDocs = childSnapshot.data!.docs;
              final vacDocs = vacSnapshot.data!.docs;

              int completed = 0, refused = 0, absent = 0;
              Set<String> vaccinatedChildren = {};

              for (var doc in vacDocs) {
                final data = doc.data() as Map<String, dynamic>;
                String status = (data['status'] ?? "").toString().toLowerCase();
                if (status == "completed") {
                  completed++;
                  vaccinatedChildren.add((data['childId'] ?? doc.id).toString());
                } else if (status == "refused") refused++;
                else if (status == "absent") absent++;
              }

              int targetCount = childrenDocs.length - vaccinatedChildren.length;
              if (targetCount < 0) targetCount = 0;

              return Column(
                children: [
                  _buildHeader(context),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, const Color(0xFF059669), Icons.verified_user),
                          _buildStatCard("Refused", refused, const Color(0xFFDC2626), Icons.block),
                          _buildStatCard("Absent", absent, const Color(0xFFD97706), Icons.person_off),
                          _buildStatCard("Target", targetCount, primaryBlue, Icons.track_changes),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _actionButton(context, "Vaccination Entry", Icons.qr_code_scanner, primaryBlue, const VaccinationEntryPage())),
                        const SizedBox(width: 12),
                        Expanded(child: _actionButton(context, "Register Child", Icons.person_add_alt_1, primaryBlue, const ChildRegistrationPage())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vacDocs.length,
                      itemBuilder: (context, index) {
                        final data = vacDocs[index].data() as Map<String, dynamic>;
                        return _buildListItem(context, data, vacDocs[index].id);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
      decoration: const BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
              IconButton(onPressed: _showVaccinatorDetailsDialog, icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28)),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Vaccinator Dashboard", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> data, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: accentBlue, child: Icon(Icons.person, color: primaryBlue)),
        title: Text(data['childName'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${data['vaccineType']} • ${data['status']}"),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteRecord(context, docId)),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 12),
        Text("$count", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.black45, fontSize: 13)),
      ]),
    );
  }

  Widget _actionButton(BuildContext context, String text, IconData icon, Color color, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)]),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'vaccination_entry.dart';
import 'child_registration.dart';

class VaccinatorScreen extends StatefulWidget {
  const VaccinatorScreen({super.key});

  @override
  State<VaccinatorScreen> createState() => _VaccinatorScreenState();
}

class _VaccinatorScreenState extends State<VaccinatorScreen> {
  static const Color primaryBlue = Color(0xFF004AAD);
  static const Color accentBlue = Color(0xFFEBF2FF);
  static const Color surfaceWhite = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  String? _selectedVaccine;
  String? _selectedDose;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _vaccines = ['BCG', 'OPV', 'IPV', 'Pentavalent', 'PCV', 'Rotavirus', 'Measles/MR', 'Hepatitis B'];
  final List<String> _doses = ['Dose 1', 'Dose 2', 'Dose 3', 'Dose4'];

  // --- Firebase Save Function ---
  Future<void> _saveSessionToFirestore() async {
    if (_idController.text.isEmpty || _selectedVaccine == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required details"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('vaccinator_sessions').add({
        'vaccinatorId': _idController.text.trim(),
        'vaccinatorName': _nameController.text.trim(),
        'vaccineType': _selectedVaccine,
        'dose': _selectedDose,
        'scheduledDate': _selectedDate, // Stores as Timestamp
        'scheduledTime': _selectedTime != null ? "${_selectedTime!.hour}:${_selectedTime!.minute}" : "",
        'timestamp': FieldValue.serverTimestamp(),
      });

      /*ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session Stored Successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }*/
        // ✅ Fixed
       if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session Stored Successfully!"), backgroundColor: Colors.green),
    );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showVaccinatorDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Session Details", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Vaccinator ID", _idController, Icons.badge),
                  _buildTextField("Vaccinator Name", _nameController, Icons.person),
                  _buildDropdown("Select Vaccine", _selectedVaccine, _vaccines, (val) {
                    setPopupState(() => _selectedVaccine = val);
                  }),
                  _buildDropdown("Select Dose", _selectedDose, _doses, (val) {
                    setPopupState(() => _selectedDose = val);
                  }),
                  _buildPickerTile(
                    _selectedDate == null ? "Select Date" : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                    Icons.calendar_month, 
                    () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setPopupState(() => _selectedDate = picked);
                    }
                  ),
                  _buildPickerTile(
                    _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                    Icons.access_time, 
                    () async {
                      TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (picked != null) setPopupState(() => _selectedTime = picked);
                    }
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                onPressed: () async {
                  await _saveSessionToFirestore();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.list_alt, color: primaryBlue, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        hint: Text(hint),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPickerTile(String text, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryBlue, size: 20),
              const SizedBox(width: 12),
              Text(text, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('vaccinations').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted"), backgroundColor: Colors.redAccent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceWhite,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('children').snapshots(),
        builder: (context, childSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vaccinations').snapshots(),
            builder: (context, vacSnapshot) {
              if (!childSnapshot.hasData || !vacSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              final childrenDocs = childSnapshot.data!.docs;
              final vacDocs = vacSnapshot.data!.docs;

              int completed = 0, refused = 0, absent = 0;
              Set<String> vaccinatedChildren = {};

              for (var doc in vacDocs) {
                final data = doc.data() as Map<String, dynamic>;
                String status = (data['status'] ?? "").toString().toLowerCase();
                if (status == "completed") {
                  completed++;
                  vaccinatedChildren.add((data['childId'] ?? doc.id).toString());
                } else if (status == "refused") refused++;
                else if (status == "absent") absent++;
              }

              int targetCount = childrenDocs.length - vaccinatedChildren.length;
              if (targetCount < 0) targetCount = 0;

              return Column(
                children: [
                  _buildHeader(context),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard("Vaccinated", completed, const Color(0xFF059669), Icons.verified_user),
                          _buildStatCard("Refused", refused, const Color(0xFFDC2626), Icons.block),
                          _buildStatCard("Absent", absent, const Color(0xFFD97706), Icons.person_off),
                          _buildStatCard("Target", targetCount, primaryBlue, Icons.track_changes),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _actionButton(context, "Entry", Icons.qr_code_scanner, primaryBlue, const VaccinationEntryPage())),
                        const SizedBox(width: 12),
                        Expanded(child: _actionButton(context, "Register", Icons.person_add_alt_1, primaryBlue, const ChildRegistrationPage())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vacDocs.length,
                      itemBuilder: (context, index) {
                        final data = vacDocs[index].data() as Map<String, dynamic>;
                        return _buildListItem(context, data, vacDocs[index].id);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
      decoration: const BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
              IconButton(onPressed: _showVaccinatorDetailsDialog, icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28)),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Vaccinator Dashboard", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> data, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: accentBlue, child: Icon(Icons.person, color: primaryBlue)),
        title: Text(data['childName'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${data['vaccineType']} • ${data['status']}"),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteRecord(context, docId)),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 12),
        Text("$count", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.black45, fontSize: 13)),
      ]),
    );
  }

  Widget _actionButton(BuildContext context, String text, IconData icon, Color color, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)]),
    );
  }
}