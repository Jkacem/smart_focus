import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_focus/features/chatbot/models/chatbot_models.dart';
import 'package:smart_focus/features/chatbot/providers/document_provider.dart';
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
  Timer? _autoUnvalidateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planningProvider.notifier).autoUnvalidateExpiredSessions();
    });
    _autoUnvalidateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      ref.read(planningProvider.notifier).autoUnvalidateExpiredSessions();
    });
  }

  @override
  void dispose() {
    _autoUnvalidateTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/planning');
    } else if (index == 2) {
      context.go('/chatbot');
    } else if (index == 3) {
      context.go('/statistics');
    } else if (index == 4) {
      context.go('/sleep');
    } else if (index == 5) {
      context.go('/settings');
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
                      decoration: const InputDecoration(
                        labelText: 'Type de semaine',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(value: null, child: Text('Auto')),
                        DropdownMenuItem(value: 'A', child: Text('Semaine A')),
                        DropdownMenuItem(value: 'B', child: Text('Semaine B')),
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
                          decoration: const InputDecoration(
                            labelText: 'Document source',
                            border: OutlineInputBorder(),
                          ),
                          items: items,
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
