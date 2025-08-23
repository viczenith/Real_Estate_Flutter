import 'dart:math';

import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class ClientSidebar extends StatefulWidget {
  final bool isExpanded;
  final Function(String) onMenuItemTap;
  final VoidCallback onToggle;

  final String? profileImageUrl;
  final String clientName;

  const ClientSidebar({
    Key? key,
    required this.isExpanded,
    required this.onMenuItemTap,
    required this.onToggle,
    required this.profileImageUrl,
    required this.clientName,
  }) : super(key: key);

  @override
  State<ClientSidebar> createState() => _ClientSidebarState();
}

class _ClientSidebarState extends State<ClientSidebar> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _hoverIndex = -1;

  static const Color primaryColor = Color(0xFF5E35B1);

  late final AnimationController _pulseController;

  final List<SidebarItem> _menuItems = [
    SidebarItem(icon: Icons.dashboard_rounded, title: "Dashboard", route: '/client-dashboard'),
    SidebarItem(icon: Icons.person_rounded, title: "Profile", route: '/client-profile'),
    SidebarItem(icon: Icons.list_alt_rounded, title: "My Property List", route: '/client-property-list'),
    SidebarItem(icon: Icons.add_home_rounded, title: "Request New Property", route: '/client-request-property'),
    SidebarItem(icon: Icons.mail_outline_rounded, title: "View Requests", route: '/client-view-requests'),
    SidebarItem(icon: Icons.chat_rounded, title: "Chat Admin", route: '/client-chat-admin', notificationCount: 1),
    SidebarItem(icon: Icons.info_rounded, title: "Property Details", route: '/client-property-details'),
    SidebarItem(icon: Icons.notifications_active, title: "Notifications", route: '/client-notification', notificationCount: 3),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapItem(int index, SidebarItem item) {
    setState(() => _selectedIndex = index);
    widget.onMenuItemTap(item.route);
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder + MediaQuery to compute a responsive width
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Collapsed width and expanded width adapt to screen size.
        final double collapsedWidth = 64; // comfortable small width
        final double expandedWidth = screenWidth < 420
            ? max(180, screenWidth * 0.7) // on very narrow screens keep it smaller
            : 260; // default expanded width for tablet/desktop
        final double width = widget.isExpanded ? expandedWidth : collapsedWidth;

        return SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: width.clamp(56.0, min(360.0, screenWidth)),
            constraints: BoxConstraints(minWidth: 56, maxWidth: min(360, screenWidth)),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(6, 4))
              ],
              borderRadius: const BorderRadius.only(topRight: Radius.circular(18), bottomRight: Radius.circular(18)),
            ),
            child: Column(
              children: [
                _buildHeader(width),
                // main menu
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: widget.isExpanded ? 8 : 6),
                    child: Scrollbar(
                      radius: const Radius.circular(8),
                      thickness: 6,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _menuItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) => _buildMenuTile(index, _menuItems[index], width),
                      ),
                    ),
                  ),
                ),
                _buildFooter(width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double sidebarWidth) {
    final avatarRadius = widget.isExpanded ? (sidebarWidth * 0.09).clamp(16.0, 30.0) : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: widget.isExpanded ? 12 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.98), primaryColor.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          if (widget.isExpanded)
            Flexible(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                          ? NetworkImage(widget.profileImageUrl!)
                          : const AssetImage('assets/avater.webp') as ImageProvider,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, ${widget.clientName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text("Premium", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            CircleAvatar(
              radius: avatarRadius,
              backgroundImage: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.profileImageUrl!)
                  : const AssetImage('assets/avater.webp') as ImageProvider,
            ),
          const SizedBox(width: 6),
          // Toggle button
          IconButton(
            onPressed: widget.onToggle,
            splashRadius: 20,
            padding: const EdgeInsets.all(6),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.isExpanded ? Icons.chevron_left_rounded : Icons.menu,
                key: ValueKey<bool>(widget.isExpanded),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(int index, SidebarItem item, double sidebarWidth) {
    final bool isSelected = _selectedIndex == index;
    final bool isHovered = _hoverIndex == index;

    final bgColor = isSelected
        ? primaryColor.withOpacity(0.08)
        : (isHovered ? Colors.grey.withOpacity(0.06) : null);
    final iconColor = isSelected ? primaryColor : Colors.grey.shade700;
    final textColor = isSelected ? primaryColor : Colors.grey.shade800;

    // Common tile height
    const tileHeight = 48.0;

    if (!widget.isExpanded) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hoverIndex = index),
        onExit: (_) => setState(() => _hoverIndex = -1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Tooltip(
            message: item.title,
            waitDuration: const Duration(milliseconds: 300),
            child: Material(
              color: bgColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _onTapItem(index, item),
                child: Container(
                  height: tileHeight,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: badges.Badge(
                    showBadge: item.notificationCount > 0,
                    badgeStyle:
                        const badges.BadgeStyle(badgeColor: Colors.redAccent, padding: EdgeInsets.all(6)),
                    badgeContent: Text('${item.notificationCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                    child: Icon(item.icon, color: iconColor, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = index),
      onExit: (_) => setState(() => _hoverIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onTapItem(index, item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: isSelected
                        ? Tween<double>(begin: 0.98, end: 1.03).animate(_pulseController)
                        : const AlwaysStoppedAnimation(1.0),
                    child: badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                      showBadge: item.notificationCount > 0,
                      badgeStyle:
                          const badges.BadgeStyle(badgeColor: Colors.redAccent, padding: EdgeInsets.all(6)),
                      badgeContent: Text('${item.notificationCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                      child: Icon(item.icon, color: iconColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title with ellipsis and maxLines = 1
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 28,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 3))
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double sidebarWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 12 : 6, vertical: 8),
          child: Row(
            children: [
              if (widget.isExpanded)
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => widget.onMenuItemTap('/client-settings'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Settings', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Preferences & account', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                          onPressed: () => widget.onMenuItemTap('/client-support'),
                          icon: Icon(Icons.support_agent_rounded, color: primaryColor)),
                    ],
                  ),
                )
              else
                IconButton(
                    onPressed: () => widget.onMenuItemTap('/client-settings'),
                    icon: Icon(Icons.settings, color: Colors.grey.shade700)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 12 : 6, vertical: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 44),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                firstCurve: Curves.easeOut,
                secondCurve: Curves.easeIn,
              ),
              onPressed: () => widget.onMenuItemTap('/login'),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String title;
  final String route;
  final int notificationCount;

  SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    this.notificationCount = 0,
  });
}
