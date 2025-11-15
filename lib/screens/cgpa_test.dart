import 'package:flutter/material.dart';
import 'package:ace_interview/screens/aptitude_test.dart'; // Navigate here after entering CGPA
import 'dart:math' as math;

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
    if (cgpa < 0) cgpa = 0;
    setState(() {
      cgpaScore = cgpa;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CGPA saved: ${cgpaScore.toStringAsFixed(1)} / 10'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatPercent(double value) {
    return (value * 10).toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('CGPA Score'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🎓 Enter Your CGPA',
                          // headline6 -> titleLarge, bodyText2 -> bodyMedium (Material 3 / recent Flutter)
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Provide your CGPA out of 10. Use the slider or type it below.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),

                        // Circular animated indicator
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: cgpaScore / 10.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) {
                            final percent = (value);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: Transform.rotate(
                                        angle: -math.pi / 2,
                                        child: CircularProgressIndicator(
                                          value: percent,
                                          strokeWidth: 12,
                                          color: themeColor,
                                          backgroundColor: themeColor.withValues(),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_formatPercent(percent)}%',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: themeColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(percent * 10).toStringAsFixed(1)} / 10',
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // Slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Adjust with the slider:'),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: themeColor,
                                inactiveTrackColor: themeColor.withValues(),
                                thumbColor: themeColor,
                                overlayColor: themeColor.withValues(),
                              ),
                              child: Slider(
                                value: cgpaScore,
                                min: 0,
                                max: 10,
                                divisions: 100,
                                label: cgpaScore.toStringAsFixed(1),
                                onChanged: (v) => setState(() {
                                  cgpaScore = double.parse(v.toStringAsFixed(1));
                                  cgpaController.text = cgpaScore.toStringAsFixed(1);
                                }),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Text field
                        TextField(
                          controller: cgpaController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'CGPA',
                            hintText: 'e.g. 8.5',
                            suffixText: '/10',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.school),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: themeColor),
                            ),
                          ),
                          onSubmitted: (_) => calculateCgpa(),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.calculate),
                                label: const Text('Calculate Score'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  calculateCgpa();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: themeColor,
                                  side: BorderSide(color: themeColor),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    cgpaScore = 0;
                                    cgpaController.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next: Aptitude Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cgpaScore > 0 ? themeColor : themeColor.withValues(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: cgpaScore > 0
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AptitudeScreen(cgpaScore: cgpaScore),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
