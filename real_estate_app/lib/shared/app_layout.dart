// import 'package:flutter/material.dart';
// import 'package:real_estate_app/client/client_sidebar.dart';
// import 'header.dart';

// class AppLayout extends StatefulWidget {
//   final Widget child;
//   final String pageTitle;
//   final String token;
//   final AppSide side;

//   const AppLayout(required String pageTitle, {
//     Key? key,
//     required this.child,
//     required this.pageTitle,
//     required this.token,
//     required this.side,
//   }) : super(key: key);

//   @override
//   State<AppLayout> createState() => _AppLayoutState();
// }

// class _AppLayoutState extends State<AppLayout> {
//   bool _isSidebarVisible = false;

//   void toggleSidebar(AppSide side) {
//     setState(() {
//       _isSidebarVisible = !_isSidebarVisible;
//     });
//   }

//   void handleMenuItemTap(String route) {
//     // Hide overlay/sidebar when navigating
//     setState(() {
//       _isSidebarVisible = false;
//     });

//     // For routes that need a token, pass it as arguments.
//     final tokenRequired = {
//       '/client-dashboard',
//       '/client-profile',
//       '/client-chat-admin',
//       '/client-property-details',
//       '/admin-dashboard',
//       '/admin-clients',
//       '/marketer-dashboard',
//     };

//     if (tokenRequired.contains(route)) {
//       Navigator.pushNamed(context, route, arguments: widget.token);
//     } else {
//       Navigator.pushNamed(context, route);
//     }
//   }

//   /// Build the appropriate sidebar for the active side.
//   Widget _buildSidebar({required bool isExpanded}) {
//     switch (widget.side) {
//       case AppSide.client:
//         return ClientSidebar(
//           isExpanded: isExpanded,
//           onMenuItemTap: handleMenuItemTap,
//           onToggle: () => toggleSidebar(widget.side),
//         );

//       case AppSide.marketer:
//         // TODO: Replace PlaceholderSidebar with your MarketerSidebar when available.
//         return PlaceholderSidebar(
//           title: 'Marketer',
//           isExpanded: isExpanded,
//           onMenuItemTap: handleMenuItemTap,
//           onToggle: () => toggleSidebar(widget.side),
//         );

//       case AppSide.admin:
//         // TODO: Replace PlaceholderSidebar with your AdminSidebar when available.
//         return PlaceholderSidebar(
//           title: 'Admin',
//           isExpanded: isExpanded,
//           onMenuItemTap: handleMenuItemTap,
//           onToggle: () => toggleSidebar(widget.side),
//         );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isLargeScreen = screenWidth >= 1024;

//     return Scaffold(
//       appBar: SharedHeader(
//         title: widget.pageTitle,
//         side: widget.side,
//         // If large screen, we don't show a hamburger (sidebar is always visible).
//         onMenuToggle: isLargeScreen ? null : (side) => toggleSidebar(side),
//         // Optionally: you can pass messages/notifications lists here when available.
//         // messages: myMessages,
//         // notifications: myNotifications,
//       ),
//       body: Row(
//         children: [
//           // Persistent sidebar on large screens
//           if (isLargeScreen)
//             SizedBox(
//               width: 250,
//               child: _buildSidebar(isExpanded: true),
//             ),

//           // Main content area (and overlay sidebar on mobile)
//           Expanded(
//             child: Stack(
//               children: [
//                 // Background + content
//                 Container(
//                   decoration: const BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [Colors.white, Color(0xFFF5F3FF)],
//                     ),
//                   ),
//                   child: widget.child,
//                 ),

