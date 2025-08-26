import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:real_estate_app/shared/app_side.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:real_estate_app/shared/app_layout.dart';
import 'package:real_estate_app/client/client_bottom_nav.dart';

class ClientChatAdmin extends StatefulWidget {
  final String? token;

  const ClientChatAdmin({super.key, this.token});

  @override
  _ClientChatAdminState createState() => _ClientChatAdminState();
}

class _ClientChatAdminState extends State<ClientChatAdmin> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _sendMessage({String? text, File? file, String? fileType}) {
    if ((text == null || text.trim().isEmpty) && file == null) return;

    setState(() {
      _messages.add({
        "text": text,
        "file": file,
        "fileType": fileType,
        "isMe": true,
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      });
      _isTyping = false;
    });

    _messageController.clear();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String extension = result.files.single.extension?.toLowerCase() ?? "";

      String fileType = "file";
      if (["jpg", "jpeg", "png"].contains(extension)) fileType = "image";
      if (["mp4", "mov", "avi"].contains(extension)) fileType = "video";
      if (["mp3", "wav", "m4a"].contains(extension)) fileType = "audio";
      if (["pdf", "doc", "docx"].contains(extension)) fileType = "document";

      _sendMessage(file: file, fileType: fileType);
    }
  }

  Future<void> _recordVoiceNote() async {
    // Dummy voice note (Replace this with actual recording logic)
    final fakePath = 'assets/sample_audio.mp3';
    if (await File(fakePath).exists()) {
      File fakeAudioFile = File(fakePath);
      _sendMessage(file: fakeAudioFile, fileType: "audio");
    } else {
      // you could open recorder UI here; for now show a toast/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording not implemented in this demo.')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'Chat with Admin',
      token: widget.token ?? '',
      side: AppSide.client,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        bottomNavigationBar: ClientBottomNav(
          currentIndex: 2,
          token: widget.token,
          chatBadge: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: const [
                    CircleAvatar(backgroundImage: AssetImage('assets/logo.png')),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Admin", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text("Online", style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Chat body
              Expanded(child: _buildChatBody()),

              // Message input
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  /// **🔹 Chat Messages Body**
  Widget _buildChatBody() {
    // Show placeholder when no messages
    if (_messages.isEmpty) {
      return Center(
        child: Text('No messages yet — start the conversation!',
            style: TextStyle(color: Colors.grey[600])),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildMessageBubble(
          text: message['text'] as String?,
          file: message['file'] as File?,
          fileType: message['fileType'] as String?,
          isMe: message['isMe'] as bool,
          time: message['time'] as String,
        );
      },
    );
  }

  /// **🔹 Chat Message Bubble (With File Previews)**
  Widget _buildMessageBubble({
    String? text,
    File? file,
    String? fileType,
    required bool isMe,
    required String time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file != null && fileType == "image")
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 200)),
            if (file != null && fileType == "video") VideoPlayerWidget(videoFile: file),
            if (file != null && fileType == "audio")
              AudioPlayerWidget(audioFile: file, audioPlayer: _audioPlayer),
            if (file != null && fileType == "document")
              Text("📄 ${file.path.split('/').last}", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
            if (text != null && text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 Message Input Bar (Like WhatsApp)**
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)]),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.emoji_emotions, color: Colors.blueAccent), onPressed: () {}),
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.blueAccent), onPressed: _pickFile),
          IconButton(icon: const Icon(Icons.mic, color: Colors.redAccent), onPressed: _recordVoiceNote),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
              onChanged: (text) => setState(() => _isTyping = text.isNotEmpty),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: _isTyping ? Colors.blueAccent : Colors.grey),
            onPressed: _isTyping ? () => _sendMessage(text: _messageController.text) : null,
          ),
        ],
      ),
    );
  }
}

/// **🔹 Video Player Widget**
class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;
  const VideoPlayerWidget({super.key, required this.videoFile});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
        : const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator()),
          );
  }
}

/// **🔹 Audio Player Widget**
class AudioPlayerWidget extends StatefulWidget {
  final File audioFile;
  final AudioPlayer audioPlayer;
  const AudioPlayerWidget({super.key, required this.audioFile, required this.audioPlayer});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    widget.audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    widget.audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
  }

  @override
  void dispose() {
    // don't dispose the shared audioPlayer here; the parent disposes it.
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.play(DeviceFileSource(widget.audioFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow), onPressed: _togglePlay),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: _duration.inMilliseconds == 0 ? 0.0 : _position.inMilliseconds / _duration.inMilliseconds),
              const SizedBox(height: 4),
              Text('${_position.toString().split('.').first} / ${_duration.toString().split('.').first}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
