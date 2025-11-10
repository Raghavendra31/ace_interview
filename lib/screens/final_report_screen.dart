import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinalReportScreen extends StatelessWidget {
  const FinalReportScreen({super.key});

  Future<Map<String, dynamic>> fetchScores() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection("user_scores")
        .doc(user.uid)
        .get();

    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Final Evaluation Report")),
      body: FutureBuilder(
        future: fetchScores(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;

          double cgpa = (data["cgpa_score"] as num?)?.toDouble() ?? 0.0;
          double aptitude = (data["aptitude_score"] as num?)?.toDouble() ?? 0.0;
          double gd = (data["gd_score"] as num?)?.toDouble() ?? 0.0;
          double tech = (data["technical_score"] as num?)?.toDouble() ?? 0.0;

          double total = cgpa + aptitude + gd + tech;
          double percent = (total / 50) * 100;

          String level = percent >= 80
              ? "Excellent"
              : percent >= 60
                  ? "Good"
                  : percent >= 40
                      ? "Average"
                      : "Needs Improvement";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Score: $total / 50",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Placement Readiness: $level",
                    style: TextStyle(
                        fontSize: 16,
                        color: level == "Excellent"
                            ? Colors.green
                            : level == "Good"
                                ? Colors.blue
                                : Colors.orange)),
                const SizedBox(height: 20),
                Text("Breakdown:",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text("✅ CGPA: $cgpa/10"),
                Text("✅ Aptitude: $aptitude/10"),
                Text("✅ GD: $gd/10"),
                Text("✅ Technical: $tech/20"),
                const SizedBox(height: 20),
                Text("Recommended Improvements:",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (aptitude < 6) Text("📌 Improve quantitative aptitude.")
                ,
                if (gd < 6) Text("📌 Improve fluency & vocabulary."),
                if (tech < 12) Text("📌 Strengthen core fundamentals."),
                if (cgpa < 7) Text("📌 Academic improvement recommended."),

                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // future: Generate PDF / share
                    },
                    child: const Text("Generate PDF Report"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
