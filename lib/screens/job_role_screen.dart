import 'package:flutter/material.dart';
import 'company_screen.dart';

class JobRoleScreen extends StatelessWidget {
  final roles = ["SDE", "Flutter Developer", "Cybersecurity", "Embedded"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Job Role")),
      body: ListView.builder(
        itemCount: roles.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(roles[index]),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyScreen(role: roles[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
