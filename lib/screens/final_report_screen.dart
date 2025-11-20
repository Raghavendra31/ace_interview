import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinalReportScreen extends StatelessWidget {
  const FinalReportScreen({super.key});

  Future<Map<String, dynamic>> fetchScores() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance.collection("user_scores").doc(user.uid).get();
    return doc.data() ?? {};
  }

  String _levelText(double percent) {
    if (percent >= 80) return "Excellent";
    if (percent >= 60) return "Good";
    if (percent >= 40) return "Average";
    return "Needs Improvement";
  }

  Color _levelColor(String level) {
    return level == "Excellent"
        ? Colors.green
        : level == "Good"
            ? Colors.blue
            : level == "Average"
                ? Colors.orange
                : Colors.redAccent;
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, double value, double max, Color color) {
    final pct = (max == 0) ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text("${value.toStringAsFixed(1)} / ${max.toStringAsFixed(1)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: pct, minHeight: 10, color: color, backgroundColor: color.withOpacity(0.18)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600;

    return Scaffold(
      appBar: AppBar(title: const Text("Final Evaluation Report"), backgroundColor: themeColor),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchScores(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }

          final data = snap.data!;
          double cgpa = (data["cgpa_score"] as num?)?.toDouble() ?? 0.0;
          double aptitude = (data["aptitude_score"] as num?)?.toDouble() ?? 0.0;
          double gd = (data["gd_score"] as num?)?.toDouble() ?? 0.0;
          double tech = (data["technical_score"] as num?)?.toDouble() ?? 0.0;

          // totals: cgpa(10) + aptitude(10) + gd(10) + tech(20) = 50r
          double total = cgpa + aptitude + gd + tech;
          double percent = ((total / 50) * 100).clamp(0.0, 100.0);
          final level = _levelText(percent);
          final levelColor = _levelColor(level);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      // animated circular percent
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: percent / 100),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(value: value, strokeWidth: 12, color: themeColor, backgroundColor: themeColor.withOpacity(0.18)),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${(value * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(level, style: TextStyle(color: levelColor, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 18),

                      // summary cards
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Score", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("${total.toStringAsFixed(1)} / 50", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 4.5,
                              children: [
                                _statCard("CGPA", "${cgpa.toStringAsFixed(1)}/10", Icons.school, Colors.teal),
                                _statCard("Aptitude", "${aptitude.toStringAsFixed(1)}/10", Icons.timeline, Colors.amber.shade700),
                                _statCard("GD", "${gd.toStringAsFixed(1)}/10", Icons.record_voice_over, Colors.indigo.shade600),
                                _statCard("Technical", "${tech.toStringAsFixed(1)}/20", Icons.computer, Colors.deepPurple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Breakdown card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _progressRow("CGPA", cgpa, 10, themeColor),
                          _progressRow("Aptitude", aptitude, 10, Colors.amber.shade700),
                          _progressRow("GD", gd, 10, Colors.indigo.shade600),
                          _progressRow("Technical", tech, 20, Colors.deepPurple),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Recommendations
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Recommended Improvements", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        if (aptitude < 6) ListTile(leading: const Icon(Icons.school_outlined, color: Colors.orange), title: const Text("Improve quantitative aptitude")),
                        if (gd < 6) ListTile(leading: const Icon(Icons.record_voice_over, color: Colors.orange), title: const Text("Practice fluency and reduce filler words")),
                        if (tech < 12) ListTile(leading: const Icon(Icons.build_circle_outlined, color: Colors.orange), title: const Text("Strengthen core technical fundamentals")),
                        if (cgpa < 7) ListTile(leading: const Icon(Icons.menu_book_outlined, color: Colors.orange), title: const Text("Consider academic/learning improvements")),
                        if (aptitude >= 6 && gd >= 6 && tech >= 12 && cgpa >= 7)
                          const ListTile(leading: Icon(Icons.thumb_up, color: Colors.green), title: Text("Great job — keep polishing your strengths!")),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("COMPLETED"),
                          style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            // future: implement PDF generation
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF generation coming soon")));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text("Share"),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Share functionality coming soon")));
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
