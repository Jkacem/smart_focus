import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_provider.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final int quizId;

  const QuizPlayScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  int _currentIndex = 0;
  List<int?> _answers = [];

  void _submitQuiz(QuizModel quiz) async {
    final finalAnswers = List.generate(
      quiz.questions.length,
      (i) => _answers.length > i && _answers[i] != null ? _answers[i]! : -1,
    );

    try {
      final result = await ref
          .read(quizSubmitProvider.notifier)
          .submitQuiz(quiz.id, finalAnswers);

      if (result != null && mounted) {
        ref.invalidate(quizzesProvider);
        context.pushReplacement('/quiz/result/${quiz.id}', extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit quiz: $e'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizDetailProvider(widget.quizId));
    final submitState = ref.watch(quizSubmitProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Quiz',
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
            child: quizAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF97cad8)),
              ),
              error: (err, st) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              data: (quiz) {
                if (_answers.isEmpty && quiz.questions.isNotEmpty) {
                  _answers = List<int?>.filled(quiz.questions.length, null);
                }
                if (quiz.questions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No questions found.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final currentQ = quiz.questions[_currentIndex];

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Progress bar
                      Row(
                        children: [
                          Text(
                            'Q${_currentIndex + 1}/${quiz.questions.length}',
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
                                value:
                                    (_currentIndex + 1) / quiz.questions.length,
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

                      const SizedBox(height: 20),

                      // Question card
                      FrostedGlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          currentQ.questionText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Options
                      Expanded(
                        child: ListView.separated(
                          itemCount: currentQ.options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final isSelected = _answers[_currentIndex] == idx;
                            final letter = 'ABCD'[idx];
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _answers[_currentIndex] = idx),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF97cad8,
                                            ).withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF97cad8)
                                            : Colors.white.withOpacity(0.15),
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF97cad8)
                                                : Colors.white.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.7,
                                                      ),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            currentQ.options[idx],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(
                                                      0.85,
                                                    ),
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Navigation
                      if (submitState.isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF97cad8),
                          ),
                        )
                      else
                        Row(
                          children: [
                            if (_currentIndex > 0) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                      onPressed: () =>
                                          setState(() => _currentIndex--),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: CustomButton(
                                text: _currentIndex < quiz.questions.length - 1
                                    ? 'Next →'
                                    : '✓  Submit Quiz',
                                onPressed: () {
                                  if (_currentIndex <
                                      quiz.questions.length - 1) {
                                    setState(() => _currentIndex++);
                                  } else {
                                    _submitQuiz(quiz);
                                  }
                                },
                                height: 52,
                                backgroundColor: const Color(0xFF97cad8),
                                borderColor: const Color(0xFF97cad8),
                                textColor: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                borderRadius: 14,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
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
}
