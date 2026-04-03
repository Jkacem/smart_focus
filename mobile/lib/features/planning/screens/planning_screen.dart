import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';

import 'package:smart_focus/features/chatbot/models/chatbot_models.dart';
import 'package:smart_focus/features/chatbot/providers/document_provider.dart';
import 'package:smart_focus/features/planning/models/planning_models.dart';
import 'package:smart_focus/features/planning/providers/planning_provider.dart';
import 'package:smart_focus/features/planning/widgets/mini_date_picker.dart';
import 'package:smart_focus/features/planning/widgets/planning_session_card.dart';
import 'package:smart_focus/shared/widgets/index.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go(AppRoutes.dashboard);
    } else if (index == 1) {
      context.go(AppRoutes.planning);
    } else if (index == 2) {
      context.go(AppRoutes.chatbot);
    } else if (index == 3) {
      context.go(AppRoutes.statistics);
    } else if (index == 4) {
      context.go(AppRoutes.sleep);
    } else if (index == 5) {
      context.go(AppRoutes.settings);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final planningState = ref.watch(planningProvider);
    final planningNotifier = ref.read(planningProvider.notifier);
    final docsState = ref.watch(documentProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Mon Planning',
        trailingWidget: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8A2387),
                Color(0xFFE94057),
                Color(0xFFF27121),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94057).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: planningState.isMutating
                  ? null
                  : () => _showGeneratePlanningDialog(
                        context,
                        docsState,
                        planningNotifier,
                      ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                if (planningState.isMutating)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MiniDatePicker(
                    selectedDate: planningState.selectedDate,
                    onDateSelected: planningNotifier.loadDay,
                    onPreviousWeek: () => planningNotifier.loadDay(
                      planningState.selectedDate.subtract(const Duration(days: 7)),
                    ),
                    onNextWeek: () => planningNotifier.loadDay(
                      planningState.selectedDate.add(const Duration(days: 7)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _headerTitle(planningState.selectedDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _AdaptiveSchedulingNotice(),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: planningNotifier.refresh,
                    color: Colors.black,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: planningState.sessions.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          if (planningState.isLoading && planningState.sessions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            );
                          }

                          if (planningState.errorMessage != null &&
                              planningState.sessions.isEmpty) {
                            return _PlanningFeedbackCard(
                              icon: Icons.error_outline,
                              message: planningState.errorMessage!,
                              actionLabel: 'Reessayer',
                              onPressed: () => planningNotifier.loadDay(
                                planningState.selectedDate,
                              ),
                            );
                          }

                          if (planningState.sessions.isEmpty) {
                            return _PlanningFeedbackCard(
                              icon: Icons.event_note,
                              message:
                                  'Aucune session pour cette journee. Utilise IA ou ajoute une session manuellement.',
                              actionLabel: 'Generer avec IA',
                              onPressed: planningState.isMutating
                                  ? null
                                  : () => _showGeneratePlanningDialog(
                                        context,
                                        docsState,
                                        planningNotifier,
                                      ),
                            );
                          }

                          return const SizedBox.shrink();
                        }

                        if (index <= planningState.sessions.length) {
                          final session = planningState.sessions[index - 1];
                          return PlanningSessionCard(
                            sessionId: session.id,
                            time:
                                '${_formatTime(session.start)} - ${_formatTime(session.end)}',
                            title: session.subject,
                            duration: _formatDuration(session.duration),
                            progress: session.progress,
                            priorityLabel: session.priorityLabel,
                            priorityIcon: session.priorityIcon,
                            statusLabel: session.statusLabel,
                            isCompleted: session.isCompleted,
                            linkedDocumentName: session.documentName,
                            smartSessionLabel: session.smartSessionLabel,
                            smartSessionHint: session.smartSessionHint,
                            smartSessionIcon: _smartSessionIcon(session),
                            smartSessionAccentColor: _smartSessionAccentColor(session),
                            primaryActionLabel: _primaryActionLabel(session),
                            quizActionLabel: _quizActionLabel(session),
                            flashcardActionLabel: _flashcardActionLabel(session),
                            quizActionColor: _quizActionColor(session),
                            flashcardActionColor: _flashcardActionColor(session),
                            quizActionIcon: _quizActionIcon(session),
                            flashcardActionIcon: _flashcardActionIcon(session),
                            onDeleteRequested: () async {
                              try {
                                await planningNotifier.deleteSession(session.id);
                                if (!context.mounted) return true;
                                _showSnackBar(context, '${session.subject} supprime');
                                return true;
                              } catch (e) {
                                if (!context.mounted) return false;
                                _showSnackBar(context, e.toString(), isError: true);
                                return false;
                              }
                            },
                            onComplete: session.isCompleted
                                ? () async {
                                    try {
                                      await planningNotifier.toggleSessionCompletion(
                                        session.id,
                                        session.isCompleted,
                                      );
                                      if (!context.mounted) return;
                                      _showSnackBar(
                                        context,
                                        '${session.subject} marquee comme non terminee',
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      _showSnackBar(context, e.toString(), isError: true);
                                    }
                                  }
                                : () async {
                                    try {
                                      await planningNotifier.toggleSessionCompletion(
                                        session.id,
                                        session.isCompleted,
                                      );
                                      if (!context.mounted) return;
                                      _showSnackBar(
                                        context,
                                        '${session.subject} marquee comme terminee',
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      _showSnackBar(context, e.toString(), isError: true);
                                    }
                                  },
                            onPrimaryAction: _primaryAction(session, planningNotifier),
                            onTap: _sessionTapAction(session, planningNotifier),
                            onManageDocument: () => _showSessionDocumentDialog(
                              context,
                              session,
                              planningNotifier,
                            ),
                            onGenerateQuiz: _quizAction(session, planningNotifier),
                            onGenerateFlashcards: _flashcardAction(
                              session,
                              planningNotifier,
                            ),
                            onReschedule: _rescheduleAction(session, planningNotifier),
                            rescheduleLabel: session.isCancelled
                                ? 'Replanifier'
                                : session.isMissed
                                    ? 'Reporter'
                                    : null,
                          );
                        }

                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: TextButton.icon(
                                onPressed: planningState.isMutating
                                    ? null
                                    : () => _showAddSessionDialog(
                                          context,
                                          planningState.selectedDate,
                                          planningNotifier,
                                        ),
                                icon: const Icon(Icons.add),
                                label: const Text(
                                  'Ajouter une session',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        );
                      },
                    ),
                  ),
                ),
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

  Future<void> _showAddSessionDialog(
    BuildContext context,
    DateTime selectedDate,
    PlanningNotifier planningNotifier,
  ) async {
    final subjectController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    String priority = 'medium';
    int? selectedDocumentId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvelle session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Matiere / sujet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setDialogState(() => startTime = picked);
                              }
                            },
                            child: Text('Debut ${startTime.format(dialogContext)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setDialogState(() => endTime = picked);
                              }
                            },
                            child: Text('Fin ${endTime.format(dialogContext)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priorite',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Faible')),
                        DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                        DropdownMenuItem(value: 'high', child: Text('Haute')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, _) {
                        final liveDocsState = ref.watch(documentProvider);
                        return _DocumentPickerSection(
                          docsState: liveDocsState,
                          selectedDocumentId: selectedDocumentId,
                          label: 'Document etudie',
                          onChanged: (value) {
                            setDialogState(() => selectedDocumentId = value);
                          },
                          onUpload: () async {
                            await ref.read(documentProvider.notifier).uploadDocument();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final subject = subjectController.text.trim();
                    if (subject.isEmpty) {
                      _showSnackBar(context, 'Le sujet est obligatoire.', isError: true);
                      return;
                    }

                    final start = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final end = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    if (!end.isAfter(start)) {
                      _showSnackBar(
                        context,
                        'L heure de fin doit etre apres l heure de debut.',
                        isError: true,
                      );
                      return;
                    }

                    try {
                      await planningNotifier.createSession(
                        subject: subject,
                        start: start,
                        end: end,
                        priority: priority,
                        documentId: selectedDocumentId,
                      );
                      if (!context.mounted) return;
                      Navigator.of(dialogContext).pop();
                      _showSnackBar(context, 'Session ajoutee.');
                    } catch (e) {
                      if (!context.mounted) return;
                      _showSnackBar(context, e.toString(), isError: true);
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSessionDocumentDialog(
    BuildContext context,
    PlanningSessionModel session,
    PlanningNotifier planningNotifier,
  ) async {
    int? selectedDocumentId = session.documentId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Document pour ${session.subject}'),
              content: Consumer(
                builder: (context, ref, _) {
                  final docsState = ref.watch(documentProvider);
                  return _DocumentPickerSection(
                    docsState: docsState,
                    selectedDocumentId: selectedDocumentId,
                    label: 'Document lie',
                    onChanged: (value) {
                      setDialogState(() => selectedDocumentId = value);
                    },
                    onUpload: () async {
                      await ref.read(documentProvider.notifier).uploadDocument();
                    },
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      await planningNotifier.updateSessionDocument(
                        session.id,
                        selectedDocumentId,
                      );
                      if (!context.mounted) return;
                      Navigator.of(dialogContext).pop();
                      _showSnackBar(
                        context,
                        selectedDocumentId == null
                            ? 'Document retire de la session.'
                            : 'Document lie a la session.',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      _showSnackBar(context, e.toString(), isError: true);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGeneratePlanningDialog(
    BuildContext context,
    AsyncValue<List<DocumentInfo>> docsState,
    PlanningNotifier planningNotifier,
  ) async {
    int? selectedDocumentId;
    String? weekType;
    bool generateWholeWeek = true;
    final preferencesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Generer avec IA'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _DialogInfoBanner(
                      icon: Icons.schedule_outlined,
                      accent: Color(0xFF8B5CF6),
                      message:
                          'Les revisions automatiques privilegient vos heures de completion les plus fiables sur les 14 derniers jours. Sans historique, votre plage preferee reste utilisee.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: preferencesController,
                      decoration: const InputDecoration(
                        labelText: 'Preferences (optionnel)',
                        hintText: 'Ex: Maths, Physique',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: weekType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Type de semaine',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Auto'),
                        ),
                        DropdownMenuItem(
                          value: 'A',
                          child: Text('Semaine A'),
                        ),
                        DropdownMenuItem(
                          value: 'B',
                          child: Text('Semaine B'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() => weekType = value),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: generateWholeWeek,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Generer toute la semaine'),
                      subtitle: const Text('Lundi a dimanche de la semaine affichee'),
                      onChanged: (value) {
                        setDialogState(() => generateWholeWeek = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    docsState.when(
                      data: (docs) {
                        final items = <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sans document'),
                          ),
                          ...docs.map(
                            (doc) => DropdownMenuItem<int?>(
                              value: doc.id,
                              child: Text(
                                doc.filename,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ];

                        return DropdownButtonFormField<int?>(
                          value: selectedDocumentId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Document source',
                            border: OutlineInputBorder(),
                          ),
                          items: items,
                          selectedItemBuilder: (context) => [
                            const Text(
                              'Sans document',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            ...docs.map(
                              (doc) => Text(
                                doc.filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selectedDocumentId = value);
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stackTrace) => Text(
                        'Documents indisponibles: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final preferences = preferencesController.text.trim();

                    try {
                      if (generateWholeWeek) {
                        await planningNotifier.generatePlanningForWeek(
                          documentId: selectedDocumentId,
                          weekType: weekType,
                          preferences: preferences.isEmpty
                              ? null
                              : {'focus_subjects': preferences},
                        );
                      } else {
                        await planningNotifier.generatePlanning(
                          documentId: selectedDocumentId,
                          weekType: weekType,
                          preferences: preferences.isEmpty
                              ? null
                              : {'focus_subjects': preferences},
                        );
                      }
                      if (!context.mounted) return;
                      Navigator.of(dialogContext).pop();
                      _showSnackBar(
                        context,
                        generateWholeWeek
                            ? 'Planning de la semaine genere avec succes.'
                            : 'Planning genere avec succes.',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      _showSnackBar(context, e.toString(), isError: true);
                    }
                  },
                  child: Text(generateWholeWeek ? 'Generer la semaine' : 'Generer le jour'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _headerTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return "Aujourd'hui";
    }

    const months = [
      'janvier',
      'fevrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'aout',
      'septembre',
      'octobre',
      'novembre',
      'decembre',
    ];

    return '${selected.day} ${months[selected.month - 1]}';
  }

  IconData? _smartSessionIcon(PlanningSessionModel session) {
    if (session.isFlashcardReviewSession) {
      return Icons.style_outlined;
    }
    if (session.isQuizRevisionSession) {
      return Icons.quiz_outlined;
    }
    if (session.isSmartRevisionSession || session.isAiGenerated) {
      return Icons.auto_awesome;
    }
    return null;
  }

  Color? _smartSessionAccentColor(PlanningSessionModel session) {
    if (session.isFlashcardReviewSession) {
      return const Color(0xFF8BD3A8);
    }
    if (session.isQuizRevisionSession) {
      return const Color(0xFFFFC857);
    }
    if (session.isAiGenerated) {
      return const Color(0xFF97CAD8);
    }
    return null;
  }

  String? _primaryActionLabel(PlanningSessionModel session) {
    if (session.isFlashcardReviewSession && session.documentId != null) {
      return session.hasSavedFlashcards
          ? (session.sessionFlashcardsDue > 0 ? 'Reprendre la revision' : 'Voir les cartes')
          : 'Generer des cartes';
    }
    if (session.isQuizRevisionSession && session.documentId != null) {
      return session.hasSavedQuiz ? 'Ouvrir le quiz' : 'Generer un quiz';
    }
    return null;
  }

  VoidCallback? _primaryAction(
    PlanningSessionModel session,
    PlanningNotifier planningNotifier,
  ) {
    if (session.isFlashcardReviewSession && session.documentId != null) {
      return _flashcardAction(session, planningNotifier);
    }
    if (session.isQuizRevisionSession && session.documentId != null) {
      return _quizAction(session, planningNotifier);
    }
    return null;
  }

  VoidCallback? _sessionTapAction(
    PlanningSessionModel session,
    PlanningNotifier planningNotifier,
  ) {
    if (session.isFlashcardReviewSession) {
      return _flashcardAction(session, planningNotifier);
    }
    if (session.isQuizRevisionSession) {
      return _quizAction(session, planningNotifier);
    }
    return null;
  }

  String _quizActionLabel(PlanningSessionModel session) {
    switch (session.sessionQuizStatus) {
      case 'completed':
        return 'Voir quiz';
      case 'in_progress':
        return 'Continuer quiz';
      default:
        return 'Generer quiz';
    }
  }

  String _flashcardActionLabel(PlanningSessionModel session) {
    switch (session.sessionFlashcardsStatus) {
      case 'completed':
        return 'Voir cartes';
      case 'in_progress':
        return 'Continuer cartes';
      case 'generated':
        return 'Ouvrir cartes';
      default:
        return 'Generer cartes';
    }
  }

  Color _quizActionColor(PlanningSessionModel session) {
    switch (session.sessionQuizStatus) {
      case 'completed':
        return const Color(0xFF4ADE80);
      case 'in_progress':
        return const Color(0xFFFFC857);
      default:
        return const Color(0xFF97CAD8);
    }
  }

  Color _flashcardActionColor(PlanningSessionModel session) {
    switch (session.sessionFlashcardsStatus) {
      case 'completed':
        return const Color(0xFF4ADE80);
      case 'in_progress':
        return const Color(0xFFFFC857);
      case 'generated':
        return const Color(0xFF8BD3A8);
      default:
        return const Color(0xFF97CAD8);
    }
  }

  IconData _quizActionIcon(PlanningSessionModel session) {
    switch (session.sessionQuizStatus) {
      case 'completed':
        return Icons.fact_check_outlined;
      case 'in_progress':
        return Icons.play_circle_outline;
      default:
        return Icons.quiz_outlined;
    }
  }

  IconData _flashcardActionIcon(PlanningSessionModel session) {
    switch (session.sessionFlashcardsStatus) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.refresh_outlined;
      case 'generated':
        return Icons.style_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  VoidCallback? _quizAction(
    PlanningSessionModel session,
    PlanningNotifier planningNotifier,
  ) {
    if (!session.isCompleted) {
      return null;
    }
    if (session.sessionQuizId != null) {
      return () {
        _openRouteAndRefresh(
          AppRoutes.quizPlay(session.sessionQuizId!),
          planningNotifier,
        );
      };
    }
    if (session.hasLinkedDocument) {
      return () {
        _openRouteAndRefresh(
          AppRoutes.quizGenerateSession(session.id, title: session.subject),
          planningNotifier,
        );
      };
    }
    return null;
  }

  VoidCallback? _flashcardAction(
    PlanningSessionModel session,
    PlanningNotifier planningNotifier,
  ) {
    if (!session.isCompleted) {
      return null;
    }
    if (session.hasSavedFlashcards) {
      final route = session.sessionFlashcardsDue > 0
          ? AppRoutes.flashcardsReview(sessionId: session.id)
          : AppRoutes.flashcardsDeckSession(session.id);
      return () {
        _openRouteAndRefresh(route, planningNotifier);
      };
    }
    if (session.hasLinkedDocument) {
      return () {
        _openRouteAndRefresh(
          AppRoutes.flashcardsGenerateSession(session.id, title: session.subject),
          planningNotifier,
        );
      };
    }
    return null;
  }

  VoidCallback? _rescheduleAction(
    PlanningSessionModel session,
    PlanningNotifier planningNotifier,
  ) {
    if (!session.canBeRescheduled) {
      return null;
    }
    return () async {
      try {
        final newSession = await planningNotifier.rescheduleSession(session.id);
        if (!context.mounted) return;
        _showSnackBar(
          context,
          'Session replanifiee pour ${_formatRescheduledSlot(newSession)}.',
        );
      } catch (e) {
        if (!context.mounted) return;
        _showSnackBar(context, e.toString(), isError: true);
      }
    };
  }

  void _openRouteAndRefresh(String route, PlanningNotifier planningNotifier) {
    context.push(route).then((_) {
      planningNotifier.refresh();
    });
  }

  String _formatRescheduledSlot(PlanningSessionModel session) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(session.start.year, session.start.month, session.start.day);
    final dayLabel = sessionDay == today ? 'aujourd hui' : _headerTitle(session.start);
    return '$dayLabel a ${_formatTime(session.start)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${duration.inMinutes}min';
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }
}

class _PlanningFeedbackCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _PlanningFeedbackCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FrostedGlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.14),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveSchedulingNotice extends StatelessWidget {
  const _AdaptiveSchedulingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: Color(0xFFD8B4FE),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Revisions IA adaptees a vos heures les plus fiables.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoBanner extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String message;

  const _DialogInfoBanner({
    required this.icon,
    required this.accent,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.black.withOpacity(0.72),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPickerSection extends StatelessWidget {
  final AsyncValue<List<DocumentInfo>> docsState;
  final int? selectedDocumentId;
  final String label;
  final ValueChanged<int?> onChanged;
  final Future<void> Function() onUpload;

  const _DocumentPickerSection({
    required this.docsState,
    required this.selectedDocumentId,
    required this.label,
    required this.onChanged,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        docsState.when(
          data: (docs) {
            final items = <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Sans document'),
              ),
              ...docs.map(
                (doc) => DropdownMenuItem<int?>(
                  value: doc.id,
                  child: Text(
                    doc.filename,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ];

            return DropdownButtonFormField<int?>(
              value: selectedDocumentId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              items: items,
              onChanged: onChanged,
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Text(
            'Documents indisponibles: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Uploader un document'),
          ),
        ),
      ],
    );
  }
}
