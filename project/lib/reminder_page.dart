import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReminderPage extends StatelessWidget {
  final String? motherCNIC;

  const ReminderPage({super.key, this.motherCNIC});

  // ⏰ Date Parsing Logic (Firebase Timestamp ya String dono ke liye safe)
  DateTime parseDateTime(dynamic dateField, String timeStr) {
    try {
      if (dateField == null) return DateTime.now();
      
      DateTime date;
      if (dateField is Timestamp) {
        date = dateField.toDate();
      } else {
        date = DateFormat("yyyy-MM-dd").parse(dateField.toString());
      }

      if (timeStr.isEmpty) return date;

      // Time parsing (assuming "HH:mm" format from your previous code)
      List<String> parts = timeStr.split(':');
      return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return DateTime.now();
    }
  }

  String getStatus(DateTime vaccineTime) {
    final now = DateTime.now();
    if (vaccineTime.isBefore(now)) return "Overdue";
    if (vaccineTime.isBefore(now.add(const Duration(days: 2)))) return "Urgent";
    return "Upcoming";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Vaccination Reminders"),
        backgroundColor: const Color(0xFF004AAD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 Note: Vaccinator sessions wali collection se data fetch ho raha hai
        stream: FirebaseFirestore.instance
            .collection('vaccinator_sessions') 
            // Agar aapne sessions ko motherCNIC se link kiya hai to niche wali line rakhein, 
            // warna pure schedule dikhane ke liye .where line remove kar dein.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No upcoming sessions found."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;

              // 📋 Extracting fields saved by Vaccinator
              String vName = data['vaccinatorName'] ?? "Unknown Vaccinator";
              String vId = data['vaccinatorId'] ?? "N/A";
              String vaccine = data['vaccineType'] ?? "General Vaccine";
              String dose = data['dose'] ?? "1";
              String timeVal = data['scheduledTime'] ?? "";
              var dateVal = data['scheduledDate'];

              DateTime fullDateTime = parseDateTime(dateVal, timeVal);
              String status = getStatus(fullDateTime);
              
              Color statusColor = status == "Overdue" ? Colors.red : (status == "Urgent" ? Colors.orange : Colors.green);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    // Top Status Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Status: $status", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("ID: $vId", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF004AAD).withOpacity(0.1),
                        child: const Icon(Icons.medication, color: Color(0xFF004AAD)),
                      ),
                      title: Text("$vaccine ($dose)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text("👨‍⚕️ Vaccinator: $vName", style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.event, size: 16, color: Color(0xFF004AAD)),
                              const SizedBox(width: 5),
                              Text(
                                dateVal is Timestamp 
                                  ? DateFormat('dd-MM-yyyy').format(dateVal.toDate())
                                  : dateVal.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 15),
                              const Icon(Icons.access_time, size: 16, color: Color(0xFF004AAD)),
                              const SizedBox(width: 5),
                              Text(timeVal, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}