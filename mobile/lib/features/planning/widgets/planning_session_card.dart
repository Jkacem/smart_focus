import 'package:flutter/material.dart';
import 'package:smart_focus/shared/widgets/index.dart';

class PlanningSessionCard extends StatelessWidget {
  final int sessionId;
  final String time;
  final String title;
  final String duration;
  final double progress;
  final String priorityLabel;
  final String priorityIcon;
  final String statusLabel;
  final bool isCompleted;
  final String? linkedDocumentName;
  final Future<bool> Function() onDeleteRequested;
  final VoidCallback? onComplete;
  final VoidCallback? onManageDocument;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onGenerateFlashcards;

  const PlanningSessionCard({
    Key? key,
    required this.sessionId,
    required this.time,
    required this.title,
    required this.duration,
    required this.progress,
    required this.priorityLabel,
    required this.priorityIcon,
    required this.statusLabel,
    required this.isCompleted,
    required this.onDeleteRequested,
    this.linkedDocumentName,
    this.onComplete,
    this.onManageDocument,
    this.onGenerateQuiz,
    this.onGenerateFlashcards,
  }) : super(key: key);

  bool get _canGenerateStudyContent =>
      isCompleted && linkedDocumentName != null && linkedDocumentName!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(sessionId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => onDeleteRequested(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: FrostedGlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                time,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onComplete,
                          tooltip: isCompleted
                              ? 'Marquer comme non terminee'
                              : 'Marquer comme terminee',
                          icon: Icon(
                            isCompleted
                                ? Icons.restart_alt_rounded
                                : Icons.check_circle_outline,
                            color: isCompleted ? Colors.greenAccent : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progress),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          duration,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          '[$priorityLabel] $priorityIcon',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (linkedDocumentName != null && linkedDocumentName!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF97CAD8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF97CAD8).withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              color: Color(0xFF97CAD8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                linkedDocumentName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onManageDocument,
                          icon: const Icon(Icons.link, size: 18),
                          label: const Text('Changer le document'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                    if (!isCompleted) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB74D).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFB74D).withOpacity(0.55),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFFFFD180),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Session non terminee. Pense a la valider une fois finie.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (!_canGenerateStudyContent) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_off,
                              color: Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ajoute un document a cette session pour generer un quiz ou des flashcards cibles.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onManageDocument,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Ajouter un document'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                    if (_canGenerateStudyContent) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onGenerateQuiz,
                              icon: const Icon(Icons.quiz_outlined, size: 18),
                              label: const Text('Quiz'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onGenerateFlashcards,
                              icon: const Icon(Icons.style_outlined, size: 18),
                              label: const Text('Flashcards'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress > 0.7) return Colors.greenAccent;
    if (progress > 0.4) return Colors.blueAccent;
    return Colors.white70;
  }
}
