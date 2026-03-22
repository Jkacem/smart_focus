import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/document_section.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  int _selectedIndex = 2; // Index for chatbot in BottomNav
  final TextEditingController _msgController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Explique le cycle de Krebs',
      'isUser': true,
    },
    {
      'text':
          'Le cycle de Krebs est une série de réactions chimiques qui produit de lATP dans la mitochondrie.',
      'isUser': false,
      'sources': ['Biochimie p.45', 'Biochimie p.47'],
    },
  ];

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _msgController.text.trim(),
        'isUser': true,
      });
    });
    _msgController.clear();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/planning');
    } else if (index == 3) {
      context.go('/statistics');
    } else if (index == 4) {
      context.go('/settings');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Smart Chatbot 🤖',
        trailingIcon: Icons.library_books, // 📚 Document icon alternative
        onTrailingPressed: () {},
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a1628),
                  Color(0xFF1a3a4a),
                  Color(0xFF0d2635),
                ],
              ),
            ),
          ),
          // Starfield Background
          SizedBox.expand(child: CustomPaint(painter: StarfieldPainter())),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                const DocumentSection(
                  documents: ['📄 Biochimie_L2.pdf', '📄 Physique_S3.pdf'],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatBubble(
                        text: msg['text'],
                        isUser: msg['isUser'],
                        sources: msg['sources'],
                      );
                    },
                  ),
                ),
                _buildQuickActions(),
                _buildMessageInput(),
                const SizedBox(height: 10), // Nav Bar padding
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _QuickActionBtn(title: 'Quiz'),
          const SizedBox(width: 8),
          _QuickActionBtn(title: 'Flashcards'),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Pose ta question...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String title;
  const _QuickActionBtn({required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Action for quick button
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
