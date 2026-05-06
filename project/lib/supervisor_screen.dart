import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  final Color primaryTeal = const Color(0xFF0D9488);
  final Color bgSlate = const Color(0xFFF1F5F9);

  // --- Real-time Data Stream ---
  // Ye stream "children" collection par nazar rakhegi
  Stream<QuerySnapshot> get childrenStream =>
      FirebaseFirestore.instance.collection('children').snapshots();

  // --- Vaccination Data Stream ---
  Stream<QuerySnapshot> get vaccinationStream =>
      FirebaseFirestore.instance.collection('vaccinations').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSlate,
      body: StreamBuilder<QuerySnapshot>(
        stream: childrenStream,
        builder: (context, childSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: vaccinationStream,
            builder: (context, vacSnap) {
              if (childSnap.connectionState == ConnectionState.waiting ||
                  vacSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- LOGIC: Calculation ---
              int totalChildren = childSnap.data?.docs.length ?? 0;
              
              // Vaccinations collection se status filter karna
              var vacDocs = vacSnap.data?.docs ?? [];
              int vaccinated = vacDocs.where((d) => d['status'] == 'completed').length;
              int refused = vacDocs.where((d) => d['status'] == 'refused').length;
              //int absent = vacDocs.where((d) => d['status'] == 'absent').length;
              // ✅ Add underscore to suppress the warning
              final int _absent = vacDocs.where((d) => d['status'] == 'absent').length; 
              int pending = totalChildren - vaccinated;
              double coverage = totalChildren > 0 ? (vaccinated / totalChildren) * 100 : 0;

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Ab hum calculate kiye hue numbers pass karenge
                          _buildKpiGrid(totalChildren, vaccinated, pending, refused, coverage),
                          const SizedBox(height: 24),
                          _buildSimpleChartSection(vaccinated, totalChildren),
                        ],
                      ),
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

  // HEADER (Same as yours)
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Supervisor Dashboard",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(
            "Real-time Vaccination Monitoring",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // KPI CARDS (Functional)
  Widget _buildKpiGrid(int total, int vac, int pend, int ref, double cover) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard("Total Children", total.toString(), Colors.blue),
        _statCard("Vaccinated", vac.toString(), Colors.green),
        _statCard("Pending", pend.toString(), Colors.orange),
        _statCard("Refused", ref.toString(), Colors.red),
        _statCard("Coverage", "${cover.toStringAsFixed(1)}%", Colors.purple),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    double width = (MediaQuery.of(context).size.width / 2) - 22;
    return Container(
      width: title == "Coverage" ? double.infinity : width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // CHART (Ab ye vaccinated percentage ke mutabiq bar show karega)
  Widget _buildSimpleChartSection(int vaccinated, int total) {
    double factor = total > 0 ? (vaccinated / total) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Overall Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bar("Target", 1.0, Colors.grey.shade300), // Full bar
              _bar("Achieved", factor, Colors.green),    // Current performance bar
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double heightFactor, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 120 * heightFactor,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}