// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:real_estate_app/core/api_service.dart';

// class NotificationDetailPage extends StatefulWidget {
//   final String token;
//   final int userNotificationId;
//   const NotificationDetailPage({
//     required this.token,
//     required this.userNotificationId,
//     super.key,
//   });

//   @override
//   _NotificationDetailPageState createState() => _NotificationDetailPageState();
// }

// class _NotificationDetailPageState extends State<NotificationDetailPage> {
//   final ApiService _api = ApiService();
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _userNotification;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     if (!mounted) return;
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     final token = widget.token.trim();
//     if (token.isEmpty) {
//       setState(() {
//         _error = 'Not authenticated.';
//         _loading = false;
//       });
//       return;
//     }

//     try {
//       final data = await _api.getNotificationDetail(
//         token: token,
//         userNotificationId: widget.userNotificationId,
//       );
//       if (!mounted) return;
//       setState(() => _userNotification = Map<String, dynamic>.from(data));
//     } on Exception catch (e) {
//       if (!mounted) return;
//       setState(() => _error = e.toString());
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _error = 'Unexpected error');
//     } finally {
//       if (!mounted) return;
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _markRead() async {
//     if (_userNotification == null) return;
//     final id = _userNotification!['id'] as int? ?? -1;
//     if (id < 0) return;

//     try {
//       await _api.markNotificationRead(token: widget.token, userNotificationId: id);
//       if (!mounted) return;
//       setState(() {
//         _userNotification = {..._userNotification!, 'read': true};
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Marked as read')));
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final gradientA = const Color(0xFF6A11CB);
//     final gradientB = const Color(0xFF2575FC);

//     return Scaffold(
//       backgroundColor: const Color(0xFF0f1724),
//       appBar: AppBar(
//         title: const Text('Notification'),
//         centerTitle: true,
//         backgroundColor: gradientA,
//       ),
//       body: SafeArea(
//         child: _loading
//             ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
//             : _error != null
//                 ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.white70)))
//                 : Padding(
//                     padding: const EdgeInsets.all(18.0),
//                     child: Column(children: [
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(14),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(colors: [gradientA, gradientB]),
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
//                         ),
//                         child: Row(children: [
//                           Container(
//                             width: 56,
//                             height: 56,
//                             decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
//                             child: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                               Text(
//                                 (_userNotification?['notification']?['title'] ?? '-'),
//                                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 (_userNotification?['notification']?['get_notification_type_display'] ?? ''),
//                                 style: const TextStyle(color: Colors.white70),
//                               ),
//                             ]),
//                           ),
//                           IconButton(
//                             onPressed: _markRead,
//                             icon: Icon(
//                               _userNotification?['read'] == true ? Icons.check_circle : Icons.mark_email_read,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ]),
//                       ),
//                       const SizedBox(height: 16),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                             Text(
//                               DateFormat('MMMM d, yyyy • h:mm a').format(
//                                 DateTime.parse((_userNotification?['notification']?['created_at']) ?? DateTime.now().toIso8601String()),
//                               ),
//                               style: const TextStyle(color: Colors.white54),
//                             ),
//                             const SizedBox(height: 12),
//                             Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
//                               child: Text((_userNotification?['notification']?['message'] ?? ''), style: const TextStyle(color: Colors.white70, height: 1.6)),
//                             ),
//                           ]),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Row(children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () => Navigator.pop(context),
//                             icon: const Icon(Icons.arrow_back),
//                             label: const Text('Back to notifications'),
//                             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
//                           ),
//                         ),
//                       ])
//                     ]),
//                   ),
//       ),
//     );
//   }
// }


