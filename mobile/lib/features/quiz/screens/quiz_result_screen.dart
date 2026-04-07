import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../data/quiz_repository.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  final int quizId;
  final QuizResultModel result;

  const QuizResultScreen({
    Key? key,
    required this.quizId,
    required this.result,
  }) : super(key: key);

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  bool _isRetrying = false;

  Future<void> _retryQuiz() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    try {
      final repository = ref.read(quizRepositoryProvider);
      final originalQuiz = await repository.getQuiz(widget.quizId);
      final documentIds = originalQuiz.documentIds.isNotEmpty
          ? originalQuiz.documentIds
          : (originalQuiz.documentId == null ? <int>[] : [originalQuiz.documentId!]);
      if (documentIds.isEmpty) {
        throw Exception('Les documents sources du quiz sont introuvables.');
      }
      final retriedQuiz = documentIds.length == 1
          ? await repository.generateQuiz(
              documentIds.first,
              numQuestions: originalQuiz.numQuestions,
            )
          : await repository.generateQuizForDocuments(
              documentIds,
              numQuestions: originalQuiz.numQuestions,
            );

      ref.invalidate(quizzesProvider);

      if (!mounted) return;
      context.pushReplacement(AppRoutes.quizPlay(retriedQuiz.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de relancer le quiz: $e'),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isPassed = result.percentage >= 50.0;
    final scoreColor = isPassed
        ? const Color(0xFF4ade80)
        : const Color(0xFFf87171);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Resultats',
        leadingIcon: Icons.home_outlined,
        onLeadingPressed: () => context.go(AppRoutes.dashboard),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: FrostedGlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scoreColor.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isPassed
                                ? Icons.emoji_events_outlined
                                : Icons.replay_outlined,
                            color: scoreColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPassed ? 'Bien joue !' : 'Continue !',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${result.score} / ${result.total}',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${result.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: result.questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final q = result.questions[index];
                      final isCorrect = q.userAnswerIndex == q.correctIndex;
                      final qColor = isCorrect
                          ? const Color(0xFF4ade80)
                          : const Color(0xFFf87171);

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: qColor.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: qColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isCorrect ? Icons.check : Icons.close,
                                        color: qColor,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        q.questionText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                  color: Colors.white12,
                                  thickness: 1,
                                  height: 1,
                                ),
                                const SizedBox(height: 12),
                                _AnswerRow(
                                  label: 'Ta reponse',
                                  text:
                                      (q.userAnswerIndex != null &&
                                          q.userAnswerIndex! >= 0 &&
                                          q.userAnswerIndex! <
                                              q.options.length)
                                      ? q.options[q.userAnswerIndex!]
                                      : 'Aucune reponse',
                                  color: isCorrect
                                      ? const Color(0xFF4ade80)
                                      : const Color(0xFFf87171),
                                ),
                                if (!isCorrect && q.correctIndex != null) ...[
                                  const SizedBox(height: 6),
                                  _AnswerRow(
                                    label: 'Bonne reponse',
                                    text: q.options[q.correctIndex!],
                                    color: const Color(0xFF4ade80),
                                  ),
                                ],
                                if (q.explanation != null &&
                                    q.explanation!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF97cad8,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF97cad8,
                                        ).withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.lightbulb_outline,
                                          color: Color(0xFF97cad8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            q.explanation!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _isRetrying
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF97cad8),
                          ),
                        )
                      : CustomButton(
                          text: 'Refaire le quiz',
                          onPressed: _retryQuiz,
                          width: double.infinity,
                          height: 54,
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
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _AnswerRow({
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
