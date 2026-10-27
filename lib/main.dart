import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Private Chat App',
      theme: ThemeData.dark(),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    socket = IO.io('http://10.0.2.2:8000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
  }

  void login() {
    socket.emit('login', {
      'userId': _idController.text.trim(),
      'password': _passController.text.trim(),
    }, (response) {
      if (response['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(socket: socket, currentUserId: _idController.text.trim(), streak: response['streak']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تسجيل الدخول - تطبيق خاص')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: 'الرقم التعريفي (مثال: 10 أو 7)'),
            ),
            TextField(
              controller: _passController,
              decoration: InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text('دخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final IO.Socket socket;
  final String currentUserId;
  final int streak;

  ChatScreen({required this.socket, required this.currentUserId, required this.streak});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    widget.socket.on('message', (data) {
      setState(() {
        messages.add("من ${data['sender']}: ${data['text']}");
      });
    });
  }

  void sendMessage() {
    if (_msgController.text.isNotEmpty && _recipientController.text.isNotEmpty) {
      widget.socket.emit('message', {
        'sender': widget.currentUserId,
        'recipient': _recipientController.text.trim(),
        'text': _msgController.text.trim(),
      });
      setState(() {
        messages.add("أنت إلى ${_recipientController.text.trim()}: ${_msgController.text.trim()}");
        _msgController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المحادثة (يوزر: ${widget.currentUserId})'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange),
                  Text('${widget.streak}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _recipientController,
              decoration: InputDecoration(labelText: 'رقم المستقبل (مثال: 7 أو 10)'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(messages[index]));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(labelText: 'اكتب رسالتك...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}