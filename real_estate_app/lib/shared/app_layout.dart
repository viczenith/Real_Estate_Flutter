import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_app/shared/app_side.dart';
import 'package:real_estate_app/shared/header.dart';
import 'package:real_estate_app/core/api_service.dart';
import 'package:real_estate_app/client/client_sidebar.dart';
import 'package:real_estate_app/marketer/marketer_sidebar.dart';

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
  static const _kClientCacheKey = 'cache_client_profile_v1';
  static const _kMarketerCacheKey = 'cache_marketer_profile_v1';

  bool _isSidebarVisible = false;

  Map<String, dynamic>? clientData;
  bool _loadingClient = false;

  Map<String, dynamic>? marketerData;
  bool _loadingMarketer = false;

  @override
  void initState() {
    super.initState();
    _loadingClient = false;
    _loadingMarketer = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedThenRefresh();
    });
  }

  Future<void> _loadCachedThenRefresh() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.side == AppSide.client) {
      final cached = prefs.getString(_kClientCacheKey);
      if (cached != null) {
        try {
          clientData = json.decode(cached) as Map<String, dynamic>;
        } catch (_) {
          clientData = null;
        }
        if (mounted) setState(() {});
        _fetchClientAndCache();
      } else {
        if (mounted) setState(() => _loadingClient = true);
        _fetchClientAndCache();
      }
    }

    if (widget.side == AppSide.marketer) {
      final cached = prefs.getString(_kMarketerCacheKey);
      if (cached != null) {
        try {
          marketerData = json.decode(cached) as Map<String, dynamic>;
        } catch (_) {
          marketerData = null;
        }
        if (mounted) setState(() {});
        _fetchMarketerAndCache();
      } else {
        if (mounted) setState(() => _loadingMarketer = true);
        _fetchMarketerAndCache();
      }
    }
  }

  Future<void> _fetchClientAndCache() async {
    final api = ApiService();
    try {
      final data = await api.getClientDetailByToken(token: widget.token).timeout(const Duration(seconds: 10));
      if (data is Map<String, dynamic>) clientData = Map<String, dynamic>.from(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kClientCacheKey, json.encode(clientData));
    } catch (e, st) {
      debugPrint('Client refresh failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _loadingClient = false);
    }
  }

  Future<void> _fetchMarketerAndCache() async {
    final api = ApiService();
    try {
      final data = await api.getMarketerProfileByToken(token: widget.token).timeout(const Duration(seconds: 10));
      if (data is Map<String, dynamic>) marketerData = Map<String, dynamic>.from(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMarketerCacheKey, json.encode(marketerData));
    } catch (e, st) {
      debugPrint('Marketer refresh failed: $e\n$st');
    } finally {
      if (mounted) setState(() => _loadingMarketer = false);
    }
  }

  Future<void> refreshProfile() async {
    if (widget.side == AppSide.client) {
      if (mounted) setState(() => _loadingClient = true);
      await _fetchClientAndCache();
    } else if (widget.side == AppSide.marketer) {
      if (mounted) setState(() => _loadingMarketer = true);
      await _fetchMarketerAndCache();
    }
  }

  void toggleSidebar(AppSide side) {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void handleMenuItemTap(String route) {
    debugPrint('handleMenuItemTap -> $route');
    setState(() {
      _isSidebarVisible = false;
    });

    final tokenRequired = {
      '/admin-dashboard',
      '/admin-clients',
      '/client-dashboard',
      '/client-profile',
      '/client-chat-admin',
      '/client-property-details',
      '/marketer-dashboard',
      '/marketer-clients',
      '/marketer-profile',
      '/marketer-notifications',
    };

    if (tokenRequired.contains(route)) {
      Navigator.pushNamed(context, route, arguments: widget.token);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  Widget _buildSidebar({required bool isExpanded}) {
    switch (widget.side) {
      case AppSide.client:
        return ClientSidebar(
          isExpanded: isExpanded,
          onMenuItemTap: handleMenuItemTap,
          onToggle: () => toggleSidebar(widget.side),
          profileImageUrl: clientData?['profile_image'],
          clientName: clientData?['full_name'] ?? "Client",
        );

      case AppSide.marketer:
        return MarketerSidebar(
          isExpanded: isExpanded,
          onMenuItemTap: handleMenuItemTap,
          onToggle: () => toggleSidebar(widget.side),
          profileImageUrl: marketerData?['profile_image'],
          marketerName: marketerData?['full_name'] ?? "Marketer",
        );

      case AppSide.admin:
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
    if ((widget.side == AppSide.client && _loadingClient) ||
        (widget.side == AppSide.marketer && _loadingMarketer)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;

    return Scaffold(
      appBar: SharedHeader(
        title: widget.pageTitle,
        side: widget.side,
        onMenuToggle: isLargeScreen ? null : (side) => toggleSidebar(side),
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            SizedBox(width: 250, child: _buildSidebar(isExpanded: true)),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFF5F3FF)]),
                  ),
                  child: widget.child,
                ),
                if (!isLargeScreen)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: _isSidebarVisible ? 0 : -250,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(width: 250, child: _buildSidebar(isExpanded: true)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// PlaceholderSidebar unchanged — reuse your existing placeholder code or keep below.
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(4, 6))],
        borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: isExpanded ? 16 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.blueAccent.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(0)),
            ),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (isExpanded)
                  Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Text(title[0], style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Hello, $title!", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Welcome back 👋", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      ]),
                    ],
                  )
                else
                  CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Text(title[0], style: const TextStyle(color: Colors.white))),
                IconButton(icon: Icon(isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded, color: Colors.white), onPressed: onToggle),
              ],
            ),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 12), children: [
            _menuTile(Icons.dashboard_rounded, "$title Dashboard", '/${title.toLowerCase()}-dashboard'),
            _menuTile(Icons.people_rounded, "$title Clients", '/${title.toLowerCase()}-clients'),
            _menuTile(Icons.notifications_rounded, "$title Notifications", '/${title.toLowerCase()}-notifications'),
          ])),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 4, vertical: 6),
            child: Column(children: [
              ListTile(leading: const Icon(Icons.settings_rounded, color: Colors.blueAccent), title: isExpanded ? const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)) : null, onTap: () => onMenuItemTap('/${title.toLowerCase()}-settings')),
              ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), title: isExpanded ? const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)) : null, onTap: () => onMenuItemTap('/login')),
              const SizedBox(height: 12),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, String route) {
    return ListTile(leading: Icon(icon, color: Colors.grey.shade700), title: isExpanded ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600)) : null, onTap: () => onMenuItemTap(route));
  }
}
