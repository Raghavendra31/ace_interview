import 'package:flutter/material.dart';
import 'package:ace_interview/screens/aptitude_test.dart'; // Navigate here after entering CGPA

class CgpaScreen extends StatefulWidget {
  const CgpaScreen({super.key});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen> {
  final cgpaController = TextEditingController();
  double cgpaScore = 0;

  void calculateCgpa() {
    double cgpa = double.tryParse(cgpaController.text) ?? 0;
    if (cgpa > 10) cgpa = 10;
    setState(() {
      cgpaScore = cgpa;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CGPA Score')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎓 Enter Your CGPA (out of 10)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cgpaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CGPA',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculateCgpa,
              child: const Text('Calculate Score'),
            ),
            const SizedBox(height: 15),
            if (cgpaScore > 0)
              Text(
                '✅ CGPA Score: ${cgpaScore.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: Aptitude Test'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AptitudeScreen(cgpaScore: cgpaScore),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
