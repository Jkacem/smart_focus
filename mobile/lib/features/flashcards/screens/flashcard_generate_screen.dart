import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/features/planning/providers/planning_provider.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../providers/flashcard_provider.dart';

class FlashcardGenerateScreen extends ConsumerStatefulWidget {
  final int? documentId;
  final int? sessionId;
  final String documentTitle;

  const FlashcardGenerateScreen({
    Key? key,
    this.documentId,
    this.sessionId,
    required this.documentTitle,
  }) : assert(documentId != null || sessionId != null),
       super(key: key);

  @override
  ConsumerState<FlashcardGenerateScreen> createState() =>
      _FlashcardGenerateScreenState();
}

class _FlashcardGenerateScreenState extends ConsumerState<FlashcardGenerateScreen> {
  int _numCards = 10;

  bool get _fromSession => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(flashcardGeneratorProvider.notifier).reset();
    });
  }

  void _generateCards() async {
    try {
      final notifier = ref.read(flashcardGeneratorProvider.notifier);
      final deck = _fromSession
          ? await notifier.generateFlashcardsFromSession(widget.sessionId!, _numCards)
          : await notifier.generateFlashcards(widget.documentId!, _numCards);

      if (deck != null && mounted) {
        if (deck.documentId != null) {
          ref.invalidate(flashcardDeckProvider(deck.documentId!));
        }
        if (deck.sessionId != null) {
          ref.invalidate(sessionFlashcardDeckProvider(deck.sessionId!));
        }
        await ref.read(planningProvider.notifier).refresh();
        if (!mounted) return;
        context.pushReplacement(
          deck.sessionId != null
              ? '/flashcards/deck/session/${deck.sessionId}'
              : '/flashcards/deck/${deck.documentId}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate flashcards: $e'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    ref.read(flashcardGeneratorProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generateState = ref.watch(flashcardGeneratorProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Generate Flashcards',
        leadingIcon: Icons.arrow_back,
        onLeadingPressed: () => context.pop(),
      ),
      body: Stack(
        children: [
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
          SizedBox.expand(child: CustomPaint(painter: StarfieldPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  FrostedGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF97cad8).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF97cad8).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.style_outlined,
                            size: 32,
                            color: Color(0xFF97cad8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI Flashcard Deck',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fromSession ? 'Source: completed session' : 'Source: document',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.documentTitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FrostedGlassCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 24,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Number of Cards',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CounterButton(
                              icon: Icons.remove,
                              onTap: _numCards > 5
                                  ? () => setState(() => _numCards -= 5)
                                  : null,
                            ),
                            const SizedBox(width: 32),
                            Text(
                              '$_numCards',
                              style: const TextStyle(
                                color: Color(0xFF97cad8),
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 32),
                            _CounterButton(
                              icon: Icons.add,
                              onTap: _numCards < 50
                                  ? () => setState(() => _numCards += 5)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'min 5 · max 50',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (generateState.isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF97cad8)),
                    )
                  else
                    CustomButton(
                      text: _fromSession ? 'Generate Session Deck' : 'Generate Deck',
                      onPressed: _generateCards,
                      width: double.infinity,
                      height: 56,
                      backgroundColor: const Color(0xFF97cad8),
                      borderColor: const Color(0xFF97cad8),
                      textColor: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      borderRadius: 16,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
