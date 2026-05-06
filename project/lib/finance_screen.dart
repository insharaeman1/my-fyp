import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // User ID lene ke liye

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final Color primaryOrange = const Color(0xFFE67E22);
  final Color headerOrange = const Color(0xFFD35400);
  
  // फर्ज़ करें hum logged-in user ka data dekh rahe hain
  final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // FILTER: Hum sirf wo records mangwa rahe hain jahan vaccinator ka naam matches ho
              // Aap 'vaccinatorName' ki jagah 'vaccinatorEmail' ya 'uid' bhi use kar sakte hain
              stream: FirebaseFirestore.instance
                  .collection('vaccinations')
                  .where('vaccinatorName', isEqualTo: "Ali Khan") // Yahan us bande ka naam likhein
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No records found for this vaccinator"));
                }

                var docs = snapshot.data!.docs;

                // --- Calculation for only THIS person ---
                int count = docs.length;
                int salary = count * 50; // 50 per vaccination
                int paid = docs.where((d) => d['status'] == 'completed').length * 50;
                int pending = salary - paid;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Personal Stats Card
                      _buildPersonalStats(salary, paid, pending),
                      const SizedBox(height: 20),
                      
                      // List of their specific vaccinations
                      _buildDetailTable(docs),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryOrange, headerOrange])),
      child: const Text("My Earnings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildPersonalStats(int total, int paid, int pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total", "Rs $total", Colors.blue),
          _statItem("Received", "Rs $paid", Colors.green),
          _statItem("Pending", "Rs $pending", Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailTable(List<QueryDocumentSnapshot> docs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DataTable(
        horizontalMargin: 10,
        columnSpacing: 15,
        columns: const [
          DataColumn(label: Text('CHILD')),
          DataColumn(label: Text('AMOUNT')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: docs.map((doc) {
          String status = doc['status'] ?? 'pending';
          return DataRow(cells: [
            DataCell(Text(doc['childName'] ?? 'N/A')),
            //DataCell(Text("Rs 50")),
            const DataCell(Text("Rs 50")),
            DataCell(Text(status, style: TextStyle(color: status == 'completed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      ),
    );
  }
}