import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:ace_interview/screens/technical_screen.dart';
import 'package:ace_interview/screens/job_role_screen.dart';


class GDScreen extends StatefulWidget {
  final double cgpaScore;
  final int aptitudeScore;
  const GDScreen({super.key, required this.cgpaScore, required this.aptitudeScore});

  @override
  State<GDScreen> createState() => _GDScreenState();
}

class _GDScreenState extends State<GDScreen> {
  late stt.SpeechToText speech;
  bool isListening = false;
  String transcript = "";
  double gdScore = 0;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  Future<void> saveGDScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("user_scores")
        .doc(user.uid)
        .set({
      "gd_score": gdScore,
    }, SetOptions(merge: true));
  }

  void analyzeGD() {
    int words = transcript.split(" ").length;

    if (words < 10) gdScore = 3;
    if (words > 10 && words < 50) gdScore = 6;
    if (words >= 50) gdScore = 9;

    if (transcript.toLowerCase().contains("um") ||
        transcript.toLowerCase().contains("aaa")) {
      gdScore -= 1;
    }

    if (gdScore < 0) gdScore = 0;

    saveGDScore();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("GD Result"),
        content: Text(
          "Transcript:\n$transcript\n\n"
          "GD Score: $gdScore / 10\n\n"
          "Tip: Improve fluency and reduce filler words.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobRoleScreen(), // 🧭 go to job role selection first
                ),
              );
            },
            child: const Text("Continue"),
          )
        ],
      ),
    );
  }

  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(onResult: (result) {
        setState(() {
          transcript = result.recognizedWords;
        });
      });
    }
  }

  void stopListening() {
    speech.stop();
    setState(() => isListening = false);
    analyzeGD();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Group Discussion")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Speak about: Should AI replace human jobs?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    transcript.isEmpty
                        ? "Your speech transcript will appear here..."
                        : transcript,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(isListening ? Icons.stop : Icons.mic),
              label: Text(isListening ? "Stop Speaking" : "Start Speaking"),
              onPressed: () {
                if (isListening) {
                  stopListening();
                } else {
                  startListening();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
