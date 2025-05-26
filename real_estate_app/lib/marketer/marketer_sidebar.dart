import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MarketerSidebar extends StatelessWidget {
  final Function(String) onMenuItemTap;

  const MarketerSidebar({super.key, required this.onMenuItemTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 30, backgroundImage: AssetImage('assets/logo.jpg')),
                SizedBox(height: 10),
                Text("Marketer Panel", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildSidebarItem(context, Icons.dashboard, "Dashboard", '/marketer-dashboard'),
          _buildSidebarItem(context, Icons.people, "My Clients", '/marketer-clients'),
          _buildSidebarItem(context, Icons.business, "Commissions", '/marketer-commission'),
          _buildSidebarItem(context, Icons.assignment, "Notifications", '/marketer-notifications'),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
