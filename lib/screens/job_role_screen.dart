import 'package:flutter/material.dart';
import 'company_screen.dart';

class JobRoleScreen extends StatelessWidget {
  JobRoleScreen({Key? key}) : super(key: key);

  final List<String> roles = ["SDE", "Flutter Developer", "Cybersecurity", "Embedded", "Data Scientist", "DevOps"];

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Job Role'),
        backgroundColor: themeColor,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // search / hint
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search roles (e.g. SDE, Flutter)...',
                        ),
                        onChanged: (q) {
                          // optional: implement filtering later
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {},
                      color: themeColor,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // roles grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final icon = _iconForRole(role);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CompanyScreen(role: role)),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: themeColor, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    role,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _subtitleForRole(role),
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // quick actionr
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.question_answer),
                label: const Text('Request Custom Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(String role) {
    final r = role.toLowerCase();
    if (r.contains('flutter')) return Icons.phone_iphone;
    if (r.contains('sde') || r.contains('developer')) return Icons.code;
    if (r.contains('data')) return Icons.bar_chart;
    if (r.contains('devops')) return Icons.cloud;
    if (r.contains('cyber')) return Icons.security;
    if (r.contains('embedded')) return Icons.memory;
    return Icons.work;
  }

  String _subtitleForRole(String role) {
    final r = role.toLowerCase();
    if (r.contains('flutter')) return 'Mobile UI & cross-platform apps';
    if (r.contains('sde')) return 'Software development & problem solving';
    if (r.contains('data')) return 'ML, analysis & data pipelines';
    if (r.contains('devops')) return 'CI/CD, infra & automation';
    if (r.contains('cyber')) return 'Security & vulnerability testing';
    if (r.contains('embedded')) return 'Firmware & low-level systems';
    return 'Explore opportunities';
  }
}
