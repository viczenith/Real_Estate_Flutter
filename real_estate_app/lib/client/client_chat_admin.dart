import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class ClientChatAdmin extends StatefulWidget {
  const ClientChatAdmin({super.key});

  @override
  _ClientChatAdminState createState() => _ClientChatAdminState();
}

class _ClientChatAdminState extends State<ClientChatAdmin> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  // ignore: unused_field
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _sendMessage({String? text, File? file, String? fileType}) {
    if (text != null && text.trim().isEmpty && file == null) return;

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

    if (result != null) {
      File file = File(result.files.single.path!);
      String extension = result.files.single.extension ?? "";
      
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
    File fakeAudioFile = File('assets/sample_audio.mp3');
    _sendMessage(file: fakeAudioFile, fileType: "audio");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: _buildChatHeader(),
      body: Column(
        children: [
          Expanded(child: _buildChatBody()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// **🔹 Chat Header (Like WhatsApp)**
  AppBar _buildChatHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          CircleAvatar(backgroundImage: AssetImage('assets/admin_avatar.jpg')),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              Text("Online", style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
      iconTheme: IconThemeData(color: Colors.black),
      actions: [
        IconButton(icon: Icon(Icons.video_call, color: Colors.blueAccent), onPressed: () {}),
        IconButton(icon: Icon(Icons.call, color: Colors.blueAccent), onPressed: () {}),
      ],
    );
  }

  /// **🔹 Chat Messages Body**
  Widget _buildChatBody() {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildMessageBubble(
          text: message['text'],
          file: message['file'],
          fileType: message['fileType'],
          isMe: message['isMe'],
          time: message['time'],
        );
      },
    );
  }

  /// **🔹 Chat Message Bubble (With File Previews)**
  Widget _buildMessageBubble({String? text, File? file, String? fileType, required bool isMe, required String time}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file != null && fileType == "image") Image.file(file, width: 200), // Display image
            if (file != null && fileType == "video")
              VideoPlayerWidget(videoFile: file), // Display video
            if (file != null && fileType == "audio")
              AudioPlayerWidget(audioFile: file, audioPlayer: _audioPlayer), // Play audio
            if (file != null && fileType == "document")
              Text("📄 ${file.path.split('/').last}", style: TextStyle(color: Colors.white)), // Display document name
            if (text != null)
              Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 12),
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)]),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.emoji_emotions, color: Colors.blueAccent), onPressed: () {}),
          IconButton(icon: Icon(Icons.attach_file, color: Colors.blueAccent), onPressed: _pickFile),
          IconButton(icon: Icon(Icons.mic, color: Colors.redAccent), onPressed: _recordVoiceNote),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(hintText: "Type a message...", border: InputBorder.none),
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
  Widget build(BuildContext context) {
    return _controller.value.isInitialized ? VideoPlayer(_controller) : CircularProgressIndicator();
  }
}

/// **🔹 Audio Player Widget**
class AudioPlayerWidget extends StatelessWidget {
  final File audioFile;
  final AudioPlayer audioPlayer;
  const AudioPlayerWidget({super.key, required this.audioFile, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(Icons.play_arrow), onPressed: () => audioPlayer.play(audioFile.path as Source));
  }
}
