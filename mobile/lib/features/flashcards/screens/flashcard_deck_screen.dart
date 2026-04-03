import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../data/flashcard_repository.dart';
import '../providers/flashcard_provider.dart';

class FlashcardDeckScreen extends ConsumerWidget {
  final int? documentId;
  final int? sessionId;

  const FlashcardDeckScreen({
    Key? key,
    this.documentId,
    this.sessionId,
  }) : assert(documentId != null || sessionId != null),
       super(key: key);

  bool get _fromSession => sessionId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = _fromSession
        ? ref.watch(sessionFlashcardDeckProvider(sessionId!))
        : ref.watch(flashcardDeckProvider(documentId!));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Flashcard Deck',
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
            child: deckAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF97cad8)),
              ),
              error: (err, st) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (deck) {
                if (deck.cards.isEmpty) {
                  return _buildEmptyState(context, deck.documentName);
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: FrostedGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              deck.sessionSubject ?? deck.documentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_fromSession) ...[
                              const SizedBox(height: 6),
                              Text(
                                deck.documentName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatBadge(
                                  label: 'Total',
                                  value: '${deck.totalCards}',
                                  icon: Icons.style_outlined,
                                  color: const Color(0xFF97cad8),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                _StatBadge(
                                  label: 'Due Now',
                                  value: '${deck.dueCards}',
                                  icon: Icons.schedule_outlined,
                                  color: deck.dueCards > 0
                                      ? const Color(0xFFfacc15)
                                      : const Color(0xFF4ade80),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: deck.dueCards > 0
                                  ? 'Review ${deck.dueCards} Cards'
                                  : 'All Caught Up',
                              onPressed: deck.dueCards > 0
                                  ? () => context.push(_reviewRoute)
                                  : () {},
                              height: 52,
                              backgroundColor: deck.dueCards > 0
                                  ? const Color(0xFF97cad8)
                                  : Colors.white,
                              borderColor: deck.dueCards > 0
                                  ? const Color(0xFF97cad8)
                                  : Colors.white,
                              textColor: deck.dueCards > 0
                                  ? Colors.white
                                  : Colors.black54,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              borderRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: deck.cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final card = deck.cards[index];
                          final isDue = card.nextReview.isBefore(DateTime.now().toUtc());

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDue
                                        ? const Color(0xFFfacc15).withOpacity(0.4)
                                        : Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDue
                                            ? const Color(0xFFfacc15).withOpacity(0.15)
                                            : const Color(0xFF97cad8).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDue
                                            ? Icons.schedule_outlined
                                            : Icons.check_circle_outline,
                                        color: isDue
                                            ? const Color(0xFFfacc15)
                                            : const Color(0xFF97cad8),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            card.front,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isDue
                                                ? 'Due for review'
                                                : 'Next: ${card.nextReview.toLocal().toString().split(' ')[0]}',
                                            style: TextStyle(
                                              color: isDue
                                                  ? const Color(0xFFfacc15)
                                                  : Colors.white.withOpacity(0.4),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.white.withOpacity(0.35),
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteCard(context, ref, card.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String get _reviewRoute {
    if (_fromSession) {
      return AppRoutes.flashcardsReview(sessionId: sessionId);
    }
    return AppRoutes.flashcardsReview(documentId: documentId);
  }

  Widget _buildEmptyState(BuildContext context, String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF97cad8).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF97cad8).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.style_outlined,
                size: 40,
                color: Color(0xFF97cad8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No flashcards yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Generate AI flashcards from\n$title',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Generate Cards',
              onPressed: () {
                if (_fromSession) {
                  context.pushReplacement(
                    AppRoutes.flashcardsGenerateSession(
                      sessionId!,
                      title: title,
                    ),
                  );
                  return;
                }
                context.pushReplacement(
                  AppRoutes.flashcardsGenerateDocument(
                    documentId!,
                    title: title,
                  ),
                );
              },
              height: 52,
              backgroundColor: const Color(0xFF97cad8),
              borderColor: const Color(0xFF97cad8),
              textColor: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCard(BuildContext context, WidgetRef ref, int cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a3a4a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Card',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete this flashcard?',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFf87171)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final repository = ref.read(flashcardRepositoryProvider);
        await repository.deleteCard(cardId);
        if (sessionId != null) {
          ref.invalidate(sessionFlashcardDeckProvider(sessionId!));
        }
        if (documentId != null) {
          ref.invalidate(flashcardDeckProvider(documentId!));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      ],
    );
  }
}
