import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- add this
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ace_interview/screens/job_role_screen.dart';

class GDScreen extends StatefulWidget {
  final double cgpaScore;
  final int aptitudeScore;
  const GDScreen({super.key, required this.cgpaScore, required this.aptitudeScore});

  @override
  State<GDScreen> createState() => _GDScreenState();
}

class _GDScreenState extends State<GDScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText speech;
  bool isListening = false;
  bool speechAvailable = false;
  String transcript = "";
  double gdScore = 0;

  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await speech.initialize(
        onStatus: (s) => debugPrint('speech status: $s'),
        onError: (e) => debugPrint('speech error: $e'),
      );
      setState(() => speechAvailable = available);
      if (!available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Speech recognition unavailable on this device/emulator.'),
        ));
      }
    } catch (e) {
      setState(() => speechAvailable = false);
      debugPrint('initializeSpeech exception: $e');
    }
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
    final words = transcript.trim().isEmpty ? 0 : transcript.trim().split(RegExp(r"\s+")).length;

    if (words < 10) gdScore = 3;
    else if (words < 50) gdScore = 6;
    else gdScore = 9;

    final lowered = transcript.toLowerCase();
    if (lowered.contains("um") || lowered.contains("aaa") || lowered.contains("uh")) {
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
                  builder: (context) => JobRoleScreen(),
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
    if (!speechAvailable) {
      await _initSpeech();
      if (!speechAvailable) return;
    }

    try {
      final available = await speech.initialize(
        onStatus: (status) => debugPrint('status: $status'),
        onError: (err) => debugPrint('init error: $err'),
      );
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech service not available.')));
        return;
      }

      setState(() {
        isListening = true;
        transcript = "";
      });
      _pulseController?.repeat(reverse: true);

      speech.listen(
        onResult: (result) {
          setState(() {
            transcript = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('startListening error: $e');
      setState(() => isListening = false);
      _pulseController?.stop();
    }
  }

  void stopListening() {
    try {
      speech.stop();
    } catch (_) {}
    setState(() => isListening = false);
    _pulseController?.stop();
    analyzeGD();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.indigo.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Discussion"),
        backgroundColor: themeColor,
        elevation: 0,
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
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Topic",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Should AI replace human jobs?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "CGPA: ${widget.cgpaScore.toStringAsFixed(1)}  •  Aptitude: ${widget.aptitudeScore}/10",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                        if (!speechAvailable)
                          const Icon(Icons.error_outline, color: Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // transcript box
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      SelectableText(
                        transcript.isEmpty ? "Your speech transcript will appear here..." : transcript,
                        style: TextStyle(color: Colors.black87, height: 1.4),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () => setState(() => transcript = ""),
                              icon: const Icon(Icons.clear),
                            ),
                            IconButton(
                              tooltip: 'Copy',
                              onPressed: () {
                                if (transcript.isNotEmpty) {
                                  Clipboard.setData(ClipboardData(text: transcript));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied transcript')));
                                }
                              },
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // big mic with pulse
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isListening) stopListening();
                          else startListening();
                        },
                        child: AnimatedBuilder(
                          animation: _pulseController ?? AlwaysStoppedAnimation(0.0),
                          builder: (context, child) {
                            final controllerValue = _pulseController?.value ?? 0.0;
                            final scale = 1.0 + (controllerValue * 0.08);
                            return Transform.scale(
                              scale: isListening ? scale : 1.0,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                isListening ? themeColor.withOpacity(0.95) : themeColor.withOpacity(0.85),
                                isListening ? themeColor.withOpacity(0.75) : themeColor.withOpacity(0.55),
                              ]),
                              boxShadow: [
                                BoxShadow(color: themeColor.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Icon(
                              isListening ? Icons.mic_off : Icons.mic,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isListening ? "Listening..." : "Tap to speak",
                        style: TextStyle(color: isListening ? Colors.redAccent : Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // quick actions column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop_circle),
                      label: const Text("Stop & Analyze"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: isListening ? stopListening : null,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save Draft"),
                      onPressed: () {
                        // optional: implement save draft
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved (not implemented)')));
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tip: Speak for >30s for better score', style: TextStyle(color: Colors.black54)),
                Text('Words: ${transcript.trim().isEmpty ? 0 : transcript.trim().split(RegExp(r"\\s+")).length}',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
