import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/profile_avatar.dart';
import '../providers/user_profile_provider.dart';

class CurrentUserAvatar extends ConsumerWidget {
  const CurrentUserAvatar({
    Key? key,
    this.radius = 20,
    this.fallbackName = 'User',
  }) : super(key: key);

  final double radius;
  final String fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    return ProfileAvatar(
      name: profile?.fullName ?? fallbackName,
      imageDataUrl: profile?.avatarDataUrl,
      radius: radius,
    );
  }
}