//                 // Slide-in sidebar for small screens
//                 if (!isLargeScreen)
//                   AnimatedPositioned(
//                     duration: const Duration(milliseconds: 300),
//                     left: _isSidebarVisible ? 0 : -250,
//                     top: 0,
//                     bottom: 0,
//                     child: SizedBox(
//                       width: 250,
//                       child: _buildSidebar(isExpanded: true),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Simple placeholder sidebar widget that mirrors ClientSidebar's API enough
// /// for AppLayout to compile and show a usable UI for marketer/admin until you
// /// replace it with the actual MarketerSidebar/AdminSidebar implementation.
// class PlaceholderSidebar extends StatelessWidget {
//   final bool isExpanded;
//   final Function(String) onMenuItemTap;
//   final VoidCallback onToggle;
//   final String title;

//   const PlaceholderSidebar({
//     Key? key,
//     required this.isExpanded,
//     required this.onMenuItemTap,
//     required this.onToggle,
//     required this.title,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final double width = isExpanded ? 240 : 72;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: width,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 18,
//             offset: const Offset(4, 6),
//           )
//         ],
//         borderRadius: const BorderRadius.only(
//             topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding:
//                 EdgeInsets.symmetric(vertical: 20, horizontal: isExpanded ? 16 : 8),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.indigo.shade700, Colors.blueAccent.shade400],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: const BorderRadius.only(
//                   topRight: Radius.circular(16), bottomRight: Radius.circular(0)),
//             ),
//             child: Row(
//               mainAxisAlignment:
//                   isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
//               children: [
//                 if (isExpanded)
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 20,
//                         backgroundColor: Colors.white24,
//                         child: Text(title[0], style: const TextStyle(color: Colors.white)),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Hello, $title!",
//                               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   )),
//                           const SizedBox(height: 4),
//                           Text("Welcome back 👋",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodySmall
//                                   ?.copyWith(color: Colors.white70)),
//                         ],
//                       ),
//                     ],
//                   )
//                 else
//                   CircleAvatar(
//                     radius: 18,
//                     backgroundColor: Colors.white24,
//                     child: Text(title[0], style: const TextStyle(color: Colors.white)),
//                   ),

//                 IconButton(
//                   icon: Icon(isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
//                       color: Colors.white),
//                   onPressed: onToggle,
//                 ),
//               ],
//             ),
//           ),

