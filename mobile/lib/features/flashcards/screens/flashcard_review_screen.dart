import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';
import '../models/flashcard_models.dart';
import '../providers/flashcard_provider.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  final int? documentId;

  const FlashcardReviewScreen({Key? key, this.documentId}) : super(key: key);

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  List<FlashcardModel> _dueCards = [];
  bool _isInitialized = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: pi / 2,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -pi / 2,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_flipCtrl);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _isFlipped = !_isFlipped);
    _flipCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = widget.documentId != null
        ? ref.watch(flashcardDeckProvider(widget.documentId!))
        : ref.watch(dueFlashcardsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Review Session',
        leadingIcon: Icons.close,
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
            child: asyncValue.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF97cad8)),
              ),
              error: (err, st) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (data) {
                if (!_isInitialized) {
                  final now = DateTime.now().toUtc();
                  if (data is FlashcardDeckModel) {
                    _dueCards = data.cards
                        .where((c) => c.nextReview.isBefore(now))
                        .toList();
                  } else if (data is List<FlashcardModel>) {
                    _dueCards = data
                        .where((c) => c.nextReview.isBefore(now))
                        .toList();
                  }
                  _isInitialized = true;
                }

                if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) {
                  return _buildFinishedState(context);
                }

                final currentCard = _dueCards[_currentIndex];

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Progress
                      Row(
                        children: [
                          Text(
                            '${_currentIndex + 1}/${_dueCards.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_currentIndex + 1) / _dueCards.length,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF97cad8),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Flip hint
                      Text(
                        _isFlipped
                            ? 'Tap card to see front'
                            : 'Tap card to reveal answer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Flashcard with flip animation
                      Expanded(
                        child: GestureDetector(
                          onTap: _flip,
                          child: AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.rotationY(_flipAnim.value),
                                alignment: Alignment.center,
                                child: _buildCardFace(currentCard, _isFlipped),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action area
                      if (!_isFlipped)
                        CustomButton(
                          text: 'Show Answer',
                          onPressed: _flip,
                          height: 52,
                          backgroundColor: Colors.white,
                          borderColor: Colors.white,
                          textColor: const Color(0xFF0a1628),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          borderRadius: 14,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'How well did you remember?',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _buildRatingBtn(
                                  '✗',
                                  'Again',
                                  const Color(0xFFf87171),
                                  0,
                                  currentCard,
                                ),
                                const SizedBox(width: 8),
                                _buildRatingBtn(
                                  '~',
                                  'Hard',
                                  const Color(0xFFfb923c),
                                  2,
                                  currentCard,
                                ),
                                const SizedBox(width: 8),
                                _buildRatingBtn(
                                  '✓',
                                  'Good',
                                  const Color(0xFF4ade80),
                                  4,
                                  currentCard,
                                ),
                                const SizedBox(width: 8),
                                _buildRatingBtn(
                                  '★',
                                  'Easy',
                                  const Color(0xFF97cad8),
                                  5,
                                  currentCard,
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace(FlashcardModel card, bool isBack) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isBack
                ? const Color(0xFF97cad8).withOpacity(0.08)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isBack
                  ? const Color(0xFF97cad8).withOpacity(0.4)
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isBack ? 'ANSWER' : 'QUESTION',
                style: TextStyle(
                  color: isBack
                      ? const Color(0xFF97cad8)
                      : Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isBack ? card.back : card.front,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBtn(
    String symbol,
    String label,
    Color color,
    int quality,
    FlashcardModel card,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            await ref.read(reviewFlashcardProvider)(card.id, quality);
            if (mounted) {
              setState(() {
                _isFlipped = false;
                _currentIndex++;
              });
              _flipCtrl.reset();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save rating: $e')),
              );
            }
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF4ade80).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4ade80).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 44,
                color: Color(0xFF4ade80),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Complete! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You have reviewed all due flashcards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 36),
            CustomButton(
              text: '← Back to Deck',
              onPressed: () {
                if (widget.documentId != null) {
                  ref.invalidate(flashcardDeckProvider(widget.documentId!));
                } else {
                  ref.invalidate(dueFlashcardsProvider);
                }
                context.pop();
              },
              height: 52,
              backgroundColor: const Color(0xFF97cad8),
              borderColor: const Color(0xFF97cad8),
              textColor: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
