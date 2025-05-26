// import 'package:flutter/material.dart';
// import 'package:badges/badges.dart' as badges;
// import 'package:intl/intl.dart';
// import 'package:real_estate_app/admin/admin_layout.dart';

// class AdminChatListScreen extends StatelessWidget {
//   final String token;
//   const AdminChatListScreen({required this.token, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AdminLayout(
//       pageTitle: 'Client Chats',
//       token: token, // Use the token passed in the constructor
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Client Chats'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.search),
//               onPressed: () {
//                 // Implement search logic here
//               },
//             ),
//           ],
//         ),
//         body: _ChatList(),
//       ),
//     );
//   }
// }

// class _ChatList extends StatefulWidget {
//   @override
//   State<_ChatList> createState() => _ChatListState();
// }

// class _ChatListState extends State<_ChatList> {
//   final List<Chat> _chats = [
//     Chat(
//       id: '1',
//       clientName: 'Victor Godwin',
//       lastMessage: 'Hello, I wanted to follow up on my plot allocation...',
//       timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
//       unreadCount: 2,
//       avatarUrl: '',
//     ),
//     Chat(
//       id: '2',
//       clientName: 'Rose Shelthon',
//       lastMessage: 'Thank you for the update!',
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//       unreadCount: 0,
//       avatarUrl: '',
//     ),
//     Chat(
//       id: '3',
//       clientName: 'David Goja Shelthon',
//       lastMessage: 'Thank you for the update!',
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//       unreadCount: 0,
//       avatarUrl: '',
//     ),
//     Chat(
//       id: '4',
//       clientName: 'Tinibu Shettima',
//       lastMessage: 'Thank you for the update!',
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//       unreadCount: 0,
//       avatarUrl: '',
//     ),
//     Chat(
//       id: '5',
//       clientName: 'Mac Donald',
//       lastMessage: 'Thank you for the update!',
//       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//       unreadCount: 0,
//       avatarUrl: '',
//     ),
//     // Add more mock chats if needed...
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () async => await _refreshChats(),
//       child: ListView.separated(
//         padding: const EdgeInsets.only(top: 8),
//         itemCount: _chats.isEmpty ? 1 : _chats.length,
//         separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
//         itemBuilder: (context, index) {
//           if (_chats.isEmpty) {
//             return _buildEmptyState();
//           }
//           return _ChatListItem(chat: _chats[index]);
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return SizedBox(
//       height: 300,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
//             const SizedBox(height: 16),
//             Text(
//               'No Active Conversations',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: Colors.grey.shade600,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _refreshChats() async {
//     // Implement your refresh logic here
//     await Future.delayed(const Duration(seconds: 1));
//   }
// }

// class _ChatListItem extends StatelessWidget {
//   final Chat chat;
//   const _ChatListItem({required this.chat});

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       leading: CircleAvatar(
//         radius: 28,
//         backgroundColor: Colors.grey.shade200,
//         child: Icon(Icons.person, color: Colors.grey.shade600),
//       ),
//       title: Row(
//         children: [
//           Text(
//             chat.clientName,
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//           ),
//           if (chat.unreadCount > 0)
//             badges.Badge(
//               position: badges.BadgePosition.topEnd(top: -4, end: -24),
//               badgeContent: Text(
//                 chat.unreadCount.toString(),
//                 style: const TextStyle(color: Colors.white, fontSize: 12),
//               ),
//               badgeStyle: const badges.BadgeStyle(
//                 padding: EdgeInsets.all(6),
//                 badgeColor: Colors.red,
//               ),
//             ),
//         ],
//       ),
//       subtitle: Text(
//         chat.lastMessage,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               color: Colors.grey.shade600,
//             ),
//       ),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Text(
//             DateFormat('HH:mm').format(chat.timestamp),
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: Colors.grey.shade600,
//                 ),
//           ),
//           if (chat.unreadCount > 0)
//             Container(
//               width: 12,
//               height: 12,
//               decoration: const BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//             ),
//         ],
//       ),
//       onTap: () => Navigator.pushNamed(
//         context,
//         '/admin-chat',
//         arguments: chat.id,
//       ),
//     );
//   }
// }

// class Chat {
//   final String id;
//   final String clientName;
//   final String lastMessage;
//   final DateTime timestamp;
//   final int unreadCount;
//   final String avatarUrl;

//   Chat({
//     required this.id,
//     required this.clientName,
//     required this.lastMessage,
//     required this.timestamp,
//     required this.unreadCount,
//     required this.avatarUrl,
//   });
// }


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';
import 'package:real_estate_app/admin/models/admin_chat_model.dart';
import 'package:real_estate_app/admin/admin_layout.dart';
import 'package:real_estate_app/core/api_service.dart';

class AdminChatListScreen extends StatelessWidget {
  final String token;
  const AdminChatListScreen({required this.token, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      pageTitle: 'Client Chats',
      token: token,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Client Chats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
            ),
          ],
        ),
        body: _ChatList(token: token),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Clients'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Search by client name...'),
          onChanged: (value) {
            // Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Execute search
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _ChatList extends StatefulWidget {
  final String token;
  const _ChatList({required this.token});

  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList> {
  final ApiService _api = ApiService();
  List<Chat> _chats = [];
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadChats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final chats = await _api.fetchClientChats(widget.token);
      if (mounted) {
        setState(() {
          _chats = chats;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _error != null 
                ? 'Error loading chats'
                : 'No active conversations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadChats,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: _chats.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildEmptyState(),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, idx) => _ChatListItem(
                chat: _chats[idx],
                token: widget.token,
              ),
            ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Chat chat;
  final String token;
  
  const _ChatListItem({required this.chat, required this.token});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.clientName.isNotEmpty ? chat.clientName : 'Unknown Client',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: chat.unreadCount > 0 
                        ? Theme.of(context).colorScheme.primary 
                        : null,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: chat.unreadCount > 0
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                    : Colors.grey.shade600,
              ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(chat.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          if (chat.unreadCount > 0)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () => Navigator.pushNamed(
        context,
        '/admin-chat',
        arguments: {
          'clientId': chat.id,
          'token': token,
          'clientName': chat.clientName,
        },
      ),
    );
  }
}

