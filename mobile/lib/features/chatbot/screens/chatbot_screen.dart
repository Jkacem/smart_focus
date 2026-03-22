import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/document_section.dart';
import '../providers/chat_provider.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  int _selectedIndex = 2; // Index for chatbot in BottomNav
  final TextEditingController _msgController = TextEditingController();

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    
    final text = _msgController.text.trim();
    _msgController.clear();
    
    ref.read(chatProvider.notifier).sendMessage(text).catchError((err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString(), style: const TextStyle(color: Colors.white))),
        );
      }
    });
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
                const DocumentSection(),
                Expanded(
                  child: ref.watch(chatProvider).when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text("Posez votre première question!", style: TextStyle(color: Colors.white54)),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        reverse: true, // we reversed the list in provider so newest is at the bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          
                          // Convert SourceCitation to String
                          final sourceStrings = msg.sources.map((s) => 
                            "${s.filename} (p.${s.page ?? '?'})").toList();
                            
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. The User's Question
                              ChatBubble(
                                text: msg.question,
                                isUser: true,
                              ),
                              // 2. The Bot's Answer (if it's not empty / finished loading)
                              if (msg.answer.isNotEmpty)
                                ChatBubble(
                                  text: msg.answer,
                                  isUser: false,
                                  sources: sourceStrings,
                                )
                              else
                                // Optional loading indicator bubble could go here
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: CircularProgressIndicator(color: Colors.white54),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(child: Text("Erreur: $err", style: const TextStyle(color: Colors.red))),
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
