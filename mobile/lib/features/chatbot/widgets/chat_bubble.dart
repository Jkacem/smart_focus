import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<String>? sources;

  const ChatBubble({
    Key? key,
    required this.text,
    required this.isUser,
    this.sources,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Text('🤖', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6A1B9A).withOpacity(0.8) // Purple for user
                    : Colors.white.withOpacity(0.1), // Gray/glass for bot
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (sources != null && sources!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 4),
                    const Text(
                      '📎 Sources :',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...sources!.map((source) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: InkWell(
                            onTap: () {},
                            child: Text(
                              '• $source',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Text('👤', style: TextStyle(fontSize: 24)),
            ),
          ],
        ],
      ),
    );
  }
}
