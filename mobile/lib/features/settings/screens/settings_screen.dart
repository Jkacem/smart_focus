import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/features/auth/models/current_user_profile.dart';
import 'package:smart_focus/features/auth/providers/auth_provider.dart';
import 'package:smart_focus/features/auth/providers/user_profile_provider.dart';
import 'package:smart_focus/features/chatbot/providers/chat_provider.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Set<String> _allowedRoles = {
    'student',
    'teacher',
    'professional',
  };
  static const Set<String> _allowedSchedules = {
    'morning',
    'afternoon',
    'evening',
  };

  final TextEditingController _fullNameController = TextEditingController();

  int _selectedIndex = 5;
  String? _seededProfileSignature;
  double _focusGoal = 120;
  bool _notificationsEnabled = true;
  bool _focusAlerts = true;
  bool _sleepReminders = true;
  String _preferredSchedule = 'morning';
  String _selectedRole = 'student';
  String? _avatarDataUrl;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
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

  void _seedForm(CurrentUserProfile profile) {
    _fullNameController.text = profile.fullName;
    _focusGoal = profile.dailyFocusGoal.toDouble();
    _notificationsEnabled = profile.notifEnabled;
    _focusAlerts = profile.focusAlertsEnabled;
    _sleepReminders = profile.sleepRemindersEnabled;
    _preferredSchedule = _normalizeSchedule(profile.preferredSchedule);
    _selectedRole = _normalizeRole(profile.role);
    _avatarDataUrl = profile.avatarDataUrl;
    _seededProfileSignature = _profileSignature(profile);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    if (profile != null &&
        _seededProfileSignature != _profileSignature(profile)) {
      _seedForm(profile);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const CustomAppBar(
        title: 'Parametres',
        trailingIcon: Icons.settings,
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
              onRefresh: () => ref.read(userProfileProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  if (profileState.isLoading && profile == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (profile == null)
                    _buildErrorState(profileState.errorMessage)
                  else ...[
                    _buildProfileCard(profile),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Compte'),
                    const SizedBox(height: 8),
                    _buildAccountCard(profile),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Preferences d etude'),
                    const SizedBox(height: 8),
                    _buildPreferencesCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notifications'),
                    const SizedBox(height: 8),
                    _buildNotificationsCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(profileState),
                    const SizedBox(height: 16),
                    _buildDisconnectButton(),
                    const SizedBox(height: 100),
                  ],
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

  Widget _buildErrorState(String? message) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil indisponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'Impossible de charger vos parametres.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.read(userProfileProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF97CAD8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileCard(CurrentUserProfile profile) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ProfileAvatar(
            name: _fullNameController.text.isEmpty
                ? profile.fullName
                : _fullNameController.text,
            imageDataUrl: _avatarDataUrl,
            radius: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullNameController.text.isEmpty
                      ? profile.fullName
                      : _fullNameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _roleLabel(_selectedRole),
                    style: const TextStyle(
                      color: Color(0xFF97CAD8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(CurrentUserProfile profile) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                name: _fullNameController.text.isEmpty
                    ? profile.fullName
                    : _fullNameController.text,
                imageDataUrl: _avatarDataUrl,
                radius: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Changer la photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.22)),
                      ),
                    ),
                    if ((_avatarDataUrl ?? '').isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _avatarDataUrl = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Retirer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _fullNameController,
            label: 'Nom complet',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _buildReadOnlyField(
            label: 'Email',
            value: profile.email,
            icon: Icons.mail_outline,
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Role',
            value: _selectedRole,
            icon: Icons.badge_outlined,
            items: const {
              'student': 'Etudiant',
              'teacher': 'Enseignant',
              'professional': 'Professionnel',
            },
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedRole = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFF97CAD8)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Objectif de focus quotidien',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_focusGoal.round()} min',
                style: const TextStyle(
                  color: Color(0xFF97CAD8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _focusGoal,
            min: 30,
            max: 300,
            divisions: 27,
            activeColor: const Color(0xFF97CAD8),
            inactiveColor: Colors.white24,
            onChanged: (value) {
              setState(() {
                _focusGoal = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildDropdownField(
            label: 'Horaire prefere',
            value: _preferredSchedule,
            icon: Icons.schedule,
            items: const {
              'morning': 'Matin',
              'afternoon': 'Apres-midi',
              'evening': 'Soir',
            },
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _preferredSchedule = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildSwitchRow(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications actives',
            subtitle: 'Active ou coupe toutes les alertes de l app.',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 24),
          _buildSwitchRow(
            icon: Icons.bolt_outlined,
            title: 'Alertes focus',
            subtitle: 'Rappels quand le temps de concentration baisse.',
            value: _focusAlerts,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _focusAlerts = value)
                : null,
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 24),
          _buildSwitchRow(
            icon: Icons.nightlight_round,
            title: 'Rappels sommeil',
            subtitle: 'Messages pour garder un rythme de sommeil regulier.',
            value: _sleepReminders,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _sleepReminders = value)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(UserProfileState profileState) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: profileState.isSaving ? null : _saveProfile,
        icon: profileState.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0A1628),
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(
          profileState.isSaving ? 'Enregistrement...' : 'Enregistrer',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: () async {
          ref.invalidate(chatProvider);
          ref.read(userProfileProvider.notifier).clear();
          await ref.read(authProvider.notifier).logout();
          if (mounted) context.go(AppRoutes.welcome);
        },
        icon: const Icon(Icons.exit_to_app),
        label: const Text(
          'Se deconnecter',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.redAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF97CAD8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF97CAD8)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF97CAD8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.containsKey(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      dropdownColor: const Color(0xFF17304A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF97CAD8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF97CAD8)),
        ),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF97CAD8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF97CAD8),
        ),
      ],
    );
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez une image plus petite que 2 MB.'),
        ),
      );
      return;
    }

    final extension = (file.extension ?? '').toLowerCase();
    final mimeType = _mimeTypeForExtension(extension);
    final encoded = base64Encode(bytes);

    setState(() {
      _avatarDataUrl = 'data:$mimeType;base64,$encoded';
    });
  }

  String _mimeTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom complet est obligatoire.')),
      );
      return;
    }

    try {
      await ref.read(userProfileProvider.notifier).updateProfile(
            CurrentUserProfileUpdateInput(
              fullName: fullName,
              role: _selectedRole,
              dailyFocusGoal: _focusGoal.round(),
              preferredSchedule: _preferredSchedule,
              avatarDataUrl: _avatarDataUrl,
              notifEnabled: _notificationsEnabled,
              focusAlerts: _focusAlerts,
              sleepReminders: _sleepReminders,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis a jour.')),
      );
    } catch (_) {
      final error = ref.read(userProfileProvider).errorMessage ??
          'Impossible d enregistrer vos modifications.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'teacher':
        return 'Enseignant';
      case 'professional':
        return 'Professionnel';
      default:
        return 'Etudiant';
    }
  }

  String _normalizeRole(String role) {
    if (_allowedRoles.contains(role)) {
      return role;
    }
    return 'student';
  }

  String _normalizeSchedule(String schedule) {
    if (_allowedSchedules.contains(schedule)) {
      return schedule;
    }
    return 'morning';
  }

  String _profileSignature(CurrentUserProfile profile) {
    final focusAlerts = profile.focusAlertsEnabled;
    final sleepReminders = profile.sleepRemindersEnabled;
    final avatar = profile.avatarDataUrl ?? '';
    return [
      profile.fullName,
      profile.role,
      '${profile.dailyFocusGoal}',
      profile.preferredSchedule,
      '${profile.notifEnabled}',
      '$focusAlerts',
      '$sleepReminders',
      avatar,
    ].join('|');
  }
}
