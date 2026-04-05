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
  final String? smartSessionLabel;
  final String? smartSessionHint;
  final IconData? smartSessionIcon;
  final Color? smartSessionAccentColor;
  final String? primaryActionLabel;
  final Future<bool> Function() onDeleteRequested;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onManageDocument;
  final VoidCallback? onGenerateQuiz;
  final VoidCallback? onGenerateFlashcards;
  final VoidCallback? onReschedule;
  final String? rescheduleLabel;
  final String? quizActionLabel;
  final String? flashcardActionLabel;
  final Color? quizActionColor;
  final Color? flashcardActionColor;
  final IconData? quizActionIcon;
  final IconData? flashcardActionIcon;

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
    this.smartSessionLabel,
    this.smartSessionHint,
    this.smartSessionIcon,
    this.smartSessionAccentColor,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onTap,
    this.onComplete,
    this.onManageDocument,
    this.onGenerateQuiz,
    this.onGenerateFlashcards,
    this.onReschedule,
    this.rescheduleLabel,
    this.quizActionLabel,
    this.flashcardActionLabel,
    this.quizActionColor,
    this.flashcardActionColor,
    this.quizActionIcon,
    this.flashcardActionIcon,
  }) : super(key: key);

  bool get _canShowStudyContentActions =>
      isCompleted &&
      (onGenerateQuiz != null || onGenerateFlashcards != null);

  bool get _hasSmartHeader =>
      smartSessionLabel != null &&
      smartSessionLabel!.isNotEmpty &&
      smartSessionIcon != null &&
      smartSessionAccentColor != null;

  @override
  Widget build(BuildContext context) {
    final accentColor = smartSessionAccentColor ?? const Color(0xFF97CAD8);

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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: FrostedGlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasSmartHeader) ...[
                  _SmartBadge(
                    label: smartSessionLabel!,
                    icon: smartSessionIcon!,
                    color: accentColor,
                  ),
                  const SizedBox(height: 12),
                ],
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
                if (smartSessionHint != null && smartSessionHint!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoBox(
                    icon: smartSessionIcon ?? Icons.auto_awesome,
                    color: accentColor,
                    message: smartSessionHint!,
                  ),
                ],
                if (primaryActionLabel != null &&
                    primaryActionLabel!.isNotEmpty &&
                    onPrimaryAction != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPrimaryAction,
                      icon: Icon(
                        smartSessionIcon ?? Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(primaryActionLabel!),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: accentColor.withOpacity(0.22),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: accentColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (linkedDocumentName != null && linkedDocumentName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                ],
                if (onManageDocument != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onManageDocument,
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(
                        linkedDocumentName != null && linkedDocumentName!.isNotEmpty
                            ? 'Gerer les documents'
                            : 'Lier des documents',
                      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            onReschedule != null
                                ? 'Session manquee ou annulee. Tu peux la replanifier automatiquement.'
                                : 'Session non terminee. Pense a la valider une fois finie.',
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
                  if (onReschedule != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: rescheduleLabel ?? 'Replanifier',
                        color: const Color(0xFFFFC857),
                        icon: Icons.update_outlined,
                        onPressed: onReschedule,
                      ),
                    ),
                  ],
                ] else if (!_canShowStudyContentActions) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            'Ajoute un document a cette session pour generer ou rouvrir un quiz et des flashcards lies.',
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
                if (_canShowStudyContentActions) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: quizActionLabel ?? 'Quiz',
                          color: quizActionColor ?? const Color(0xFF97CAD8),
                          icon: quizActionIcon ?? Icons.quiz_outlined,
                          onPressed: onGenerateQuiz,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: flashcardActionLabel ?? 'Flashcards',
                          color: flashcardActionColor ?? const Color(0xFF97CAD8),
                          icon: flashcardActionIcon ?? Icons.style_outlined,
                          onPressed: onGenerateFlashcards,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress > 0.7) {
      return Colors.greenAccent;
    }
    if (progress > 0.4) {
      return Colors.blueAccent;
    }
    return Colors.white70;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color.withOpacity(0.22),
        disabledBackgroundColor: Colors.white.withOpacity(0.08),
        disabledForegroundColor: Colors.white54,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withOpacity(0.45),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _SmartBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SmartBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBox({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.32),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
