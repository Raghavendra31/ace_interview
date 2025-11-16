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
    final themeColor = Colors.teal.shade600;

    // loading state
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Technical Test"), backgroundColor: themeColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // no questions
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Technical Test"), backgroundColor: themeColor),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: themeColor),
                  const SizedBox(height: 12),
                  const Text(
                    "⚠️ No technical questions found.\nPlease add questions in Firestore.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                    onPressed: addDebugQuestion,
                    child: const Text('Add debug question (dev)'),
                  )
                ]),
              ),
            ),
          ),
        ),
      );
    }

    final q = questions[current];
    final options = (q["options"] as List).cast<String>();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.company.toUpperCase()} • ${widget.role}"),
        backgroundColor: themeColor,
        elevation: 2,
      ),
      body: Container(
        color: Colors.teal.shade50,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              // top card: progress + timer + score
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // progress
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            "Question ${current + 1} of ${questions.length}",
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (current + 1) / questions.length,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: themeColor,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.school, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text('Current score: $techScore / 20', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ]),
                      ),

                      const SizedBox(width: 12),

                      // timer placeholder (reuse existing if you have)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.timer, color: Colors.redAccent),
                                const SizedBox(height: 6),
                                Text(
                                  '30s',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // question cardr
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(
                      q["question"],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(questions.length, (i) {
                        // small page indicators
                        return Container(
                          width: 10,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= current ? themeColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 14),

              // options list
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final isSelected = selected == i;
                    return GestureDetector(
                      onTap: () => setState(() => selected = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? themeColor.withOpacity(0.14) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? themeColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                          boxShadow: isSelected ? [BoxShadow(color: themeColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))] : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isSelected ? themeColor : Colors.grey.shade200,
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(options[i], style: const TextStyle(fontSize: 16))),
                            if (isSelected)
                              Icon(Icons.check_circle, color: themeColor)
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected == -1 ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(current == questions.length - 1 ? 'Finish' : 'Next'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selected = -1;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      side: BorderSide(color: themeColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // footer summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Company: ${widget.company.toUpperCase()}', style: const TextStyle(color: Colors.black54)),
                  Text('Role: ${widget.role}', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
