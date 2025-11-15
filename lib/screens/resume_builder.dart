import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ace_interview/screens/cgpa_test.dart';

class ResumeBuilder extends StatefulWidget {
  const ResumeBuilder({super.key});

  @override
  State<ResumeBuilder> createState() => _ResumeBuilderState();
}

class _ResumeBuilderState extends State<ResumeBuilder> {
  // Personal Info
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final linkedinController = TextEditingController();
  final githubController = TextEditingController();

  // Education
  final degreeController = TextEditingController();
  final branchController = TextEditingController();
  final collegeController = TextEditingController();
  final graduationYearController = TextEditingController();
  final cgpaController = TextEditingController();

  // Skills & Experience
  final skillsController = TextEditingController();
  final experienceController = TextEditingController();
  final projectsController = TextEditingController();
  final certificationsController = TextEditingController();
  final achievementsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  int resumeScore = 0;

  void calculateScore() {
    int temp = 0;

    if (fullNameController.text.isNotEmpty) temp += 1;
    if (emailController.text.isNotEmpty && emailController.text.contains('@')) temp += 1;
    if (phoneController.text.length >= 10) temp += 1;
    if (linkedinController.text.isNotEmpty) temp += 1;
    if (githubController.text.isNotEmpty) temp += 1;

    if (degreeController.text.isNotEmpty) temp += 1;
    if (branchController.text.isNotEmpty) temp += 1;
    if (collegeController.text.isNotEmpty) temp += 1;
    if (graduationYearController.text.isNotEmpty) temp += 1;
    if (cgpaController.text.isNotEmpty) temp += 1;

    if (skillsController.text.split(',').where((s) => s.trim().isNotEmpty).length >= 3) temp += 2;
    if (projectsController.text.isNotEmpty) temp += 2;
    if (certificationsController.text.isNotEmpty) temp += 1;
    if (achievementsController.text.isNotEmpty) temp += 1;

    setState(() => resumeScore = (temp / 2).clamp(0, 10).round());
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    linkedinController.dispose();
    githubController.dispose();
    degreeController.dispose();
    branchController.dispose();
    collegeController.dispose();
    graduationYearController.dispose();
    cgpaController.dispose();
    skillsController.dispose();
    experienceController.dispose();
    projectsController.dispose();
    certificationsController.dispose();
    achievementsController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }

