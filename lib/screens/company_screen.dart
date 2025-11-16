import 'package:flutter/material.dart';
import 'technical_screen.dart';

class CompanyScreen extends StatelessWidget {
  final String role;
  CompanyScreen({Key? key, required this.role}) : super(key: key);

  final companies = ["amazon", "google", "infosys", "tcs", "wipro"];

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal;
    return Scaffold(
      backgroundColor: themeColor.shade50,
      appBar: AppBar(
        title: const Text("Select Company"),
        backgroundColor: themeColor.shade700,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search / Hint Cardr
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search companies (e.g. Google, Amazon)',
                          border: InputBorder.none,
                        ),
                        onChanged: (q) {
                          // optional: add filtering state later
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      color: themeColor.shade700,
                      onPressed: () {},
                      tooltip: 'Sort',
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Companies grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.2,
                ),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final display = company.toUpperCase();
                  final initials = company.length <= 2 ? display : display.substring(0, 2);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TechnicalScreen(role: role, company: company),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: themeColor.shade100,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: themeColor.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(display, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap to take ${role.toUpperCase()} test',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text('Request Company Addition'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request submitted — we will review and add the company.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
