import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ace_interview/screens/cgpa_test.dart'; // added import

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

  int resumeScore = 0;

  void calculateScore() {
    int temp = 0;

    // Personal info scoring
    if (fullNameController.text.isNotEmpty) temp += 1;
    if (emailController.text.isNotEmpty && emailController.text.contains('@')) temp += 1;
    if (phoneController.text.length >= 10) temp += 1;
    if (linkedinController.text.isNotEmpty) temp += 1;
    if (githubController.text.isNotEmpty) temp += 1;

    // Education scoring
    if (degreeController.text.isNotEmpty) temp += 1;
    if (branchController.text.isNotEmpty) temp += 1;
    if (collegeController.text.isNotEmpty) temp += 1;
    if (graduationYearController.text.isNotEmpty) temp += 1;
    if (cgpaController.text.isNotEmpty) temp += 1;

    // Skills & Experience
    if (skillsController.text.split(',').length >= 3) temp += 2;
    if (projectsController.text.isNotEmpty) temp += 2;
    if (certificationsController.text.isNotEmpty) temp += 1;
    if (achievementsController.text.isNotEmpty) temp += 1;

    // Max 20 → convert to 10 scale
    setState(() => resumeScore = (temp / 2).clamp(0, 10).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👤 Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL')),
            TextField(controller: githubController, decoration: const InputDecoration(labelText: 'GitHub URL')),
            const SizedBox(height: 20),

            const Text('🎓 Education Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree')),
            TextField(controller: branchController, decoration: const InputDecoration(labelText: 'Branch')),
            TextField(controller: collegeController, decoration: const InputDecoration(labelText: 'College/University')),
            TextField(controller: graduationYearController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Graduation Year')),
            TextField(controller: cgpaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CGPA')),
            const SizedBox(height: 20),

            const Text('💼 Skills & Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: skillsController, decoration: const InputDecoration(labelText: 'Skills (comma separated)')),
            TextField(controller: experienceController, decoration: const InputDecoration(labelText: 'Work Experience / Internships')),
            TextField(controller: projectsController, decoration: const InputDecoration(labelText: 'Projects')),
            TextField(controller: certificationsController, decoration: const InputDecoration(labelText: 'Certifications')),
            TextField(controller: achievementsController, decoration: const InputDecoration(labelText: 'Achievements')),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: calculateScore,
              child: const Text('✨ Calculate Resume Score'),
            ),
            const SizedBox(height: 15),
            if (resumeScore > 0)
              Center(
                child: Text(
                  '📊 Resume Score: $resumeScore / 10',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: CGPA & Aptitude Test'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CgpaScreen()),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
