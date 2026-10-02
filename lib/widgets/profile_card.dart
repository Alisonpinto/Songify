import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';

import '../theme.dart';

class ProfileCard extends StatelessWidget {
  final Color color;
  final String username;
  final String userHandle;
  final String avatarSeed;
  final String? userProfileImage;
  final bool loggedIn;

  final void Function()? onAvatarPressed;
  final void Function()? onEditProfile;

  const ProfileCard({
    super.key,
    required this.color,
    required this.username,
    required this.userHandle,
    required this.avatarSeed,
    required this.userProfileImage,
    required this.loggedIn,
    this.onAvatarPressed,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        _Avatar(color: color, avatarSeed: avatarSeed, profileUrl: userProfileImage, onPressed: onAvatarPressed),
        const SizedBox(height: 20),
        Row(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              username,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            if (loggedIn)
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 16, color: color),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.1))),
                visualDensity: VisualDensity.compact,
                onPressed: onEditProfile,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.05),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              userHandle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final Color color;
  final String? profileUrl;
  final String? avatarSeed;
  final void Function()? onPressed;

  const _Avatar({super.key, required this.color, this.profileUrl, this.avatarSeed, this.onPressed});

  @override
  Widget build(BuildContext context) {
    DecorationImage? image;
    if (profileUrl != null) image = DecorationImage(image: NetworkImage(profileUrl!), fit: BoxFit.cover);

    Widget? avatar;
    if (avatarSeed != null) avatar = ClipOval(child: RandomAvatar(avatarSeed!, trBackground: false));

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.darkCard,
          border: Border.all(color: color, width: 4),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 4)],
          image: image,
        ),
        child: avatar,
      ),
    );
  }
}
