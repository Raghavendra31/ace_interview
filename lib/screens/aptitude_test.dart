import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'gd_screen.dart'; // Import the GDScreen here

class AptitudeScreen extends StatefulWidget {
  final double cgpaScore;
  const AptitudeScreen({super.key, required this.cgpaScore});

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  int currentQuestion = 0;
  int selectedAnswer = -1;
  int aptitudeScore = 0;

  Timer? timer;
  int remainingSeconds = 30;
  bool isLoading = true;

  final List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchQuestions() async {
    // debug which Firebase app / project is used
    debugPrint('Firebase app: ${Firebase.app().name}, projectId: ${Firebase.app().options.projectId}');
    debugPrint('currentUser: ${FirebaseAuth.instance.currentUser?.uid}');

    try {
      setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('aptitude_questions')
          .get();

      debugPrint('aptitude_questions count: ${snapshot.docs.length}');
      debugPrint('docs data: ${snapshot.docs.map((d) => d.data()).toList()}');

      if (!mounted) return;

      final loaded = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        loaded.add({
          'question': doc['question'] ?? '',
          'options': List<String>.from(doc['options'] ?? []),
          'answer': doc['answer'] ?? 0,
        });
      }

      setState(() {
        questions
          ..clear()
          ..addAll(loaded);
        currentQuestion = 0;
        selectedAnswer = -1;
        aptitudeScore = 0;
        isLoading = false;
      });

      if (questions.isNotEmpty) {
        startTimer();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'No aptitude questions found. Verify Firestore collection "aptitude_questions" '
              'contains documents with fields: question (string), options (array), answer (int).'
            ),
            duration: Duration(seconds: 6),
          ));
        }
      }
    } catch (e, st) {
      setState(() => isLoading = false);
      debugPrint('fetchQuestions error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load questions: $e')),
        );
      }
    }
  }

  // Dev helper: inserts a sample document and refetches
  Future<void> addDebugQuestion() async {
    await FirebaseFirestore.instance.collection('aptitude_questions').add({
      'question': 'What is 2 + 2?',
      'options': ['1', '2', '3', '4'],
      'answer': 3,
    });
    debugPrint('Added debug question -> refetching');
    await fetchQuestions();
  }

  void startTimer() {
    timer?.cancel();
    setState(() => remainingSeconds = 30);

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        if (mounted) setState(() => remainingSeconds--);
      } else {
        t.cancel();
        submitAnswer();
      }
    });
  }

  Future<void> saveScores(double cgpaScore, int aptitudeScore) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('user_scores')
        .doc(user.uid)
        .set({
      'cgpa_score': cgpaScore,
      'aptitude_score': aptitudeScore,
      'total_score': cgpaScore + aptitudeScore,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> submitAnswer() async {
    timer?.cancel();

    if (selectedAnswer == questions[currentQuestion]['answer']) {
      aptitudeScore += 3;
    }

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = -1;
      });
      startTimer();
    } else {
      setState(() {
        if (aptitudeScore > 10) aptitudeScore = 10;
      });

      await saveScores(widget.cgpaScore, aptitudeScore);
      if (!mounted) return;

      final totalScore = widget.cgpaScore + aptitudeScore.toDouble();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Aptitude Test Complete'),
          content: Text(
            'CGPA Score: ${widget.cgpaScore}/10\n'
            'Aptitude Score: $aptitudeScore/10\n\n'
            '📊 Total: $totalScore/20',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GDScreen(
                      cgpaScore: widget.cgpaScore,
                      aptitudeScore: aptitudeScore,
                    ),
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Aptitude Test')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isLoading && questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aptitude Test')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️ No questions available right now.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: addDebugQuestion,
                child: const Text('Add debug question (dev)'),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[currentQuestion];
    final options = (q['options'] as List).cast<String>();

    return Scaffold(
      appBar: AppBar(title: const Text('Aptitude Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              backgroundColor: Colors.grey[300],
              color: Colors.indigo,
            ),
            const SizedBox(height: 20),

            Text(
              'Q${currentQuestion + 1}: ${q['question']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Timer
            Text(
              '⏳ Time left: $remainingSeconds s',
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 15),

            // Options
            ...List.generate(options.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: selectedAnswer,
                title: Text(options[index]),
                onChanged: (val) => setState(() => selectedAnswer = val ?? -1),
              );
            }),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: selectedAnswer == -1 ? null : submitAnswer,
              child: Text(currentQuestion == questions.length - 1 ? 'Finish' : 'Next'),
            ),
            const Spacer(),
            Text(
              'CGPA Score: ${widget.cgpaScore}/10',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Aptitude Score: $aptitudeScore/10',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
