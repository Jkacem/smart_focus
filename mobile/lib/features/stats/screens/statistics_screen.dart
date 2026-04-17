import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/features/flashcards/data/flashcard_repository.dart';
import 'package:smart_focus/features/flashcards/models/flashcard_models.dart';
import 'package:smart_focus/features/planning/data/planning_repository.dart';
import 'package:smart_focus/features/planning/models/planning_models.dart';
import 'package:smart_focus/features/planning/providers/planning_provider.dart';
import 'package:smart_focus/features/quiz/data/quiz_repository.dart';
import 'package:smart_focus/features/quiz/models/quiz_models.dart';
import 'package:smart_focus/features/sleep/services/sleep_service.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../widgets/focus_chart_card.dart';
import '../widgets/general_score_card.dart';
import '../widgets/planning_insights_card.dart';
import '../widgets/sleep_chart_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  static const _savedStatsKey = 'saved_stats_bundles_v1';

  int _selectedIndex = 3;
  String _selectedPeriod = 'week';
  bool _isSavingStatsBundle = false;
  bool _isExportingPdf = false;
  bool _isLoadingSavedBundles = true;
  List<Map<String, dynamic>> _savedStatsBundles = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedStatsBundles();
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
    final insightsAsync = ref.watch(planningInsightsProvider(_selectedPeriod));

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const CustomAppBar(
        title: 'Statistiques',
        trailingIcon: Icons.date_range,
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
            child: RefreshIndicator(
              color: Colors.black,
              onRefresh: () async {
                ref.invalidate(planningInsightsProvider(_selectedPeriod));
                await ref.read(planningInsightsProvider(_selectedPeriod).future);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  _buildPeriodFilter(),
                  const SizedBox(height: 24),
                  insightsAsync.when(
                    loading: () => _buildInsightsLoadingCard(),
                    error: (error, stackTrace) => _buildInsightsErrorCard(error),
                    data: (insights) => PlanningInsightsCard(insights: insights),
                  ),
                  const SizedBox(height: 24),
                  const GeneralScoreCard(),
                  const SizedBox(height: 24),
                  const FocusChartCard(),
                  const SizedBox(height: 24),
                  const SleepChartCard(),
                  const SizedBox(height: 24),
                  _buildSaveStatsBundleButton(),
                  const SizedBox(height: 10),
                  _buildExportPdfButton(),
                  const SizedBox(height: 12),
                  _buildLastSavedBundleCard(),
                  const SizedBox(height: 100),
                ],
              ),
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

  Widget _buildPeriodFilter() {
    const periods = {
      'week': 'Semaine',
      'month': 'Mois',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: periods.entries.map((entry) {
        final isSelected = _selectedPeriod == entry.key;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = entry.key;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF97cad8)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightsLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF97cad8)),
      ),
    );
  }

  Widget _buildInsightsErrorCard(Object error) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFB7185).withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights indisponibles',
            style: TextStyle(
              color: Color(0xFFFB7185),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(planningInsightsProvider(_selectedPeriod));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveStatsBundleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSavingStatsBundle ? null : _saveStatsBundle,
        icon: _isSavingStatsBundle
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0A1628),
                ),
              )
            : const Icon(Icons.save_alt_rounded),
        label: Text(
          _isSavingStatsBundle
              ? 'Sauvegarde en cours...'
              : 'Sauvegarder bilan semaine + mois',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF0A1628),
          backgroundColor: const Color(0xFF97CAD8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildExportPdfButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isExportingPdf ? null : _exportStatsPdf,
        icon: _isExportingPdf
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          _isExportingPdf ? 'Preparation du PDF...' : 'Telecharger le PDF',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.35), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLastSavedBundleCard() {
    if (_isLoadingSavedBundles) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Chargement des bilans sauvegardes...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_savedStatsBundles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          'Aucun bilan sauvegarde pour le moment.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 13,
          ),
        ),
      );
    }

    final latest = _savedStatsBundles.first;
    final savedAt = _parseDateTime(latest['saved_at']);
    final week = _asMap(latest['week']);
    final month = _asMap(latest['month']);
    final weekMinutes = _asInt(_asMap(week['focus'])['studied_minutes']);
    final monthMinutes = _asInt(_asMap(month['focus'])['studied_minutes']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF97CAD8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dernier bilan: ${_formatDateTime(savedAt)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Etude sauvegardee - semaine: ${_formatMinutes(weekMinutes)} | mois: ${_formatMinutes(monthMinutes)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showSavedBundleDetails(latest),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF97CAD8),
            ),
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSavedStatsBundles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getStringList(_savedStatsKey) ?? const [];
      final decoded = <Map<String, dynamic>>[];
      for (final item in encoded) {
        final parsed = jsonDecode(item);
        if (parsed is Map<String, dynamic>) {
          decoded.add(parsed);
        } else if (parsed is Map) {
          decoded.add(Map<String, dynamic>.from(parsed));
        }
      }
      if (!mounted) return;
      setState(() {
        _savedStatsBundles = decoded;
        _isLoadingSavedBundles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedStatsBundles = const [];
        _isLoadingSavedBundles = false;
      });
    }
  }

  Future<void> _saveStatsBundle() async {
    if (_isSavingStatsBundle) return;

    setState(() {
      _isSavingStatsBundle = true;
    });

    try {
      final bundle = await _buildStatsBundlePayload();
      await _persistStatsBundle(bundle);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bilan semaine + mois sauvegarde localement.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sauvegarde impossible: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingStatsBundle = false;
      });
    }
  }

  Future<void> _exportStatsPdf() async {
    if (_isExportingPdf) return;
    setState(() {
      _isExportingPdf = true;
    });

    try {
      final bundle = await _buildStatsBundlePayload();
      await _persistStatsBundle(bundle);
      final bytes = await _buildStatsPdfBytes(bundle);
      final fileStamp = _fileStamp(DateTime.now());

      await Printing.layoutPdf(
        name: 'smartfocus_stats_$fileStamp.pdf',
        onLayout: (format) async => bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF pret. Utilisez le dialogue pour enregistrer/télécharger.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export PDF impossible: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExportingPdf = false;
      });
    }
  }

  Future<Map<String, dynamic>> _buildStatsBundlePayload() async {
    final quizRepository = ref.read(quizRepositoryProvider);
    final flashcardRepository = ref.read(flashcardRepositoryProvider);

    final allQuizzes = await quizRepository.getQuizzes();
    final dueCards = await flashcardRepository.getDueCards();

    final weekReport = await _buildPeriodReport(
      period: 'week',
      allQuizzes: allQuizzes,
      dueCards: dueCards,
    );
    final monthReport = await _buildPeriodReport(
      period: 'month',
      allQuizzes: allQuizzes,
      dueCards: dueCards,
    );

    final now = DateTime.now();
    return <String, dynamic>{
      'id': now.millisecondsSinceEpoch.toString(),
      'saved_at': now.toIso8601String(),
      'week': weekReport,
      'month': monthReport,
    };
  }

  Future<Uint8List> _buildStatsPdfBytes(Map<String, dynamic> bundle) async {
    final pdf = pw.Document();
    final week = _asMap(bundle['week']);
    final month = _asMap(bundle['month']);
    final savedAt = _formatDateTime(_parseDateTime(bundle['saved_at']));

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          _pdfHeader(savedAt),
          pw.SizedBox(height: 14),
          _pdfQuickKpis(week: week, month: month),
          pw.SizedBox(height: 16),
          _pdfComparisonSection(week: week, month: month),
          pw.SizedBox(height: 16),
          _pdfPeriodSection(week),
          pw.SizedBox(height: 12),
          _pdfPeriodSection(month),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfHeader(String savedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E8F2F5'),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SmartFocus - Bilan de progression',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A1628'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Genere le $savedAt',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromHex('#38536B'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfQuickKpis({
    required Map<String, dynamic> week,
    required Map<String, dynamic> month,
  }) {
    final weekFocus = _asMap(week['focus']);
    final monthFocus = _asMap(month['focus']);
    final weekSleep = _asMap(week['sleep']);
    final monthSleep = _asMap(month['sleep']);
    final weekQuiz = _asMap(week['quizzes']);
    final monthQuiz = _asMap(month['quizzes']);

    return pw.Row(
      children: [
        _pdfKpiCard(
          title: 'Etude',
          weekValue: _formatMinutes(_asInt(weekFocus['studied_minutes'])),
          monthValue: _formatMinutes(_asInt(monthFocus['studied_minutes'])),
        ),
        pw.SizedBox(width: 10),
        _pdfKpiCard(
          title: 'Sommeil',
          weekValue: '${(_asDouble(weekSleep['avg_hours']) ?? 0).toStringAsFixed(1)} h',
          monthValue: '${(_asDouble(monthSleep['avg_hours']) ?? 0).toStringAsFixed(1)} h',
        ),
        pw.SizedBox(width: 10),
        _pdfKpiCard(
          title: 'Quiz',
          weekValue: '${_asInt(weekQuiz['completed'])} completes',
          monthValue: '${_asInt(monthQuiz['completed'])} completes',
        ),
      ],
    );
  }

  pw.Widget _pdfKpiCard({
    required String title,
    required String weekValue,
    required String monthValue,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex('#C7D7E2')),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#17304A'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Semaine: $weekValue', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 2),
            pw.Text('Mois: $monthValue', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfComparisonSection({
    required Map<String, dynamic> week,
    required Map<String, dynamic> month,
  }) {
    final weekFocus = _asMap(week['focus']);
    final monthFocus = _asMap(month['focus']);
    final weekSleep = _asMap(week['sleep']);
    final monthSleep = _asMap(month['sleep']);
    final weekQuiz = _asMap(week['quizzes']);
    final monthQuiz = _asMap(month['quizzes']);
    final weekFlashcards = _asMap(week['flashcards']);
    final monthFlashcards = _asMap(month['flashcards']);

    final focusWeek = _asInt(weekFocus['studied_minutes']).toDouble();
    final focusMonth = _asInt(monthFocus['studied_minutes']).toDouble();
    final focusMax = (focusWeek > focusMonth ? focusWeek : focusMonth).clamp(1, 1000000);

    final flashWeek = _asInt(weekFlashcards['reviewed_from_sessions']).toDouble();
    final flashMonth = _asInt(monthFlashcards['reviewed_from_sessions']).toDouble();
    final flashMax = (flashWeek > flashMonth ? flashWeek : flashMonth).clamp(1, 1000000);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#C7D7E2')),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Comparaison visuelle (rapide)',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#17304A'),
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfComparisonBar(
            label: 'Focus (minutes etudiees)',
            weekValue: focusWeek,
            monthValue: focusMonth,
            max: focusMax.toDouble(),
          ),
          pw.SizedBox(height: 8),
          _pdfComparisonBar(
            label: 'Completion sessions (%)',
            weekValue: _asInt(weekFocus['completion_rate_percent']).toDouble(),
            monthValue: _asInt(monthFocus['completion_rate_percent']).toDouble(),
            max: 100,
          ),
          pw.SizedBox(height: 8),
          _pdfComparisonBar(
            label: 'Sommeil moyen (h)',
            weekValue: _asDouble(weekSleep['avg_hours']) ?? 0,
            monthValue: _asDouble(monthSleep['avg_hours']) ?? 0,
            max: 10,
          ),
          pw.SizedBox(height: 8),
          _pdfComparisonBar(
            label: 'Score quiz moyen (%)',
            weekValue: _asDouble(weekQuiz['avg_score_percent']) ?? 0,
            monthValue: _asDouble(monthQuiz['avg_score_percent']) ?? 0,
            max: 100,
          ),
          pw.SizedBox(height: 8),
          _pdfComparisonBar(
            label: 'Flashcards revisees',
            weekValue: flashWeek,
            monthValue: flashMonth,
            max: flashMax.toDouble(),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfComparisonBar({
    required String label,
    required double weekValue,
    required double monthValue,
    required double max,
  }) {
    final safeMax = max <= 0 ? 1.0 : max;
    final weekRatio = (weekValue / safeMax).clamp(0.0, 1.0);
    final monthRatio = (monthValue / safeMax).clamp(0.0, 1.0);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 4),
        _pdfSingleBar(
          prefix: 'Semaine',
          ratio: weekRatio,
          valueLabel: _formatPdfNumber(weekValue),
          colorHex: '#2B6CB0',
        ),
        pw.SizedBox(height: 3),
        _pdfSingleBar(
          prefix: 'Mois',
          ratio: monthRatio,
          valueLabel: _formatPdfNumber(monthValue),
          colorHex: '#1F8A70',
        ),
      ],
    );
  }

  pw.Widget _pdfSingleBar({
    required String prefix,
    required double ratio,
    required String valueLabel,
    required String colorHex,
  }) {
    final normalizedRatio = ratio.clamp(0.0, 1.0);
    var filledFlex = (normalizedRatio * 1000).round();
    if (normalizedRatio > 0 && filledFlex == 0) {
      filledFlex = 1;
    }
    if (filledFlex > 1000) {
      filledFlex = 1000;
    }
    final emptyFlex = 1000 - filledFlex;

    return pw.Row(
      children: [
        pw.SizedBox(
          width: 52,
          child: pw.Text(prefix, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Expanded(
          child: pw.Container(
            height: 10,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E9EEF2'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                if (filledFlex > 0)
                  pw.Expanded(
                    flex: filledFlex,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex(colorHex),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (emptyFlex > 0)
                  pw.Expanded(
                    flex: emptyFlex,
                    child: pw.SizedBox(),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(valueLabel, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _pdfPeriodSection(Map<String, dynamic> periodData) {
    final label = periodData['label']?.toString() ?? 'Periode';
    final focus = _asMap(periodData['focus']);
    final sleep = _asMap(periodData['sleep']);
    final sessions = _asMap(periodData['sessions']);
    final quizzes = _asMap(periodData['quizzes']);
    final flashcards = _asMap(periodData['flashcards']);
    final recommendation = periodData['recommendation']?.toString() ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#C7D7E2')),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Details - $label',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#17304A'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Focus: ${_formatMinutes(_asInt(focus['studied_minutes']))} | completion ${_asInt(focus['completion_rate_percent'])}%',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Sommeil: ${(_asDouble(sleep['avg_hours']) ?? 0).toStringAsFixed(1)} h | score ${_asDouble(sleep['avg_score'])?.toStringAsFixed(1) ?? '--'}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Sessions: ${_asInt(sessions['completed'])} terminees / ${_asInt(sessions['total'])}, manquees ${_asInt(sessions['missed'])}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Quiz: ${_asInt(quizzes['completed'])} completes, moyenne ${_asDouble(quizzes['avg_score_percent'])?.toStringAsFixed(1) ?? '--'}%',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Flashcards: ${_asInt(flashcards['reviewed_from_sessions'])} revisees, dues maintenant ${_asInt(flashcards['due_now'])}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (recommendation.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Recommendation: $recommendation', style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  String _formatPdfNumber(double value) {
    final roundedInt = value.roundToDouble();
    if (roundedInt == value) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _fileStamp(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}$month${day}_$hour$minute';
  }

  Future<void> _persistStatsBundle(Map<String, dynamic> bundle) async {
    final prefs = await SharedPreferences.getInstance();
    final next = [bundle, ..._savedStatsBundles].take(20).toList();
    final encoded = next.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_savedStatsKey, encoded);

    if (!mounted) return;
    setState(() {
      _savedStatsBundles = next;
    });
  }

  Future<Map<String, dynamic>> _buildPeriodReport({
    required String period,
    required List<QuizModel> allQuizzes,
    required List<FlashcardModel> dueCards,
  }) async {
    final planningRepository = ref.read(planningRepositoryProvider);
    final sleepService = ref.read(sleepServiceProvider);
    final range = _rangeForPeriod(period);

    final insights = await planningRepository.getInsights(period: period);
    final sleepStats = await sleepService.getStats(period: period);
    final sessions = await _loadSessionsInRange(
      planningRepository: planningRepository,
      start: range.start,
      end: range.end,
      days: range.days,
    );

    final sessionSummary = _buildSessionSummary(sessions);
    final quizSummary = _buildQuizSummary(allQuizzes, start: range.start, end: range.end);
    final notes = _collectSessionNotes(sessions);
    final focus = _buildFocusSummary(insights, sessionSummary);
    final sleep = _buildSleepSummary(sleepStats);
    final flashcards = _buildFlashcardSummary(
      dueCards: dueCards,
      sessions: sessions,
      start: range.start,
      end: range.end,
    );

    return <String, dynamic>{
      'period': period,
      'label': _periodLabel(period),
      'range_start': range.start.toIso8601String(),
      'range_end': range.end.toIso8601String(),
      'focus': focus,
      'sleep': sleep,
      'sessions': sessionSummary,
      'quizzes': quizSummary,
      'flashcards': flashcards,
      'subjects': {
        'weakest': insights.weakestSubject,
        'strongest': insights.strongestSubject,
        'top_completed': sessionSummary['top_completed_subjects'],
      },
      'recommendation': insights.recommendation,
      'notes': notes,
    };
  }

  Future<List<PlanningSessionModel>> _loadSessionsInRange({
    required PlanningRepository planningRepository,
    required DateTime start,
    required DateTime end,
    required int days,
  }) async {
    final requests = <Future<PlanningDayModel?>>[];
    for (var i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      requests.add(() async {
        try {
          return await planningRepository.getDay(day);
        } catch (_) {
          return null;
        }
      }());
    }

    final dayResults = await Future.wait(requests);
    final sessions = <PlanningSessionModel>[];
    for (final day in dayResults) {
      if (day == null) continue;
      sessions.addAll(day.sessions);
    }

    return sessions.where((session) {
      final startAt = session.start;
      return !startAt.isBefore(start) && !startAt.isAfter(end);
    }).toList();
  }

  Map<String, dynamic> _buildFocusSummary(
    PlanningInsightsModel insights,
    Map<String, dynamic> sessionSummary,
  ) {
    return <String, dynamic>{
      'studied_minutes': insights.totalStudyMinutes,
      'completion_rate_percent': insights.completionRatePercent,
      'completed_sessions': insights.completedSessions,
      'skipped_sessions': insights.skippedSessions,
      'tracked_sessions': insights.trackedSessions,
      'planned_minutes': _asInt(sessionSummary['planned_minutes']),
    };
  }

  Map<String, dynamic> _buildSleepSummary(dynamic sleepStats) {
    return <String, dynamic>{
      'avg_hours': sleepStats.avgHours,
      'avg_score': sleepStats.scoreAvg,
      'trend': sleepStats.trend,
      'records': sleepStats.numRecords,
    };
  }

  Map<String, dynamic> _buildSessionSummary(List<PlanningSessionModel> sessions) {
    final completed = sessions.where((s) => s.isCompleted).toList();
    final cancelledCount = sessions.where((s) => s.isCancelled).length;
    final missedCount = sessions.where((s) => s.isMissed).length;
    final pendingCount = sessions
        .where((s) => !s.isCompleted && !s.isCancelled && !s.isMissed)
        .length;

    final plannedMinutes = sessions.fold<int>(0, (sum, s) => sum + s.duration.inMinutes);
    final completedMinutes = completed.fold<int>(0, (sum, s) => sum + s.duration.inMinutes);

    final flashcardsTotal = sessions.fold<int>(0, (sum, s) => sum + s.sessionFlashcardsTotal);
    final flashcardsDue = sessions.fold<int>(0, (sum, s) => sum + s.sessionFlashcardsDue);
    final flashcardsReviewed = sessions.fold<int>(
      0,
      (sum, s) => sum + s.sessionFlashcardsReviewed,
    );
    final quizCompletedCount = sessions.where((s) => s.quizCompleted).length;
    final quizStartedCount = sessions.where((s) => s.quizStarted).length;

    final completedBySubject = <String, int>{};
    for (final session in completed) {
      final subject = session.subject.trim();
      if (subject.isEmpty) continue;
      completedBySubject[subject] = (completedBySubject[subject] ?? 0) + 1;
    }
    final topSubjects = completedBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return <String, dynamic>{
      'total': sessions.length,
      'completed': completed.length,
      'cancelled': cancelledCount,
      'missed': missedCount,
      'pending': pendingCount,
      'planned_minutes': plannedMinutes,
      'completed_minutes': completedMinutes,
      'flashcards_total': flashcardsTotal,
      'flashcards_due': flashcardsDue,
      'flashcards_reviewed': flashcardsReviewed,
      'session_quiz_started': quizStartedCount,
      'session_quiz_completed': quizCompletedCount,
      'top_completed_subjects': topSubjects
          .take(5)
          .map((entry) => <String, dynamic>{'subject': entry.key, 'count': entry.value})
          .toList(),
    };
  }

  Map<String, dynamic> _buildQuizSummary(
    List<QuizModel> quizzes, {
    required DateTime start,
    required DateTime end,
  }) {
    final created = quizzes.where((q) => _isWithinRange(q.createdAt, start: start, end: end));
    final completed = quizzes.where(
      (q) => q.completedAt != null && _isWithinRange(q.completedAt!, start: start, end: end),
    );
    final completedList = completed.toList();

    double? avgScorePercent;
    if (completedList.isNotEmpty) {
      final validPercentages = completedList
          .where((q) => q.numQuestions > 0 && q.score != null)
          .map((q) => (q.score! / q.numQuestions) * 100)
          .toList();
      if (validPercentages.isNotEmpty) {
        final sum = validPercentages.reduce((a, b) => a + b);
        avgScorePercent = sum / validPercentages.length;
      }
    }

    final lowScoreCount = completedList
        .where((q) => q.numQuestions > 0 && q.score != null && (q.score! / q.numQuestions) < 0.6)
        .length;

    return <String, dynamic>{
      'created': created.length,
      'completed': completedList.length,
      'avg_score_percent': avgScorePercent,
      'low_score_count': lowScoreCount,
    };
  }

  Map<String, dynamic> _buildFlashcardSummary({
    required List<FlashcardModel> dueCards,
    required List<PlanningSessionModel> sessions,
    required DateTime start,
    required DateTime end,
  }) {
    final dueCreatedInRange = dueCards
        .where((card) => _isWithinRange(card.createdAt, start: start, end: end))
        .length;
    final reviewedFromSessions = sessions.fold<int>(
      0,
      (sum, session) => sum + session.sessionFlashcardsReviewed,
    );
    final generatedFromSessions = sessions.fold<int>(
      0,
      (sum, session) => sum + session.sessionFlashcardsTotal,
    );

    return <String, dynamic>{
      'due_now': dueCards.length,
      'due_cards_created_in_period': dueCreatedInRange,
      'generated_from_sessions': generatedFromSessions,
      'reviewed_from_sessions': reviewedFromSessions,
    };
  }

  List<String> _collectSessionNotes(List<PlanningSessionModel> sessions) {
    final notes = <String>[];
    for (final session in sessions) {
      final note = session.notes?.trim();
      if (note == null || note.isEmpty) {
        continue;
      }
      if (!notes.contains(note)) {
        notes.add(note);
      }
    }
    return notes.take(10).toList();
  }

  _DateRange _rangeForPeriod(String period) {
    final days = period == 'month' ? 30 : 7;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start = todayStart.subtract(Duration(days: days - 1));
    return _DateRange(start: start, end: now, days: days);
  }

  bool _isWithinRange(
    DateTime value, {
    required DateTime start,
    required DateTime end,
  }) {
    return !value.isBefore(start) && !value.isAfter(end);
  }

  String _periodLabel(String period) {
    return period == 'month' ? 'Mois' : 'Semaine';
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}min';
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  void _showSavedBundleDetails(Map<String, dynamic> bundle) {
    final week = _asMap(bundle['week']);
    final month = _asMap(bundle['month']);
    final savedAt = _formatDateTime(_parseDateTime(bundle['saved_at']));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF102235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bilan sauvegarde',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sauvegarde: $savedAt',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSavedPeriodSection(week),
                  const SizedBox(height: 14),
                  _buildSavedPeriodSection(month),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedPeriodSection(Map<String, dynamic> periodData) {
    final label = periodData['label']?.toString() ?? 'Periode';
    final focus = _asMap(periodData['focus']);
    final sleep = _asMap(periodData['sleep']);
    final sessions = _asMap(periodData['sessions']);
    final quizzes = _asMap(periodData['quizzes']);
    final flashcards = _asMap(periodData['flashcards']);
    final recommendation = periodData['recommendation']?.toString() ?? '';
    final notes = (periodData['notes'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF97CAD8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Focus: ${_formatMinutes(_asInt(focus['studied_minutes']))} etudiees | completion ${_asInt(focus['completion_rate_percent'])}%',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Sommeil: ${(_asDouble(sleep['avg_hours']) ?? 0).toStringAsFixed(1)} h | score ${_asDouble(sleep['avg_score'])?.toStringAsFixed(1) ?? '--'}',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Sessions: ${_asInt(sessions['completed'])} terminees / ${_asInt(sessions['total'])}',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Quiz: ${_asInt(quizzes['completed'])} completes | score moyen ${_asDouble(quizzes['avg_score_percent'])?.toStringAsFixed(1) ?? '--'}%',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Flashcards: ${_asInt(flashcards['reviewed_from_sessions'])} revisees | ${_asInt(flashcards['due_now'])} dues maintenant',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reco: $recommendation',
              style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${notes.join(' | ')}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  final int days;

  const _DateRange({
    required this.start,
    required this.end,
    required this.days,
  });
}
