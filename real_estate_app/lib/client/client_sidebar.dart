import 'package:flutter/material.dart';

class ClientSidebar extends StatelessWidget {
  final VoidCallback closeSidebar;

  const ClientSidebar({super.key, required this.closeSidebar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900.withOpacity(0.9),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Stylish header area
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent, Colors.indigo]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage("assets/avater.webp"),
                ),
                SizedBox(height: 10),
                Text(
                  "Hello, Client!",
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Welcome back 👋",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Menu items using proper routing
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildMenuItem(context, Icons.dashboard, "Dashboard", "/dashboard"),
                buildMenuItem(context, Icons.person, "Profile", "/profile"),
                buildMenuItem(
                    context, Icons.list_alt, "My Property List", "/property-list"),
                buildMenuItem(
                    context, Icons.add_home, "Request New Property", "/request-property"),
                buildMenuItem(
                    context, Icons.mail_outline, "View Requests", "/view-requests"),
                buildMenuItem(
                    context, Icons.chat_bubble, "Chat Admin", "/chat-admin",
                    badgeCount: 1),
              ],
            ),
          ),
          Divider(color: Colors.white54),
          // Logout button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              "Logout",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, "/login");
            },
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem(BuildContext context, IconData icon, String title,
      String route, {int? badgeCount}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      trailing: badgeCount != null
          ? CircleAvatar(
              radius: 10,
              backgroundColor: Colors.redAccent,
              child: Text('$badgeCount',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
            )
          : null,
      onTap: () {
        // Close the sidebar and navigate to the given route.
        closeSidebar();
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