  Widget _previewCard(bool isWide) {
    final initials = (fullNameController.text.trim().isEmpty)
        ? 'U'
        : fullNameController.text.trim().split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase();

    final skills = skillsController.text.isEmpty ? '—' : skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: isWide ? 260 : 0, maxWidth: 360),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            CircleAvatar(radius: 32, backgroundColor: Colors.deepPurple.shade200, child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Text(fullNameController.text.isEmpty ? 'Your Name' : fullNameController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(emailController.text.isEmpty ? 'your.email@example.com' : emailController.text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const Divider(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('CGPA', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text(cgpaController.text.isEmpty ? '—' : cgpaController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Skills', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Flexible(child: Text(skills, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: resumeScore / 10, minHeight: 8, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text('Resume Score: $resumeScore / 10', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                calculateScore();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preview refreshed')));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Preview'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final themeColor = Colors.teal;
    final themeColorDark = Colors.teal.shade700;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Resume Builder'),
        backgroundColor: themeColorDark,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionCard(
                              title: '👤 Personal Information',
                              children: [
                                Row(children: [
                                  Expanded(child: TextFormField(controller: fullNameController, decoration: _fieldDecoration('Full Name', Icons.person))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: emailController, decoration: _fieldDecoration('Email', Icons.email), validator: (v) {
                                    if (v == null || v.isEmpty) return null;
                                    return v.contains('@') ? null : 'Enter a valid email';
                                  })),
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _fieldDecoration('Phone Number', Icons.phone))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: addressController, decoration: _fieldDecoration('Address', Icons.home))),
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: TextFormField(controller: linkedinController, decoration: _fieldDecoration('LinkedIn URL', Icons.work))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: githubController, decoration: _fieldDecoration('GitHub URL', Icons.code))),
                                ]),
                              ],
                            ),
                            _sectionCard(
                              title: '🎓 Education Details',
                              children: [
                                Row(children: [
                                  Expanded(child: TextFormField(controller: degreeController, decoration: _fieldDecoration('Degree', Icons.school))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: branchController, decoration: _fieldDecoration('Branch', Icons.book))),
                                ]),
                                const SizedBox(height: 10),
                                TextFormField(controller: collegeController, decoration: _fieldDecoration('College/University', Icons.location_city)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: TextFormField(controller: graduationYearController, keyboardType: TextInputType.number, decoration: _fieldDecoration('Graduation Year', Icons.calendar_today))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: cgpaController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: _fieldDecoration('CGPA', Icons.grade))),
                                ]),
                              ],
                            ),
                            _sectionCard(
                              title: '💼 Skills & Experience',
                              children: [
                                TextFormField(controller: skillsController, decoration: _fieldDecoration('Skills (comma separated)', Icons.list)),
                                const SizedBox(height: 10),
                                TextFormField(controller: experienceController, decoration: _fieldDecoration('Work Experience / Internships', Icons.work)),
                                const SizedBox(height: 10),
                                TextFormField(controller: projectsController, decoration: _fieldDecoration('Projects', Icons.storage)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: TextFormField(controller: certificationsController, decoration: _fieldDecoration('Certifications', Icons.verified))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: achievementsController, decoration: _fieldDecoration('Achievements', Icons.emoji_events))),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.calculate),
                                    label: const Text('Calculate Resume Score'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeColorDark,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 4,
                                    ),
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? true) {
                                        calculateScore();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: const Text('Save (Draft)'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: themeColorDark,
                                      side: BorderSide(color: themeColorDark),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved (not implemented)')));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: resumeScore > 0
                                    ? Column(
                                        key: ValueKey<int>(resumeScore),
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: resumeScore.toDouble()),
                                            duration: const Duration(milliseconds: 600),
                                            builder: (context, value, child) => Text(
                                              '📊 Resume Score: ${value.toStringAsFixed(0)} / 10',
                                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColorDark),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(value: resumeScore / 10, color: themeColorDark, minHeight: 8),
                                        ],
                                      )
                                    : const Text('Complete the form and press Calculate', key: ValueKey('hint')),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Next: CGPA & Aptitude Test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColorDark,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CgpaScreen()));
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(flex: 1, child: _previewCard(true)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard(
                        title: '👤 Personal Information',
                        children: [
                          TextFormField(controller: fullNameController, decoration: _fieldDecoration('Full Name', Icons.person)),
                          const SizedBox(height: 10),
                          TextFormField(controller: emailController, decoration: _fieldDecoration('Email', Icons.email), validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            return v.contains('@') ? null : 'Enter a valid email';
                          }),
                          const SizedBox(height: 10),
                          TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _fieldDecoration('Phone Number', Icons.phone)),
                          const SizedBox(height: 10),
                          TextFormField(controller: addressController, decoration: _fieldDecoration('Address', Icons.home)),
                          const SizedBox(height: 10),
                          TextFormField(controller: linkedinController, decoration: _fieldDecoration('LinkedIn URL', Icons.work)),
                          const SizedBox(height: 10),
                          TextFormField(controller: githubController, decoration: _fieldDecoration('GitHub URL', Icons.code)),
                        ],
                      ),
                      _sectionCard(
                        title: '🎓 Education Details',
                        children: [
                          TextFormField(controller: degreeController, decoration: _fieldDecoration('Degree', Icons.school)),
                          const SizedBox(height: 10),
                          TextFormField(controller: branchController, decoration: _fieldDecoration('Branch', Icons.book)),
                          const SizedBox(height: 10),
                          TextFormField(controller: collegeController, decoration: _fieldDecoration('College/University', Icons.location_city)),
                          const SizedBox(height: 10),
                          TextFormField(controller: graduationYearController, keyboardType: TextInputType.number, decoration: _fieldDecoration('Graduation Year', Icons.calendar_today)),
                          const SizedBox(height: 10),
                          TextFormField(controller: cgpaController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: _fieldDecoration('CGPA', Icons.grade)),
                        ],
                      ),
                      _sectionCard(
                        title: '💼 Skills & Experience',
                        children: [
                          TextFormField(controller: skillsController, decoration: _fieldDecoration('Skills (comma separated)', Icons.list)),
                          const SizedBox(height: 10),
                          TextFormField(controller: experienceController, decoration: _fieldDecoration('Work Experience / Internships', Icons.work)),
                          const SizedBox(height: 10),
                          TextFormField(controller: projectsController, decoration: _fieldDecoration('Projects', Icons.storage)),
                          const SizedBox(height: 10),
                          TextFormField(controller: certificationsController, decoration: _fieldDecoration('Certifications', Icons.verified)),
                          const SizedBox(height: 10),
                          TextFormField(controller: achievementsController, decoration: _fieldDecoration('Achievements', Icons.emoji_events)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calculate),
                              label: const Text('Calculate Resume Score'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColorDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? true) calculateScore();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Save (Draft)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: themeColorDark,
                                side: BorderSide(color: themeColorDark),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved (not implemented)'))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _previewCard(false),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next: CGPA & Aptitude Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColorDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CgpaScreen()));
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}