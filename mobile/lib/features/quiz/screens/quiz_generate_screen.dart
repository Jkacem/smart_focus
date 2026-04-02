import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../providers/quiz_provider.dart';

class QuizGenerateScreen extends ConsumerStatefulWidget {
  final int? documentId;
  final int? sessionId;
  final String documentTitle;

  const QuizGenerateScreen({
    Key? key,
    this.documentId,
    this.sessionId,
    required this.documentTitle,
  }) : assert(documentId != null || sessionId != null),
       super(key: key);

  @override
  ConsumerState<QuizGenerateScreen> createState() => _QuizGenerateScreenState();
}

class _QuizGenerateScreenState extends ConsumerState<QuizGenerateScreen> {
  int _numQuestions = 10;

  bool get _fromSession => widget.sessionId != null;

  void _generateQuiz() async {
    try {
      final notifier = ref.read(quizGeneratorProvider.notifier);
      final newQuiz = _fromSession
          ? await notifier.generateQuizFromSession(widget.sessionId!, _numQuestions)
          : await notifier.generateQuiz(widget.documentId!, _numQuestions);

      if (newQuiz != null && mounted) {
        ref.invalidate(quizzesProvider);
        context.pushReplacement('/quiz/play/${newQuiz.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate quiz: $e'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final generateState = ref.watch(quizGeneratorProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Generate Quiz',
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
                            Icons.quiz_outlined,
                            size: 32,
                            color: Color(0xFF97cad8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quiz Generation',
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
                          'Number of Questions',
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
                              onTap: _numQuestions > 3
                                  ? () => setState(() => _numQuestions--)
                                  : null,
                            ),
                            const SizedBox(width: 32),
                            Text(
                              '$_numQuestions',
                              style: const TextStyle(
                                color: Color(0xFF97cad8),
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 32),
                            _CounterButton(
                              icon: Icons.add,
                              onTap: _numQuestions < 30
                                  ? () => setState(() => _numQuestions++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'min 3 · max 30',
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
                      text: _fromSession ? 'Generate Session Quiz' : 'Generate Quiz',
                      onPressed: _generateQuiz,
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
