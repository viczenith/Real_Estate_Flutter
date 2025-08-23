import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_app/core/api_service.dart';
import 'package:real_estate_app/shared/app_layout.dart';
import 'package:real_estate_app/client/client_bottom_nav.dart';
import 'package:real_estate_app/shared/header.dart';

class ClientNotification extends StatefulWidget {
  final String token;
  final ApiService api;

  ClientNotification({
    Key? key,
    required this.token,
    ApiService? api,
  }) : api = api ?? ApiService(),
      super(key: key);

  @override
  State<ClientNotification> createState() => _ClientNotificationState();
}

class _ClientNotificationState extends State<ClientNotification> with TickerProviderStateMixin {
  List<Map<String, dynamic>> unread = [];
  List<Map<String, dynamic>> read = [];
  bool loading = true;
  bool error = false;
  String errorMsg = '';
  bool refreshing = false;
  int unreadCount = 0;
  int readCount = 0;

  // For staggered entrance animations
  late final AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadAll();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  // small helper to convert dynamic -> non-nullable int safely
  int _toIntSafe(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? (double.tryParse(v)?.toInt() ?? 0);
    try {
      return int.parse(v.toString());
    } catch (_) {
      return 0;
    }
  }

  // Helper: call api.ensureAbsoluteUrl if available, otherwise return as-is
  String? _ensureAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    try {
      final dynamic maybe = widget.api;
      if (maybe != null && maybe is Object) {
        final mirror = maybe;
        // call ensureAbsoluteUrl if implemented (duck-typing)
        final func = (mirror as dynamic).ensureAbsoluteUrl;
        if (func is Function) {
          return func(url) as String?;
        }
      }
    } catch (_) {
      // ignore: fall back
    }
    return url;
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = false;
      errorMsg = '';
    });

    try {
      final stats = await widget.api.getNotificationStats(token: widget.token);
      final int gotUnread = _toIntSafe(stats['unread']);
      final int gotRead = _toIntSafe(stats['read']);

      final unreadList = await widget.api.getNotifications(token: widget.token, read: false);
      final readList = await widget.api.getNotifications(token: widget.token, read: true);

      final normUnread = _ensureMapList(unreadList);
      final normRead = _ensureMapList(readList);

      // animate in
      _listAnimController.forward(from: 0.0);

      if (!mounted) return;
      setState(() {
        unreadCount = gotUnread;
        readCount = gotRead;
        unread = normUnread;
        read = normRead;
        loading = false;
        refreshing = false;
        error = false;
        errorMsg = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        refreshing = false;
        error = true;
        errorMsg = e.toString();
      });
    }
  }

  // Helper: ensures each entry is a Map<String,dynamic>
  List<Map<String, dynamic>> _ensureMapList(List<dynamic> raw) {
    return raw.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return Map<String, dynamic>.from(e);
      if (e is Map) return Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v)));
      return <String, dynamic>{'id': null};
    }).toList();
  }

  // Safe accessors (local equivalents of the service helpers)
  String titleOf(Map<String, dynamic> u) {
    final n = u['notification'];
    if (n is Map && n['title'] != null) return n['title'].toString();
    return u['title']?.toString() ?? 'Untitled';
  }

  String messageOf(Map<String, dynamic> u) {
    final n = u['notification'];
    if (n is Map && n['message'] != null) return n['message'].toString();
    return u['message']?.toString() ?? '';
  }

  DateTime? createdAtOf(Map<String, dynamic> u) {
    final n = u['notification'];
    final val = (n is Map && n['created_at'] != null) ? n['created_at'] : u['created_at'];
    if (val == null) return null;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  bool readOf(Map<String, dynamic> u) {
    final r = u['read'];
    if (r is bool) return r;
    if (r is num) return r != 0;
    if (r is String) return r.toLowerCase() == 'true';
    return false;
  }

  int idOf(Map<String, dynamic> u) {
    if (u['id'] is int) return u['id'] as int;
    if (u['id'] is String) return int.tryParse(u['id']) ?? 0;
    // fallback try nested notification id if present
    final n = u['notification'];
    if (n is Map && n['id'] is int) return n['id'] as int;
    if (n is Map && n['id'] is String) return int.tryParse(n['id']) ?? 0;
    return 0;
  }

  String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() => refreshing = true);
    await _loadAll();
  }

  Future<void> _markRead(Map<String, dynamic> item, {bool refreshAfter = true}) async {
    final id = idOf(item);
    if (id == 0) return;
    try {
      await widget.api.markNotificationRead(token: widget.token, id: id);
      if (!mounted) return;
      setState(() {
        item['read'] = true;
        unread.removeWhere((m) => idOf(m) == id);
        read.insert(0, item);
        unreadCount = unread.length;
        readCount = read.length;
      });
      // lightweight refresh of counts (non-blocking)
      if (refreshAfter) _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not mark as read: $e')));
    }
  }

  Future<void> _openDetail(Map<String, dynamic> item) async {
    final id = idOf(item);
    if (id == 0) return;
    final detail = await Navigator.of(context).push<Map<String, dynamic>>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => NotificationDetailPage(token: widget.token, api: widget.api, id: id),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );

    if (!mounted) return;
    if (detail != null) {
      setState(() {
        final idx = unread.indexWhere((m) => idOf(m) == id);
        if (idx >= 0) {
          final updated = detail;
          updated['read'] = true;
          unread.removeAt(idx);
          read.insert(0, updated);
        } else {
          final ridx = read.indexWhere((m) => idOf(m) == id);
          if (ridx >= 0) read[ridx] = detail;
        }
        unreadCount = unread.length;
        readCount = read.length;
      });
    }
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
          count: unreadCount,
          label: 'UNREAD',
          icon: Icons.mark_email_unread,
          gradient: LinearGradient(colors: [Color(0xFF2ECC71).withOpacity(.9), Color(0xFF2ECC71).withOpacity(.6)]),
        )),
        SizedBox(width: 12),
        Expanded(
            child: _StatCard(
          count: readCount,
          label: 'READ',
          icon: Icons.mark_email_read,
          gradient: LinearGradient(colors: [Color(0xFF4CAF50).withOpacity(.9), Color(0xFF4CAF50).withOpacity(.6)]),
        )),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index, {bool isUnread = true}) {
    final createdAt = createdAtOf(item);
    final title = titleOf(item);
    final message = messageOf(item);
    final isRead = readOf(item);
    final id = idOf(item);

    final baseColor = isUnread ? Colors.white : Colors.grey.shade50;
    final accent = isUnread ? Colors.blueAccent : Colors.grey;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(
            parent: _listAnimController,
            curve: Interval((index * 0.04).clamp(0.0, 0.8), 1.0, curve: Curves.easeOut)),
      ),
      child: Dismissible(
        key: ValueKey('notif_$id'),
        direction: isRead ? DismissDirection.none : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          color: Colors.green,
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check, color: Colors.white), SizedBox(width: 8), Text('Mark as read', style: TextStyle(color: Colors.white))]),
        ),
        onDismissed: (_) => _markRead(item),
        child: GestureDetector(
          onTap: () => _openDetail(item),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: Offset(0, 6))],
              border: isUnread ? Border(left: BorderSide(color: Colors.greenAccent.shade700, width: 4)) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnread ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                    border: Border.all(color: isUnread ? Colors.green.shade300 : Colors.grey.shade300),
                  ),
                  child: Icon(Icons.notifications, color: isUnread ? Colors.green : Colors.grey.shade700),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row
                      Row(
                        children: [
                          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                          if (isUnread)
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(20)),
                              child: Text('NEW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(createdAt != null ? timeAgo(createdAt) : '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          Row(children: [
                            IconButton(
                              onPressed: isUnread ? () => _markRead(item) : null,
                              icon: Icon(Icons.check_circle_outline, color: isUnread ? Colors.green : Colors.grey),
                              tooltip: 'Mark as read',
                            )
                          ])
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error) {
      final titleStyle = Theme.of(context).textTheme.titleLarge ?? TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Could not load notifications', style: titleStyle),
            SizedBox(height: 8),
            Text(errorMsg, textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent)),
            SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _loadAll, icon: Icon(Icons.refresh), label: Text('Retry')),
          ]),
        ),
      );
    }

    if (unread.isEmpty && read.isEmpty) {
      return _EmptyState(onRefresh: _onRefresh);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildStatsRow(),
        SizedBox(height: 18),
        if (unread.isNotEmpty) ...[
          Text('Unread Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          for (var i = 0; i < unread.length; i++) _buildNotificationCard(unread[i], i, isUnread: true),
          SizedBox(height: 18),
        ],
        if (read.isNotEmpty) ...[
          Text('Read Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          for (var i = 0; i < read.length; i++) _buildNotificationCard(read[i], i + unread.length, isUnread: false),
        ],
        SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'Notifications',
      token: widget.token,
      side: AppSide.client,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          bottomNavigationBar: ClientBottomNav(
            currentIndex: 2, // adjust if your nav uses different indexes
            token: widget.token,
            chatBadge: unreadCount,
          ),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: Text('Notifications', style: TextStyle(letterSpacing: 0.2)),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadAll,
                tooltip: 'Refresh',
              ),
            ],
            backgroundColor: Colors.transparent,
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _buildList(),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _loadAll,
            label: Text('Refresh'),
            icon: Icon(Icons.sync),
            backgroundColor: Colors.deepPurple,
          ),
        ),
      ),
    );
  }
}

