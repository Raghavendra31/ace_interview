import 'package:flutter/material.dart';
import 'technical_screen.dart';

class CompanyScreen extends StatelessWidget {
  final String role;
  CompanyScreen({required this.role});

  final companies = ["amazon", "google", "infosys", "tcs", "wipro"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Company")),
      body: ListView.builder(
        itemCount: companies.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(companies[index].toUpperCase()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TechnicalScreen(
                    role: role,
                    company: companies[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
