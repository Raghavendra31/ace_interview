import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ace_interview/screens/final_report_screen.dart'; // <- add this import

class TechnicalScreen extends StatefulWidget {
  final String role;
  final String company;

  const TechnicalScreen({super.key, required this.role, required this.company});

  @override
  State<TechnicalScreen> createState() => _TechnicalScreenState();
}

class _TechnicalScreenState extends State<TechnicalScreen> {
  int current = 0;
  int selected = -1;
  int techScore = 0;
  bool loading = true;

  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    fetchTechnicalQ();
  }

  Future<void> fetchTechnicalQ() async {
    // debug: print which project / query values we use
    debugPrint('fetchTechnicalQ → company param: ${widget.company} (toLower: ${widget.company.toLowerCase()}), role: ${widget.role}');
    try {
      final snap = await FirebaseFirestore.instance
          .collection("technical_questions")
          .where("company", isEqualTo: widget.company.toLowerCase())
          .where("role", isEqualTo: widget.role)
          .get();

      debugPrint('technical_questions count: ${snap.docs.length}');
      debugPrint('technical_questions docs: ${snap.docs.map((d) => d.data()).toList()}');


      final loaded = snap.docs.map((doc) => {
            "question": doc["question"],
            "options": List<String>.from(doc["options"]),
            "answer": doc["answer"],
          }).toList();

      setState(() {
        questions = loaded;
        loading = false;
      });
    } catch (e, st) {
      debugPrint('fetchTechnicalQ error: $e\n$st');
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load technical questions: $e')),
        );
      }
    }
  }

  // Dev helper: insert a sample technical question (useful when collection is empty)
  Future<void> addDebugQuestion() async {
    await FirebaseFirestore.instance.collection('technical_questions').add({
      'company': widget.company.toLowerCase(),
      'role': widget.role,
      'question': 'Sample: What does HTTP stand for?',
      'options': ['HyperText Transfer Protocol', 'High Transfer Text Protocol', 'HyperText Transfer Process', 'HyperText Text Protocol'],
      'answer': 0,
    });
    debugPrint('Added debug technical question; refetching...');
    await fetchTechnicalQ();
  }

  void submit() {
    if (selected == questions[current]["answer"]) {
      techScore += 2;
    }

    if (current < questions.length - 1) {
      setState(() {
        current++;
        selected = -1;
      });
    } else {
      saveTechScore();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Technical Round Complete"),
          content: Text("Your score: $techScore / 20"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinalReportScreen(),
                  ),
                );
              },
              child: Text("OK"),
            )
          ],
        ),
      );
    }
  }

  Future<void> saveTechScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("user_scores")
        .doc(user.uid)
        .set({
      "technical_score": techScore,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Technical Test")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Technical Test")),
        body: const Center(
          child: Text(
            "⚠️ No technical questions found.\nPlease add questions in Firestore.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final q = questions[current];
    final options = q["options"];

    return Scaffold(
      appBar: AppBar(title: Text("${widget.company} - ${widget.role}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(q["question"], style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ...List.generate(options.length, (i) => RadioListTile(
                  value: i,
                  groupValue: selected,
                  title: Text(options[i]),
                  onChanged: (_) => setState(() => selected = i),
                )),
            ElevatedButton(
              onPressed: selected == -1 ? null : submit,
              child: Text(
                  current == questions.length - 1 ? "Finish" : "Next"),
            ),
          ],
        ),
      ),
    );
  }
}