// ------------------ Supporting widgets ------------------
// (unchanged; copied from your file with small spacing adjustments)

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({Key? key, required this.count, required this.label, required this.icon, required this.gradient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle baseCountStyle =
        (theme.textTheme.titleLarge ?? theme.textTheme.headlineSmall) ?? TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: Offset(0, 6))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('$count', style: baseCountStyle.copyWith(color: Colors.white)),
          ]),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({Key? key, required this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accent = LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(gradient: accent, borderRadius: BorderRadius.circular(28)),
            child: Center(child: Icon(Icons.notifications_off, size: 72, color: Colors.white.withOpacity(.95))),
          ),
          SizedBox(height: 20),
          Text('No notifications yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('We will notify you when something new arrives.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 16),
          ElevatedButton.icon(onPressed: () => onRefresh(), icon: Icon(Icons.refresh), label: Text('Refresh')),
        ]),
      ),
    );
  }
}

// ------------------ Notification Detail Page ------------------

class NotificationDetailPage extends StatefulWidget {
  final String token;
  final ApiService api;
  final int id;

  const NotificationDetailPage({Key? key, required this.token, required this.api, required this.id}) : super(key: key);

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  Map<String, dynamic>? detail;
  bool loading = true;
  bool error = false;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = false;
      errorMsg = '';
    });

    try {
      final Map<String, dynamic> res = await widget.api.getNotificationDetail(token: widget.token, id: widget.id);
      if (!mounted) return;
      setState(() {
        detail = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = true;
        errorMsg = e.toString();
      });
    }
  }

  String _title() {
    final n = detail?['notification'];
    if (n is Map && n['title'] != null) return n['title'].toString();
    return detail?['title']?.toString() ?? '';
  }

  String _message() {
    final n = detail?['notification'];
    if (n is Map && n['message'] != null) return n['message'].toString();
    return detail?['message']?.toString() ?? '';
  }

  DateTime? _createdAt() {
    final n = detail?['notification'];
    final val = (n is Map && n['created_at'] != null) ? n['created_at'] : detail?['created_at'];
    if (val == null) return null;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Failed to load'), SizedBox(height: 8), Text(errorMsg), ElevatedButton(onPressed: _loadDetail, child: Text('Retry'))]))
              : Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: Offset(0, 8))]),
                      child: Row(children: [
                        Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade50), child: Icon(Icons.notifications, size: 28, color: Colors.blueAccent)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_title(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 6),
                            Text(_createdAt() != null ? DateFormat('MMMM d, y • h:mm a').format(_createdAt()!) : '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ]),
                        ),
                      ]),
                    ),
                    SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text(_message(), style: TextStyle(fontSize: 16, height: 1.6)),
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // pop with detail so parent can update lists
                          Navigator.of(context).pop(detail);
                        },
                        icon: Icon(Icons.arrow_back),
                        label: Text('Back'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await widget.api.markNotificationRead(token: widget.token, id: widget.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked as read')));
                            await _loadDetail();
                            Navigator.of(context).pop(detail);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not mark read: $e')));
                          }
                        },
                        icon: Icon(Icons.check),
                        label: Text('Mark as read'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      ),
                    ])
                  ]),
                ),
    );
  }
}
