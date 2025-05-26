// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class DynamicHeader extends StatelessWidget {
//   final VoidCallback onMenuTap;
//   final String userType;

//   const DynamicHeader({Key? key, required this.onMenuTap, required this.userType}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           /// 🏠 Hamburger Icon for Sidebar Toggle
//           GestureDetector(
//             onTap: onMenuTap,
//             child: Icon(Icons.menu, size: 28.sp, color: Colors.black),
//           ),

//           /// 🔔 Notifications & Messages
//           Row(
//             children: [
//               _buildIconWithBadge(Icons.notifications, 4),
//               SizedBox(width: 15.w),
//               _buildIconWithBadge(Icons.message, 2),
//               SizedBox(width: 15.w),

//               /// 👤 Profile Avatar (Clickable)
//               GestureDetector(
//                 onTap: () => _showProfileMenu(context),
//                 child: CircleAvatar(
//                   radius: 20.r,
//                   backgroundImage: AssetImage("assets/user_avatar.png"),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🔔 Badge Icon Widget
//   Widget _buildIconWithBadge(IconData icon, int count) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Icon(icon, size: 28.sp, color: Colors.black),
//         if (count > 0)
//           Positioned(
//             right: -4,
//             top: -4,
//             child: Container(
//               padding: EdgeInsets.all(4.r),
//               decoration: BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 "$count",
//                 style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   /// 👤 Profile Dropdown Menu
//   void _showProfileMenu(BuildContext context) {
//     showMenu(
//       context: context,
//       position: RelativeRect.fromLTRB(100.w, 80.h, 20.w, 0),
//       items: [
//         PopupMenuItem(child: Text("My Profile"), value: "profile"),
//         PopupMenuItem(child: Text("Logout"), value: "logout"),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

class AdminHeader extends StatefulWidget implements PreferredSizeWidget {
  const AdminHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
  final List<Message> _messages = [
    Message(
      clientName: 'John Doe',
      message: 'Need help with plot allocation...',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Message(
      clientName: 'Jane Smith',
      message: 'Payment confirmation received?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Message(
      clientName: 'Mike Johnson',
      message: 'Regarding estate documents...',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  bool _showMessages = false;
  int _unreadCount = 3;

  void _toggleMessages() {
    setState(() {
      _showMessages = !_showMessages;
      if (_showMessages) _unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Admin Dashboard',
        style: TextStyle(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),
      elevation: 2,
      shadowColor: Colors.black12,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.message_outlined),
              color: Colors.black87,
              onPressed: _toggleMessages,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: CustomBadge(
                badgeColor: Colors.redAccent,
                padding: const EdgeInsets.all(5),
                badgeContent: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                showBadge: _unreadCount > 0,
                child: const SizedBox.shrink(),
              ),
            ),
            if (_showMessages)
              Positioned(
                right: 20,
                top: kToolbarHeight + 10,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Recent Messages',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  message.clientName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  message.message,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  timeAgo(message.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  // Handle message click
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton.icon(
                            icon: const Icon(Icons.message),
                            label: const Text('View All Messages'),
                            onPressed: () {
                              // Navigate to full messages screen
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 365) return '${(duration.inDays / 365).floor()}y ago';
    if (duration.inDays > 30) return '${(duration.inDays / 30).floor()}mo ago';
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }
}

/// A custom Badge widget to show unread count.
class CustomBadge extends StatelessWidget {
  final Widget child;
  final Widget badgeContent;
  final Color badgeColor;
  final EdgeInsetsGeometry padding;
  final bool showBadge;

  const CustomBadge({
    super.key,
    required this.child,
    required this.badgeContent,
    this.badgeColor = Colors.red,
    this.padding = const EdgeInsets.all(4),
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showBadge)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: badgeContent,
            ),
          ),
      ],
    );
  }
}

class Message {
  final String clientName;
  final String message;
  final DateTime timestamp;
  bool isRead;

  Message({
    required this.clientName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}
