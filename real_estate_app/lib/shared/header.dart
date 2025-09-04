import 'dart:math';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:real_estate_app/shared/app_side.dart';

class SharedHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final AppSide side;
  final ValueChanged<AppSide>? onMenuToggle;

  final bool showNotifications;
  final bool showMessages;

  final List<Message> messages;
  final List<NotificationItem> notifications;

  final Widget? companyLogo;
  final VoidCallback? onCompanyLogoTap;

  final VoidCallback? onMessagesOpened;
  final VoidCallback? onNotificationsOpened;
  final VoidCallback? onViewMessageHistory;
  final VoidCallback? onViewNotificationHistory;

  const SharedHeader({
    Key? key,
    required this.title,
    required this.side,
    this.onMenuToggle,
    this.showNotifications = false,
    this.showMessages = false,
    this.messages = const <Message>[],
    this.notifications = const <NotificationItem>[],
    this.companyLogo,
    this.onCompanyLogoTap,
    this.onMessagesOpened,
    this.onNotificationsOpened,
    this.onViewMessageHistory,
    this.onViewNotificationHistory,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SharedHeader> createState() => _SharedHeaderState();
}

class _SharedHeaderState extends State<SharedHeader> {
  OverlayEntry? _messagesOverlay;
  OverlayEntry? _notificationsOverlay;

  final GlobalKey _messageIconKey = GlobalKey();
  final GlobalKey _notifIconKey = GlobalKey();

  // keep a small notifications fallback to avoid NPE when notifications list is entirely empty
  final List<NotificationItem> _mockNotifications = [
    NotificationItem(title: 'Payment Received', body: 'Payment for plot B-12 has been confirmed.', timestamp: DateTime.now().subtract(const Duration(minutes: 36))),
    NotificationItem(title: 'New Property Added', body: 'Starlight II Estate - 6 new plots available.', timestamp: DateTime.now().subtract(const Duration(hours: 4))),
    NotificationItem(title: 'System Notice', body: 'Maintenance scheduled for Aug 20, 2:00 AM.', timestamp: DateTime.now().subtract(const Duration(days: 2))),
  ];

  // messages now come straight from widget.messages (no fallback/mock)
  List<Message> get _messages => widget.messages;
  List<NotificationItem> get _notifications => widget.notifications.isEmpty ? _mockNotifications : widget.notifications;

  int get _unreadMessagesCount => _messages.where((m) => !m.isRead).length;
  int get _unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  @override
  void dispose() {
    _removeMessagesOverlay();
    _removeNotificationsOverlay();
    super.dispose();
  }

  // note: these helpers still exist if you want to open overlays programmatically
  void _toggleMessages() {
    if (_messagesOverlay == null) {
      _showListOverlay(
        key: _messageIconKey,
        title: 'Unread Messages',
        icon: Icons.message,
        itemsHeight: 220,
        contentBuilder: _buildMessagesList,
        setOverlay: (entry) => _messagesOverlay = entry,
        removeOtherOverlay: _removeNotificationsOverlay,
      );
      widget.onMessagesOpened?.call();
    } else {
      _removeMessagesOverlay();
    }
  }

  void _toggleNotifications() {
    if (_notificationsOverlay == null) {
      _showListOverlay(
        key: _notifIconKey,
        title: 'Notifications',
        icon: Icons.notifications_rounded,
        itemsHeight: 240,
        contentBuilder: _buildNotificationsList,
        setOverlay: (entry) => _notificationsOverlay = entry,
        removeOtherOverlay: _removeMessagesOverlay,
      );
      widget.onNotificationsOpened?.call();
    } else {
      _removeNotificationsOverlay();
    }
  }

  void _removeMessagesOverlay() {
    _messagesOverlay?.remove();
    _messagesOverlay = null;
  }

  void _removeNotificationsOverlay() {
    _notificationsOverlay?.remove();
    _notificationsOverlay = null;
  }

  void _showListOverlay({
    required GlobalKey key,
    required String title,
    required IconData icon,
    required double itemsHeight,
    required WidgetBuilder contentBuilder,
    required void Function(OverlayEntry) setOverlay,
    required VoidCallback removeOtherOverlay,
  }) {
    removeOtherOverlay();

    if (key.currentContext == null) return;

    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final Size iconSize = renderBox.size;
    final Offset iconPosition = renderBox.localToGlobal(Offset.zero);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double safeMargin = 8.0;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    double overlayMaxWidth = min(360.0, screenWidth - (safeMargin * 2));
    double overlayWidth = min(340.0, overlayMaxWidth);

    double estimatedHeaderFooter = 120.0;
    double overlayDesiredHeight = min(440.0, itemsHeight + estimatedHeaderFooter);

    double maxAvailableHeight = screenHeight - topPadding - bottomPadding - (safeMargin * 2);
    double overlayHeight = min(overlayDesiredHeight, maxAvailableHeight);

    double availableBelow = screenHeight - (iconPosition.dy + iconSize.height) - bottomPadding - safeMargin;
    double availableAbove = iconPosition.dy - topPadding - safeMargin;

    bool placeAbove = false;

    if (availableBelow >= overlayHeight) {
      placeAbove = false;
    } else if (availableAbove >= overlayHeight) {
      placeAbove = true;
    } else {
      placeAbove = availableAbove > availableBelow;
      overlayHeight = max(min(overlayHeight, max(availableBelow, availableAbove)), 120.0);
      overlayHeight = min(overlayHeight, maxAvailableHeight);
    }

    double availableRight = screenWidth - (iconPosition.dx + iconSize.width) - safeMargin;
    double availableLeft = iconPosition.dx - safeMargin;

    double? leftPos;
    double? rightPos;

    if (availableRight >= overlayWidth) {
      rightPos = screenWidth - (iconPosition.dx + iconSize.width) + safeMargin;
      leftPos = null;
    } else if (availableLeft >= overlayWidth) {
      leftPos = iconPosition.dx - safeMargin;
      rightPos = null;
    } else {
      leftPos = (iconPosition.dx + iconSize.width / 2) - (overlayWidth / 2);
      leftPos = leftPos.clamp(safeMargin, screenWidth - overlayWidth - safeMargin);
      rightPos = null;
    }

    double topOffset = 0.0;
    if (!placeAbove) {
      topOffset = iconPosition.dy + iconSize.height + 8.0;
      final double maxTop = screenHeight - overlayHeight - bottomPadding - safeMargin;
      topOffset = min(topOffset, maxTop);
      if (topOffset + overlayHeight + bottomPadding + safeMargin > screenHeight) {
        placeAbove = true;
      }
    }
    if (placeAbove) {
      topOffset = iconPosition.dy - overlayHeight - 8.0;
      final double minTop = topPadding + safeMargin;
      topOffset = max(topOffset, minTop);
    }

    topOffset = topOffset.clamp(topPadding + safeMargin, max(0.0, screenHeight - overlayHeight - bottomPadding - safeMargin));

    final overlayEntry = OverlayEntry(builder: (context) {
      final double contentHeight = max(80.0, overlayHeight - estimatedHeaderFooter);
      return GestureDetector(
        onTap: () {
          _removeMessagesOverlay();
          _removeNotificationsOverlay();
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              top: topOffset,
              left: leftPos,
              right: rightPos,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: overlayWidth,
                  constraints: BoxConstraints(
                    maxHeight: overlayHeight,
                    minWidth: 200,
                    maxWidth: overlayMaxWidth,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade50,
                        Colors.blue.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(icon, color: Colors.deepPurple, size: 24),
                            const SizedBox(width: 12),
                            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      SizedBox(
                        height: contentHeight,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: contentBuilder(context),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.history_rounded),
                              label: Text(title.contains('Message') ? 'View Message History' : 'View Notifications'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                if (title.contains('Message')) {
                                  widget.onViewMessageHistory?.call();
                                  _removeMessagesOverlay();
                                } else {
                                  widget.onViewNotificationHistory?.call();
                                  _removeNotificationsOverlay();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    setOverlay(overlayEntry);
    Overlay.of(context)?.insert(overlayEntry);
  }

  Widget _buildMessagesList(BuildContext context) {
    final list = _messages;
    if (list.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('No messages'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final message = list[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              message.clientName.isNotEmpty ? message.clientName[0] : '?',
              style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(message.clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            message.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_timeAgo(message.timestamp)),
              if (!message.isRead)
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle)),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () {
            setState(() => message.isRead = true);
            _removeMessagesOverlay();
          },
        );
      },
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    final list = _notifications;
    if (list.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('No notifications'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final n = list[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.notification_important_rounded, color: Colors.blue.shade800),
          ),
          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            n.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_timeAgo(n.timestamp)),
              if (!n.isRead)
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
            ],
          ),
          onTap: () {
            setState(() => n.isRead = true);
            _removeNotificationsOverlay();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool notificationsVisible = widget.showNotifications || widget.side == AppSide.client || widget.side == AppSide.marketer;
    final bool messagesVisible = widget.showMessages || widget.side == AppSide.client || widget.side == AppSide.admin;

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          if (widget.onMenuToggle != null)
            IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => widget.onMenuToggle?.call(widget.side)),
          const SizedBox(width: 8),
          Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
      backgroundColor: Colors.deepPurple.shade800,
      elevation: 4,
      actions: [
        if (notificationsVisible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -5, end: -5),
              badgeStyle: const badges.BadgeStyle(badgeColor: Colors.redAccent, padding: EdgeInsets.all(6)),
              showBadge: _unreadNotificationsCount > 0,
              badgeContent: Text('$_unreadNotificationsCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
              child: Container(key: _notifIconKey, child: IconButton(icon: const Icon(Icons.notifications_rounded, size: 26), color: Colors.white, onPressed: _toggleNotifications)),
            ),
          ),
        if (messagesVisible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -5, end: -5),
              badgeStyle: const badges.BadgeStyle(badgeColor: Colors.redAccent, padding: EdgeInsets.all(6)),
              showBadge: _unreadMessagesCount > 0,
              badgeContent: Text('$_unreadMessagesCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
              child: Container(
                key: _messageIconKey,
                child: IconButton(
                  icon: const Icon(Icons.message, size: 26),
                  color: Colors.white,
                  onPressed: () {
                    // Prefer callbacks so parent can manage auth/context.
                    if (widget.side == AppSide.client) {
                      if (widget.onMessagesOpened != null) {
                        widget.onMessagesOpened!.call();
                        return;
                      }

                      final args = ModalRoute.of(context)?.settings.arguments;
                      Navigator.of(context).pushNamed('/client-chat-admin', arguments: args);
                    } else if (widget.side == AppSide.admin) {
                      if (widget.onViewMessageHistory != null) {
                        widget.onViewMessageHistory!.call();
                        return;
                      }
                      final args = ModalRoute.of(context)?.settings.arguments;
                      Navigator.of(context).pushNamed('/messages', arguments: args);
                    } else {
                      if (widget.onViewMessageHistory != null) {
                        widget.onViewMessageHistory!.call();
                        return;
                      }
                      final args = ModalRoute.of(context)?.settings.arguments;
                      Navigator.of(context).pushNamed('/messages', arguments: args);
                    }
                  },
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: widget.onCompanyLogoTap,
            child: widget.companyLogo ??
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
                    image: const DecorationImage(image: AssetImage('assets/logo.png'), fit: BoxFit.cover),
                  ),
                ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 365) return '${(duration.inDays / 365).floor()}y ago';
    if (duration.inDays > 30) return '${(duration.inDays / 30).floor()}mo ago';
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }
}

/// Message model
class Message {
  final String clientName;
  final String message;
  final DateTime timestamp;
  bool isRead;
  Message({required this.clientName, required this.message, required this.timestamp, this.isRead = false});
}

/// Notification model
class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  NotificationItem({required this.title, required this.body, required this.timestamp, this.isRead = false});
}



// import 'dart:math';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:badges/badges.dart' as badges;
// import 'package:real_estate_app/shared/app_side.dart';
// import 'package:real_estate_app/core/api_service.dart';

// class SharedHeader extends StatefulWidget implements PreferredSizeWidget {
//   final String title;
//   final AppSide side;
//   final ValueChanged<AppSide>? onMenuToggle;

//   /// NEW: require token (same pattern as ClientProfile)
//   final String token;

//   final bool showNotifications;
//   final bool showMessages;

//   final List<Message> messages;
//   final List<NotificationItem> notifications;

//   final Widget? companyLogo;
//   final VoidCallback? onCompanyLogoTap;

//   final VoidCallback? onMessagesOpened;
//   final VoidCallback? onNotificationsOpened;
//   final VoidCallback? onViewMessageHistory;
//   final VoidCallback? onViewNotificationHistory;

//   const SharedHeader({
//     Key? key,
//     required this.title,
//     required this.side,
//     required this.token,
//     this.onMenuToggle,
//     this.showNotifications = false,
//     this.showMessages = false,
//     this.messages = const <Message>[],
//     this.notifications = const <NotificationItem>[],
//     this.companyLogo,
//     this.onCompanyLogoTap,
//     this.onMessagesOpened,
//     this.onNotificationsOpened,
//     this.onViewMessageHistory,
//     this.onViewNotificationHistory,
//   }) : super(key: key);

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   @override
//   State<SharedHeader> createState() => _SharedHeaderState();
// }

// class _SharedHeaderState extends State<SharedHeader> {
//   OverlayEntry? _messagesOverlay;
//   OverlayEntry? _notificationsOverlay;

//   final GlobalKey _messageIconKey = GlobalKey();
//   final GlobalKey _notifIconKey = GlobalKey();

//   // final List<NotificationItem> _mockNotifications = [
//   //   NotificationItem(
//   //     title: 'Payment Received',
//   //     body: 'Payment for plot B-12 has been confirmed.',
//   //     timestamp: DateTime.now().subtract(const Duration(minutes: 36)),
//   //     isRead: false,
//   //   ),
//   //   NotificationItem(
//   //     title: 'New Property Added',
//   //     body: 'Starlight II Estate - 6 new plots available.',
//   //     timestamp: DateTime.now().subtract(const Duration(hours: 4)),
//   //     isRead: false,
//   //   ),
//   //   NotificationItem(
//   //     title: 'System Notice',
//   //     body: 'Maintenance scheduled for Aug 20, 2:00 AM.',
//   //     timestamp: DateTime.now().subtract(const Duration(days: 2)),
//   //     isRead: false,
//   //   ),
//   // ];

//   List<NotificationItem> get _notifications {
//     // For client/marketer: prefer fetched notifications (may be empty list)
//     if ((widget.side == AppSide.client || widget.side == AppSide.marketer) && _fetchedNotifications != null) {
//       return _fetchedNotifications!;
//     }
//     // If parent provided notifications explicitly, use them
//     if (widget.notifications.isNotEmpty) return widget.notifications;
//     // Otherwise return an empty list (no mock data)
//     return <NotificationItem>[];
//   }


//   List<NotificationItem>? _fetchedNotifications;

//   @override
//   void initState() {
//     super.initState();
//     _initializeNotificationsIfNeeded();
//   }

//   Future<void> _initializeNotificationsIfNeeded() async {
//     // Only fetch for client or marketer sides (per your instruction).
//     if (!(widget.side == AppSide.client || widget.side == AppSide.marketer)) return;

//     final token = widget.token;
//     if (token.trim().isEmpty) {
//       if (kDebugMode) print('SharedHeader: token is empty, using fallback notifications.');
//       return;
//     }

//     List<NotificationItem> resolved = [];

//     // Helper parser: converts a raw list of maps to NotificationItem list
//     List<NotificationItem> _parseNotificationList(List raw) {
//       return raw.map<NotificationItem>((e) {
//         if (e is Map<String, dynamic>) {
//           final String title = (e['title'] ?? '') as String;
//           final String body = (e['message'] ?? '') as String;
//           DateTime ts;
//           try {
//             ts = e.containsKey('created_at') && e['created_at'] != null
//                 ? DateTime.parse(e['created_at'].toString())
//                 : DateTime.now();
//           } catch (_) {
//             ts = DateTime.now();
//           }
//           final bool read = e['read'] == true;
//           final int? userNotificationId = e['id'] is int ? e['id'] as int : null;
//           final int? notificationId = e['notification_id'] is int ? e['notification_id'] as int : null;
//           return NotificationItem(
//             title: title,
//             body: body,
//             timestamp: ts,
//             isRead: read,
//             id: userNotificationId,
//             notificationId: notificationId,
//           );
//         }
//         return NotificationItem(title: '', body: '', timestamp: DateTime.now());
//       }).toList();
//     }

//     // 1) Try header-data preview endpoint (cheaper)
//     try {
//       final headerData = await ApiService().getHeaderData(token: token);
//       if (kDebugMode) print('SharedHeader: headerData fetched keys=${headerData.keys}');

//       if (headerData.containsKey('unread_notifications') && headerData['unread_notifications'] is List) {
//         final raw = headerData['unread_notifications'] as List;
//         resolved = _parseNotificationList(raw);
//         if (kDebugMode) print('SharedHeader: parsed ${resolved.length} unread_notifications from header-data.');
//       } else {
//         if (kDebugMode) print('SharedHeader: headerData did not include unread_notifications or it was not a List.');
//       }
//     } catch (err, st) {
//       if (kDebugMode) print('SharedHeader: getHeaderData failed: $err\n$st');
//       // continue to fallback below
//     }

//     // 2) If headerData didn't give anything, try the full notifications endpoint
//     if (resolved.isEmpty) {
//       try {
//         final full = await ApiService().getNotifications(token: token);
//         if (kDebugMode) print('SharedHeader: getNotifications returned ${full.length} items');
//         if (full.isNotEmpty) {
//           resolved = _parseNotificationList(full);
//         } else {
//           // Intentionally set resolved to empty list to avoid using the mock.
//           resolved = <NotificationItem>[];
//         }
//       } catch (err, st) {
//         if (kDebugMode) print('SharedHeader: getNotifications failed: $err\n$st');
//         // Ensure we set resolved to an empty list (do not fall back to mock silently)
//         resolved = <NotificationItem>[];
//       }
//     }

//     // 3) Update state once (even if list is empty)
//     if (mounted) {
//       setState(() {
//         _fetchedNotifications = resolved;
//       });
//     }
//   }


  
//   List<Message> get _messages => widget.messages;

//   // List<NotificationItem> get _notifications {
//   //   if ((widget.side == AppSide.client || widget.side == AppSide.marketer) && _fetchedNotifications != null) {
//   //     return _fetchedNotifications!;
//   //   }
//   //   return widget.notifications.isEmpty ? _mockNotifications : widget.notifications;
//   // }

//   int get _unreadMessagesCount => _messages.where((m) => !m.isRead).length;
//   int get _unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

//   @override
//   void dispose() {
//     _removeMessagesOverlay();
//     _removeNotificationsOverlay();
//     super.dispose();
//   }

//   void _toggleMessages() {
//     if (_messagesOverlay == null) {
//       _showListOverlay(
//         key: _messageIconKey,
//         title: 'Unread Messages',
//         icon: Icons.message,
//         itemsHeight: 220,
//         contentBuilder: _buildMessagesList,
//         setOverlay: (entry) => _messagesOverlay = entry,
//         removeOtherOverlay: _removeNotificationsOverlay,
//       );
//       widget.onMessagesOpened?.call();
//     } else {
//       _removeMessagesOverlay();
//     }
//   }

//   void _toggleNotifications() {
//     if (_notificationsOverlay == null) {
//       _showListOverlay(
//         key: _notifIconKey,
//         title: 'Notifications',
//         icon: Icons.notifications_rounded,
//         itemsHeight: 240,
//         contentBuilder: _buildNotificationsList,
//         setOverlay: (entry) => _notificationsOverlay = entry,
//         removeOtherOverlay: _removeMessagesOverlay,
//       );
//       widget.onNotificationsOpened?.call();
//     } else {
//       _removeNotificationsOverlay();
//     }
//   }

//   void _removeMessagesOverlay() {
//     _messagesOverlay?.remove();
//     _messagesOverlay = null;
//   }

//   void _removeNotificationsOverlay() {
//     _notificationsOverlay?.remove();
//     _notificationsOverlay = null;
//   }

//   void _showListOverlay({
//     required GlobalKey key,
//     required String title,
//     required IconData icon,
//     required double itemsHeight,
//     required WidgetBuilder contentBuilder,
//     required void Function(OverlayEntry) setOverlay,
//     required VoidCallback removeOtherOverlay,
//   }) {
//     removeOtherOverlay();

//     if (key.currentContext == null) return;

//     final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
//     final Size iconSize = renderBox.size;
//     final Offset iconPosition = renderBox.localToGlobal(Offset.zero);

//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double screenHeight = MediaQuery.of(context).size.height;
//     final double safeMargin = 8.0;
//     final double topPadding = MediaQuery.of(context).padding.top;
//     final double bottomPadding = MediaQuery.of(context).padding.bottom;

//     double overlayMaxWidth = min(360.0, screenWidth - (safeMargin * 2));
//     double overlayWidth = min(340.0, overlayMaxWidth);

//     double estimatedHeaderFooter = 120.0;
//     double overlayDesiredHeight = min(440.0, itemsHeight + estimatedHeaderFooter);

//     double maxAvailableHeight = screenHeight - topPadding - bottomPadding - (safeMargin * 2);
//     double overlayHeight = min(overlayDesiredHeight, maxAvailableHeight);

//     double availableBelow = screenHeight - (iconPosition.dy + iconSize.height) - bottomPadding - safeMargin;
//     double availableAbove = iconPosition.dy - topPadding - safeMargin;

//     bool placeAbove = false;

//     if (availableBelow >= overlayHeight) {
//       placeAbove = false;
//     } else if (availableAbove >= overlayHeight) {
//       placeAbove = true;
//     } else {
//       placeAbove = availableAbove > availableBelow;
//       overlayHeight = max(min(overlayHeight, max(availableBelow, availableAbove)), 120.0);
//       overlayHeight = min(overlayHeight, maxAvailableHeight);
//     }

//     double availableRight = screenWidth - (iconPosition.dx + iconSize.width) - safeMargin;
//     double availableLeft = iconPosition.dx - safeMargin;

//     double? leftPos;
//     double? rightPos;

//     if (availableRight >= overlayWidth) {
//       rightPos = screenWidth - (iconPosition.dx + iconSize.width) + safeMargin;
//       leftPos = null;
//     } else if (availableLeft >= overlayWidth) {
//       leftPos = iconPosition.dx - safeMargin;
//       rightPos = null;
//     } else {
//       leftPos = (iconPosition.dx + iconSize.width / 2) - (overlayWidth / 2);
//       leftPos = leftPos.clamp(safeMargin, screenWidth - overlayWidth - safeMargin);
//       rightPos = null;
//     }

//     double topOffset = 0.0;
//     if (!placeAbove) {
//       topOffset = iconPosition.dy + iconSize.height + 8.0;
//       final double maxTop = screenHeight - overlayHeight - bottomPadding - safeMargin;
//       topOffset = min(topOffset, maxTop);
//       if (topOffset + overlayHeight + bottomPadding + safeMargin > screenHeight) {
//         placeAbove = true;
//       }
//     }
//     if (placeAbove) {
//       topOffset = iconPosition.dy - overlayHeight - 8.0;
//       final double minTop = topPadding + safeMargin;
//       topOffset = max(topOffset, minTop);
//     }

//     topOffset = topOffset.clamp(topPadding + safeMargin, max(0.0, screenHeight - overlayHeight - bottomPadding - safeMargin));

//     final overlayEntry = OverlayEntry(builder: (context) {
//       final double contentHeight = max(80.0, overlayHeight - estimatedHeaderFooter);
//       return GestureDetector(
//         onTap: () {
//           _removeMessagesOverlay();
//           _removeNotificationsOverlay();
//         },
//         behavior: HitTestBehavior.translucent,
//         child: Stack(
//           children: [
//             Positioned(
//               top: topOffset,
//               left: leftPos,
//               right: rightPos,
//               child: Material(
//                 elevation: 10,
//                 borderRadius: BorderRadius.circular(16),
//                 child: Container(
//                   width: overlayWidth,
//                   constraints: BoxConstraints(
//                     maxHeight: overlayHeight,
//                     minWidth: 200,
//                     maxWidth: overlayMaxWidth,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         Colors.deepPurple.shade50,
//                         Colors.blue.shade50,
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.grey.shade200, width: 1),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Row(
//                           children: [
//                             Icon(icon, color: Colors.deepPurple, size: 24),
//                             const SizedBox(width: 12),
//                             Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//                           ],
//                         ),
//                       ),
//                       const Divider(height: 1, thickness: 1),
//                       SizedBox(
//                         height: contentHeight,
//                         child: ClipRRect(
//                           borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
//                           child: contentBuilder(context),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             TextButton.icon(
//                               icon: const Icon(Icons.history_rounded),
//                               label: Text(title.contains('Message') ? 'View Message History' : 'View Notifications'),
//                               style: TextButton.styleFrom(
//                                 foregroundColor: Colors.deepPurple,
//                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                               ),
//                               onPressed: () {
//                                 if (title.contains('Message')) {
//                                   widget.onViewMessageHistory?.call();
//                                   _removeMessagesOverlay();
//                                 } else {
//                                   widget.onViewNotificationHistory?.call();
//                                   _removeNotificationsOverlay();
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });

//     setOverlay(overlayEntry);
//     Overlay.of(context)?.insert(overlayEntry);
//   }

//   Widget _buildMessagesList(BuildContext context) {
//     final list = _messages;
//     if (list.isEmpty) {
//       return const Padding(padding: EdgeInsets.all(16), child: Text('No messages'));
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.all(8),
//       shrinkWrap: true,
//       itemCount: list.length,
//       separatorBuilder: (_, __) => const Divider(height: 16),
//       itemBuilder: (context, index) {
//         final message = list[index];
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundColor: Colors.deepPurple.shade100,
//             child: Text(
//               message.clientName.isNotEmpty ? message.clientName[0] : '?',
//               style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
//             ),
//           ),
//           title: Text(message.clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
//           subtitle: Text(
//             message.message,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//           trailing: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(_timeAgo(message.timestamp)),
//               if (!message.isRead)
//                 Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle)),
//             ],
//           ),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           onTap: () {
//             setState(() => message.isRead = true);
//             _removeMessagesOverlay();
//           },
//         );
//       },
//     );
//   }

//   Widget _buildNotificationsList(BuildContext context) {
//     final list = _notifications;
//     if (list.isEmpty) {
//       return const Padding(padding: EdgeInsets.all(16), child: Text('No notifications'));
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.all(8),
//       shrinkWrap: true,
//       itemCount: list.length,
//       separatorBuilder: (_, __) => const Divider(height: 16),
//       itemBuilder: (context, index) {
//         final n = list[index];
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundColor: Colors.blue.shade100,
//             child: Icon(Icons.notification_important_rounded, color: Colors.blue.shade800),
//           ),
//           title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
//           subtitle: Text(
//             n.body,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//           trailing: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(_timeAgo(n.timestamp)),
//               if (!n.isRead)
//                 Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
//             ],
//           ),
//           onTap: () async {
//             // Mark locally for immediate UX
//             setState(() => n.isRead = true);
//             _removeNotificationsOverlay();

//             // Backend: attempt to mark read using ApiService (same pattern as ClientProfile)
//             final token = widget.token;
//             if (token.trim().isEmpty) {
//               if (kDebugMode) print('SharedHeader: token empty, cannot mark backend read.');
//               return;
//             }

//             try {
//               // If backend returned user-notification id, call markNotificationRead directly
//               if (n.id != null) {
//                 final ok = await ApiService().markNotificationRead(token: token, userNotificationId: n.id!);
//                 if (!ok && kDebugMode) print('SharedHeader: markNotificationRead returned false for id ${n.id}');
//                 return;
//               }

//               // Else attempt to resolve via full notifications (best-effort)
//               final full = await ApiService().getNotifications(token: token);
//               int? resolvedId;
//               for (final item in full) {
//                 if (item is Map<String, dynamic>) {
//                   final int? notifId = item['notification_id'] is int ? item['notification_id'] as int : (item['notification_id'] is String ? int.tryParse(item['notification_id'].toString()) : null);
//                   final String title = (item['title'] ?? '') as String;
//                   final String body = (item['message'] ?? '') as String;
//                   final String? createdAtStr = item['created_at']?.toString();
//                   DateTime? createdAt;
//                   if (createdAtStr != null) {
//                     try {
//                       createdAt = DateTime.parse(createdAtStr);
//                     } catch (_) {}
//                   }

//                   final bool matchByNotifId = (n.notificationId != null && notifId != null && n.notificationId == notifId);
//                   final bool matchByContent = (n.title == title && n.body == body && createdAt != null && (createdAt.difference(n.timestamp).inSeconds).abs() < 5);

//                   if (matchByNotifId || matchByContent) {
//                     if (item.containsKey('id') && item['id'] is int) {
//                       resolvedId = item['id'] as int;
//                       break;
//                     }
//                   }
//                 }
//               }

//               if (resolvedId != null) {
//                 final ok = await ApiService().markNotificationRead(token: token, userNotificationId: resolvedId);
//                 if (!ok && kDebugMode) print('SharedHeader: resolved id but markNotificationRead returned false for $resolvedId');
//                 return;
//               }

//               if (kDebugMode) print('SharedHeader: could not resolve userNotificationId for: ${n.title}');
//             } catch (err, st) {
//               if (kDebugMode) print('SharedHeader: error marking notification read: $err\n$st');
//             }
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool notificationsVisible = widget.showNotifications || widget.side == AppSide.client || widget.side == AppSide.marketer;
//     final bool messagesVisible = widget.showMessages || widget.side == AppSide.client || widget.side == AppSide.admin;

//     return AppBar(
//       automaticallyImplyLeading: false,
//       titleSpacing: 0,
//       title: Row(
//         children: [
//           if (widget.onMenuToggle != null)
//             IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => widget.onMenuToggle?.call(widget.side)),
//           const SizedBox(width: 8),
//           Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
//         ],
//       ),
//       backgroundColor: Colors.deepPurple.shade800,
//       elevation: 4,
//       actions: [
//         if (notificationsVisible)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: badges.Badge(
//               position: badges.BadgePosition.topEnd(top: -5, end: -5),
//               badgeStyle: const badges.BadgeStyle(badgeColor: Colors.redAccent, padding: EdgeInsets.all(6)),
//               showBadge: _unreadNotificationsCount > 0,
//               badgeContent: Text('$_unreadNotificationsCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
//               child: Container(key: _notifIconKey, child: IconButton(icon: const Icon(Icons.notifications_rounded, size: 26), color: Colors.white, onPressed: _toggleNotifications)),
//             ),
//           ),
//         if (messagesVisible)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: badges.Badge(
//               position: badges.BadgePosition.topEnd(top: -5, end: -5),
//               badgeStyle: const badges.BadgeStyle(badgeColor: Colors.redAccent, padding: EdgeInsets.all(6)),
//               showBadge: _unreadMessagesCount > 0,
//               badgeContent: Text('$_unreadMessagesCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
//               child: Container(
//                 key: _messageIconKey,
//                 child: IconButton(
//                   icon: const Icon(Icons.message, size: 26),
//                   color: Colors.white,
//                   onPressed: () {
//                     if (widget.side == AppSide.client) {
//                       if (widget.onMessagesOpened != null) {
//                         widget.onMessagesOpened!.call();
//                         return;
//                       }
//                       final args = ModalRoute.of(context)?.settings.arguments;
//                       Navigator.of(context).pushNamed('/client-chat-admin', arguments: args);
//                     } else if (widget.side == AppSide.admin) {
//                       if (widget.onViewMessageHistory != null) {
//                         widget.onViewMessageHistory!.call();
//                         return;
//                       }
//                       final args = ModalRoute.of(context)?.settings.arguments;
//                       Navigator.of(context).pushNamed('/messages', arguments: args);
//                     } else {
//                       if (widget.onViewMessageHistory != null) {
//                         widget.onViewMessageHistory!.call();
//                         return;
//                       }
//                       final args = ModalRoute.of(context)?.settings.arguments;
//                       Navigator.of(context).pushNamed('/messages', arguments: args);
//                     }
//                   },
//                 ),
//               ),
//             ),
//           ),
//         Padding(
//           padding: const EdgeInsets.only(right: 12.0),
//           child: GestureDetector(
//             onTap: widget.onCompanyLogoTap,
//             child: widget.companyLogo ??
//                 Container(
//                   width: 38,
//                   height: 38,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
//                     image: const DecorationImage(image: AssetImage('assets/logo.png'), fit: BoxFit.cover),
//                   ),
//                 ),
//           ),
//         ),
//         const SizedBox(width: 4),
//       ],
//     );
//   }

//   String _timeAgo(DateTime date) {
//     final duration = DateTime.now().difference(date);
//     if (duration.inDays > 365) return '${(duration.inDays / 365).floor()}y ago';
//     if (duration.inDays > 30) return '${(duration.inDays / 30).floor()}mo ago';
//     if (duration.inDays > 0) return '${duration.inDays}d ago';
//     if (duration.inHours > 0) return '${duration.inHours}h ago';
//     if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
//     return 'Just now';
//   }
// }

// /// Message model (unchanged)
// class Message {
//   final String clientName;
//   final String message;
//   final DateTime timestamp;
//   bool isRead;
//   Message({required this.clientName, required this.message, required this.timestamp, this.isRead = false});
// }

// /// Notification model (extended: optional backend ids)
// class NotificationItem {
//   final String title;
//   final String body;
//   final DateTime timestamp;
//   bool isRead;
//   final int? id;
//   final int? notificationId;

//   NotificationItem({
//     required this.title,
//     required this.body,
//     required this.timestamp,
//     this.isRead = false,
//     this.id,
//     this.notificationId,
//   });
// }
