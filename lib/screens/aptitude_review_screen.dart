import 'package:flutter/material.dart';
import 'gd_screen.dart';   // 👉 ADD THIS IMPORT

class AptitudeReviewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final List<int> userAnswers;
  final double cgpaScore;
  final int aptitudeScore;

  const AptitudeReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.cgpaScore,
    required this.aptitudeScore,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aptitude Review"),
        backgroundColor: themeColor,
      ),

      // 👉 NEXT BUTTON ADDED HERE
      bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(16.0),
  child: ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GDScreen(
            cgpaScore: cgpaScore,
            aptitudeScore: aptitudeScore,
          ),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text(
      "Next",
      style: TextStyle(fontSize: 18, color: Colors.white),
    ),
  ),
),


      body: ListView.builder(
        itemCount: questions.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final q = questions[index];
          final correctAnswer = q['answer'];
          final selected = userAnswers[index];

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}. ${q['question']}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(q['options'].length, (optIndex) {
                    final option = q['options'][optIndex];

                    Color bg = Colors.white;
                    Color border = Colors.grey.shade300;

                    if (optIndex == correctAnswer) {
                      bg = Colors.green.withOpacity(0.2);
                      border = Colors.green;
                    }

                    if (optIndex == selected && selected != correctAnswer) {
                      bg = Colors.red.withOpacity(0.2);
                      border = Colors.red;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            String.fromCharCode(65 + optIndex),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(option)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
