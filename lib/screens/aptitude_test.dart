import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  final TextEditingController _aiKeyController = TextEditingController();
  final TextEditingController _aiCountController = TextEditingController(text: '5');
  final TextEditingController _aiTopicController = TextEditingController(text: 'general aptitude');

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  @override
  void dispose() {
    timer?.cancel();
    _aiKeyController.dispose();
    _aiCountController.dispose();
    _aiTopicController.dispose();
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

  Future<void> generateQuestionsWithAI([String? apiKey, int count = 5, String topic = 'general aptitude']) async {
    final usedKey = (apiKey?.trim().isNotEmpty ?? false) ? apiKey! : (dotenv.env['OPENAI_API_KEY'] ?? '');
    if (usedKey.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide an API key or set OPENAI_API_KEY in .env')));
      return;
    }

    final prompt = '''
You are an assistant that returns a JSON array of multiple-choice aptitude questions.
Produce $count questions about "$topic". Each item must be an object with:
- "question": string
- "options": array of 4 strings
- "answer": integer (0-based index of correct option)

Return ONLY valid JSON (the array). Example:
[
  {"question":"...","options":["A","B","C","D"],"answer":0},
  ...
]
''';

    try {
      setState(() => isLoading = true);

      final body = jsonEncode({
        "model": "gpt-3.5-turbo",
        "temperature": 0.6,
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 800,
      });

      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $usedKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (resp.statusCode != 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API error: ${resp.statusCode}')));
        setState(() => isLoading = false);
        return;
      }

      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = (map['choices'] as List).first['message']['content'] as String;

      // Attempt to extract JSON array from model output
      final start = content.indexOf('[');
      final end = content.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected AI response:\n$content')));
        setState(() => isLoading = false);
        return;
      }
      final jsonText = content.substring(start, end + 1);
      final parsed = jsonDecode(jsonText) as List<dynamic>;

      // Validate and add to Firestore
      int added = 0;
      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          final q = {
            'question': item['question'] ?? '',
            'options': List<String>.from(item['options'] ?? []),
            'answer': item['answer'] ?? 0,
          };
          // add to Firestore
          await FirebaseFirestore.instance.collection('aptitude_questions').add(q);
          added++;
        }
      }

      // refetch
      await fetchQuestions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $added questions from AI')));
    } catch (e, st) {
      debugPrint('generateQuestionsWithAI error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI generation failed: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // small helper to show dialog for API key + options
  void _showAIGeneratorDialog() {
    final defaultKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    _aiKeyController.text = defaultKey; // prefill for dev from .env (optional)
    _aiTopicController.text = 'general aptitude';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Questions (AI)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aiKeyController,
              decoration: const InputDecoration(labelText: 'API Key (dev)'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _aiTopicController,
              decoration: const InputDecoration(labelText: 'Topic (e.g. basic arithmetic, probability)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _aiCountController,
              decoration: const InputDecoration(labelText: 'How many questions'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final apiKey = _aiKeyController.text.trim();
              final count = int.tryParse(_aiCountController.text.trim()) ?? 5;
              final topic = _aiTopicController.text.trim().isEmpty ? 'general aptitude' : _aiTopicController.text.trim();
              Navigator.pop(context);
              generateQuestionsWithAI(apiKey, count, topic);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600;

    // Loading state
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aptitude Test'), backgroundColor: themeColor),
        body: Center(child: CircularProgressIndicator(color: themeColor)),
      );
    }

    // Empty-state: prevent RangeError when questions list is empty
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Aptitude Test'), backgroundColor: themeColor),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.menu_book_outlined, size: 48, color: themeColor),
                  const SizedBox(height: 12),
                  const Text(
                    'No aptitude questions available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add sample question'),
                      style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                      onPressed: addDebugQuestion,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bolt),
                      label: const Text('Generate with AI'),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: themeColor)),
                      onPressed: _showAIGeneratorDialog,
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    // add action button in AppBar to call AI generator
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aptitude Test'),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'Generate questions with AI',
            onPressed: _showAIGeneratorDialog,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeColor.withOpacity(0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card with question + progress + timer
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // progress + timer row
                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          LinearProgressIndicator(
                            value: questions.isNotEmpty ? (currentQuestion + 1) / questions.length : 0,
                            backgroundColor: Colors.grey[300],
                            color: themeColor,
                            minHeight: 6,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Question ${currentQuestion + 1} of ${questions.length}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      // circular timer
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: remainingSeconds / 30,
                              strokeWidth: 6,
                              color: Colors.redAccent,
                              backgroundColor: Colors.redAccent.withOpacity(0.15),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$remainingSeconds',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text('s', style: TextStyle(fontSize: 10)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Question text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      questions[currentQuestion]['question'],
                      key: ValueKey<int>(currentQuestion),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            const SizedBox(height: 14),

            // Options list (stylish tappable tiles)
            Expanded(
              child: ListView.separated(
                itemCount: (questions[currentQuestion]['options'] as List).length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswer == index;
                  return InkWell(
                    onTap: () => setState(() => selectedAnswer = index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor.withOpacity(0.14) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? themeColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected ? themeColor : Colors.grey.shade200,
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C...
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              questions[currentQuestion]['options'][index],
                              style: TextStyle(fontSize: 16, color: isSelected ? Colors.black : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // action row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedAnswer == -1 ? null : submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(currentQuestion == questions.length - 1 ? 'Finish' : 'Next'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedAnswer = -1;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    side: BorderSide(color: themeColor),
                  ),
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // score summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CGPA: ${widget.cgpaScore.toStringAsFixed(1)}/10', style: const TextStyle(fontSize: 14)),
                Text('Aptitude: $aptitudeScore/10', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