//           // Minimal menu (replace with your actual menu items)
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               children: [
//                 _menuTile(Icons.dashboard_rounded, "$title Dashboard", '/${title.toLowerCase()}-dashboard'),
//                 _menuTile(Icons.people_rounded, "$title Clients", '/${title.toLowerCase()}-clients'),
//                 _menuTile(Icons.notifications_rounded, "$title Notifications", '/${title.toLowerCase()}-notifications'),
//               ],
//             ),
//           ),

//           const Divider(height: 1),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 4, vertical: 6),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.settings_rounded, color: Colors.blueAccent),
//                   title: isExpanded ? const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)) : null,
//                   onTap: () => onMenuItemTap('/${title.toLowerCase()}-settings'),
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
//                   title: isExpanded ? const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)) : null,
//                   onTap: () => onMenuItemTap('/login'),
//                 ),
//                 const SizedBox(height: 12),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _menuTile(IconData icon, String label, String route) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.grey.shade700),
//       title: isExpanded ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600)) : null,
//       onTap: () => onMenuItemTap(route),
//     );
//   }
// }

// // app_layout.dart
// import 'package:flutter/material.dart';
// import 'package:real_estate_app/client/client_sidebar.dart';
// import 'header.dart';

// /// AppLayout: shared layout for Client / Marketer / Admin sides.
// /// - Pass `side` so SharedHeader can decide which icons to show.
// /// - The hamburger calls onMenuToggle(AppSide) — AppLayout toggles its local sidebar.
// class AppLayout extends StatefulWidget {
//   final Widget child;
//   final String pageTitle;
//   final String token;
//   final AppSide side; // client | marketer | admin

//   const AppLayout({
//     Key? key,
//     required this.child,
//     required this.pageTitle,
//     required this.token,
//     required this.side,
//   }) : super(key: key);

//   @override
//   State<AppLayout> createState() => _AppLayoutState();
// }

// class _AppLayoutState extends State<AppLayout> {
//   bool _isSidebarVisible = false;

//   /// Toggle sidebar. We accept the side argument because SharedHeader will pass it.
//   void toggleSidebar(AppSide side) {
//     setState(() {
//       _isSidebarVisible = !_isSidebarVisible;
//     });
//   }

//   void handleMenuItemTap(String route) {
//     // Hide overlay/sidebar when navigating
//     setState(() {
//       _isSidebarVisible = false;
//     });

//     // For routes that need a token, pass it as arguments.
//     final tokenRequired = {
//       '/client-dashboard',
//       '/client-profile',
//       '/client-chat-admin',
//       '/client-property-details',
//       '/admin-dashboard',
//       '/admin-clients',
//       '/marketer-dashboard',
//     };

//     if (tokenRequired.contains(route)) {
//       Navigator.pushNamed(context, route, arguments: widget.token);
//     } else {
//       Navigator.pushNamed(context, route);
//     }
//   }

//   /// Build the appropriate sidebar for the active side.
//   Widget _buildSidebar({required bool isExpanded}) {
//     switch (widget.side) {
//       case AppSide.client:
//         // NOTE: use the same parameter names as PlaceholderSidebar:
//         // onMenuItemTap, onToggle, closeSidebar
//         return ClientSidebar(
//           isExpanded: isExpanded,
//           onMenuItemTap: handleMenuItemTap,
//           onToggle: () => toggleSidebar(widget.side),
//           closeSidebar: () {
//             setState(() {
//               _isSidebarVisible = false;
//             });
//           },
//         );

//       case AppSide.marketer:
//         // TODO: Replace PlaceholderSidebar with your MarketerSidebar when available.
//         return PlaceholderSidebar(
//           title: 'Marketer',
//           isExpanded: isExpanded,
//           onMenuItemTap: handleMenuItemTap,
//           onToggle: () => toggleSidebar(widget.side),
//         );

//       case AppSide.admin:
//         // TODO: Replace PlaceholderSidebar with your AdminSidebar when available.
//         return PlaceholderSidebar(
//           title: 'Admin',
//           isExpanded: isExpanded,
//           onMenuItemTap: handleMenuItemTap,
//           onToggle: () => toggleSidebar(widget.side),
//         );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isLargeScreen = screenWidth >= 1024;

//     return Scaffold(
//       appBar: SharedHeader(
//         title: widget.pageTitle,
//         side: widget.side,
//         // If large screen, we don't show a hamburger (sidebar is always visible).
//         onMenuToggle: isLargeScreen ? null : (side) => toggleSidebar(side),
//         // Optionally: you can pass messages/notifications lists here when available.
//         // messages: myMessages,
//         // notifications: myNotifications,
//       ),
//       body: Row(
//         children: [
//           // Persistent sidebar on large screens
//           if (isLargeScreen)
//             SizedBox(
//               width: 250,
//               child: _buildSidebar(isExpanded: true),
//             ),

//           // Main content area (and overlay sidebar on mobile)
//           Expanded(
//             child: Stack(
//               children: [
//                 // Background + content
//                 Container(
//                   decoration: const BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [Colors.white, Color(0xFFF5F3FF)],
//                     ),
//                   ),
//                   child: widget.child,
//                 ),

//                 // Slide-in sidebar for small screens
//                 if (!isLargeScreen)
//                   AnimatedPositioned(
//                     duration: const Duration(milliseconds: 300),
//                     left: _isSidebarVisible ? 0 : -250,
//                     top: 0,
//                     bottom: 0,
//                     child: SizedBox(
//                       width: 250,
//                       child: _buildSidebar(isExpanded: true),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Simple placeholder sidebar widget that mirrors ClientSidebar's API enough
// /// for AppLayout to compile and show a usable UI for marketer/admin until you
// /// replace it with the actual MarketerSidebar/AdminSidebar implementation.
// class PlaceholderSidebar extends StatelessWidget {
//   final bool isExpanded;
//   final ValueChanged<String> onMenuItemTap;
//   final VoidCallback onToggle;
//   final String title;

//   const PlaceholderSidebar({
//     Key? key,
//     required this.isExpanded,
//     required this.onMenuItemTap,
//     required this.onToggle,
//     required this.title,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final double width = isExpanded ? 240 : 72;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: width,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 18,
//             offset: const Offset(4, 6),
//           )
//         ],
//         borderRadius: const BorderRadius.only(
//             topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding:
//                 EdgeInsets.symmetric(vertical: 20, horizontal: isExpanded ? 16 : 8),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.indigo.shade700, Colors.blueAccent.shade400],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: const BorderRadius.only(
//                   topRight: Radius.circular(16), bottomRight: Radius.circular(0)),
//             ),
//             child: Row(
//               mainAxisAlignment:
//                   isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
//               children: [
//                 if (isExpanded)
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 20,
//                         backgroundColor: Colors.white24,
//                         child: Text(title[0], style: const TextStyle(color: Colors.white)),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Hello, $title!",
//                               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                   )),
//                           const SizedBox(height: 4),
//                           Text("Welcome back 👋",
//                               style:
//                                   Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
//                         ],
//                       ),
//                     ],
//                   )
//                 else
//                   CircleAvatar(
//                     radius: 18,
//                     backgroundColor: Colors.white24,
//                     child: Text(title[0], style: const TextStyle(color: Colors.white)),
//                   ),
//                 IconButton(
//                   icon: Icon(isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
//                       color: Colors.white),
//                   onPressed: onToggle,
//                 ),
//               ],
//             ),
//           ),

//           // Minimal menu (replace with your actual menu items)
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               children: [
//                 _menuTile(Icons.dashboard_rounded, "$title Dashboard",
//                     '/${title.toLowerCase()}-dashboard'),
//                 _menuTile(Icons.people_rounded, "$title Clients",
//                     '/${title.toLowerCase()}-clients'),
//                 _menuTile(Icons.notifications_rounded, "$title Notifications",
//                     '/${title.toLowerCase()}-notifications'),
//               ],
//             ),
//           ),

//           const Divider(height: 1),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 4, vertical: 6),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: const Icon(Icons.settings_rounded, color: Colors.blueAccent),
//                   title: isExpanded
//                       ? const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold))
//                       : null,
//                   onTap: () => onMenuItemTap('/${title.toLowerCase()}-settings'),
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
//                   title: isExpanded
//                       ? const Text("Logout",
//                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))
//                       : null,
//                   onTap: () => onMenuItemTap('/login'),
//                 ),
//                 const SizedBox(height: 12),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _menuTile(IconData icon, String label, String route) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.grey.shade700),
//       title: isExpanded ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600)) : null,
//       onTap: () => onMenuItemTap(route),
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:real_estate_app/client/client_sidebar.dart';
import 'header.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String pageTitle;
  final String token;
  final AppSide side;

  const AppLayout({
    Key? key,
    required this.child,
    required this.pageTitle,
    required this.token,
    required this.side,
  }) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _isSidebarVisible = false;

  /// Toggle sidebar. We accept the side argument because SharedHeader will pass it.
  void toggleSidebar(AppSide side) {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void handleMenuItemTap(String route) {
    // Hide overlay/sidebar when navigating
    setState(() {
      _isSidebarVisible = false;
    });

    // For routes that need a token, pass it as arguments.
    final tokenRequired = {
      '/client-dashboard',
      '/client-profile',
      '/client-chat-admin',
      '/client-property-details',
      '/admin-dashboard',
      '/admin-clients',
      '/marketer-dashboard',
    };

    if (tokenRequired.contains(route)) {
      Navigator.pushNamed(context, route, arguments: widget.token);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  /// Build the appropriate sidebar for the active side.
  Widget _buildSidebar({required bool isExpanded}) {
    switch (widget.side) {
      case AppSide.client:
        // Client sidebar now shares the same API as AdminSidebar.
        return ClientSidebar(
          isExpanded: isExpanded,
          onMenuItemTap: handleMenuItemTap,
          onToggle: () => toggleSidebar(widget.side),
        );

      case AppSide.marketer:
        // TODO: Replace PlaceholderSidebar with your MarketerSidebar when available.
        return PlaceholderSidebar(
          title: 'Marketer',
          isExpanded: isExpanded,
          onMenuItemTap: handleMenuItemTap,
          onToggle: () => toggleSidebar(widget.side),
        );

      case AppSide.admin:
        // TODO: Replace PlaceholderSidebar with your AdminSidebar when available.
        return PlaceholderSidebar(
          title: 'Admin',
          isExpanded: isExpanded,
          onMenuItemTap: handleMenuItemTap,
          onToggle: () => toggleSidebar(widget.side),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;

    return Scaffold(
      appBar: SharedHeader(
        title: widget.pageTitle,
        side: widget.side,
        // If large screen, we don't show a hamburger (sidebar is always visible).
        onMenuToggle: isLargeScreen ? null : (side) => toggleSidebar(side),
        // Optionally: you can pass messages/notifications lists here when available.
        // messages: myMessages,
        // notifications: myNotifications,
      ),
      body: Row(
        children: [
          // Persistent sidebar on large screens
          if (isLargeScreen)
            SizedBox(
              width: 250,
              child: _buildSidebar(isExpanded: true),
            ),

          // Main content area (and overlay sidebar on mobile)
          Expanded(
            child: Stack(
              children: [
                // Background + content
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFF5F3FF)],
                    ),
                  ),
                  child: widget.child,
                ),

                // Slide-in sidebar for small screens
                if (!isLargeScreen)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: _isSidebarVisible ? 0 : -250,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 250,
                      // when overlaying on mobile we show expanded content for clarity
                      child: _buildSidebar(isExpanded: true),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple placeholder sidebar widget that mirrors Admin/Client sidebar API.
/// Useful until you wire the marketer/admin implementations.
class PlaceholderSidebar extends StatelessWidget {
  final bool isExpanded;
  final ValueChanged<String> onMenuItemTap;
  final VoidCallback onToggle;
  final String title;

  const PlaceholderSidebar({
    Key? key,
    required this.isExpanded,
    required this.onMenuItemTap,
    required this.onToggle,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = isExpanded ? 240 : 72;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(4, 6),
          )
        ],
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 20, horizontal: isExpanded ? 16 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.blueAccent.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(0)),
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (isExpanded)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Text(title[0],
                            style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello, $title!",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  )),
                          const SizedBox(height: 4),
                          Text("Welcome back 👋",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  )
                else
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Text(title[0],
                        style: const TextStyle(color: Colors.white)),
                  ),
                IconButton(
                  icon: Icon(
                      isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                      color: Colors.white),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),

          // Minimal menu (replace with your actual menu items)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _menuTile(Icons.dashboard_rounded, "$title Dashboard",
                    '/${title.toLowerCase()}-dashboard'),
                _menuTile(Icons.people_rounded, "$title Clients",
                    '/${title.toLowerCase()}-clients'),
                _menuTile(Icons.notifications_rounded, "$title Notifications",
                    '/${title.toLowerCase()}-notifications'),
              ],
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 4, vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_rounded, color: Colors.blueAccent),
                  title: isExpanded
                      ? const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold))
                      : null,
                  onTap: () => onMenuItemTap('/${title.toLowerCase()}-settings'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: isExpanded
                      ? const Text("Logout",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))
                      : null,
                  onTap: () => onMenuItemTap('/login'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: isExpanded ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600)) : null,
      onTap: () => onMenuItemTap(route),
    );
  }
}
