import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:songify_flutter/dialogs/edit_profile_dialog.dart';
import 'package:songify_flutter/dialogs/logout_dialog.dart';
import 'package:songify_flutter/widgets/button/login_signup_button.dart';
import 'package:songify_flutter/widgets/button/logout_icon_button.dart';
import 'package:songify_flutter/widgets/music_stat_tile.dart';
import 'package:songify_flutter/widgets/premium_features_info.dart';
import 'package:songify_flutter/widgets/profile_card.dart';
import 'package:songify_flutter/widgets/settings_list_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/mini_player.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final glowColor = MiniPlayer.getTrackColor(state.currentTrack);

          return CustomScrollView(
            slivers: [
              SliverAppBar.medium(
                expandedHeight: 320,
                title: Text("Nice to see you"),
                pinned: true,
                backgroundColor: AppTheme.darkBackground,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cool blurred gradient background based on profile
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.0, -0.8),
                            radius: 1.2,
                            colors: [
                              glowColor.withValues(alpha: 0.25),
                              glowColor.withValues(alpha: 0.05),
                              AppTheme.darkBackground,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      // Bottom fade to remove any hard lines between header and body
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.darkBackground],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),

                      // Profile Info
                      ProfileCard(
                        color: glowColor,
                        username: state.userName,
                        userHandle: state.userHandle,
                        avatarSeed: state.currentAvatarSeed,
                        userProfileImage: state.userProfileImage,
                        loggedIn: state.isLoggedIn,
                        onAvatarPressed: state.userProfileImage == null ? () => _onAvatarPressed(state) : null,
                        onEditProfile: () => _showEditProfileDialog(context, state, glowColor),
                      ),
                    ],
                  ),
                ),
                actions: [if (state.isLoggedIn) LogoutIconButton(onPressed: () => _onLogout(context))],
              ),

              // Body
              SliverToBoxAdapter(
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: state.isLoggedIn
                        ? _buildLoggedInContent(context, state, glowColor)
                        : _buildGuestContent(context, glowColor),
                  ),
                ),
              ),

              // Some padding at the bottom for the mini player
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context, AppState state, Color glowColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title("Your Music Stats"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MusicStatTile(
                icon: Icon(Icons.album_rounded),
                title: Text(state.albumNames.length.toString()),
                subtitle: Text('Playlists'),
                color: glowColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MusicStatTile(
                icon: Icon(Icons.music_note_rounded),
                title: Text(state.songsList.length.toString()),
                subtitle: Text('Songs'),
                color: glowColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const _Title("Settings"),
        const SizedBox(height: 16),
        SettingsListTile(
          icon: Icon(Icons.person_outline_rounded),
          title: Text("Edit Profile"),
          subtitle: Text("Change your name and handle"),
          onPressed: () => _showEditProfileDialog(context, state, glowColor),
        ),
        SettingsListTile(
          icon: Icon(Icons.info_outline_rounded),
          title: Text("About Songify"),
          subtitle: Text("Version 1.0.0"),
        ),
      ],
    );
  }

  Widget _buildGuestContent(BuildContext context, Color glowColor) {
    return PremiumFeaturesInfo(
      color: glowColor,
      trailing: SizedBox(
        width: double.infinity,
        child: LoginSignupButton(color: glowColor, onPressed: () async => _onLoginOrSignup(context)),
      ),
    );
  }

  void _onAvatarPressed(AppState state) => state.generateNewAvatar();

  Future<void> _onLoginOrSignup(BuildContext context) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  Future<void> _onLogout(BuildContext context) async {
    bool logout = await showLogoutDialog(context: context);

    if (logout) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context, AppState state, Color glowColor) async {
    String name = state.userName;
    String handle = state.userHandle;

    (name, handle) = await showEditProfileDialog(context: context, name: name, handle: handle);

    if (state.userName != name || state.userHandle != handle) {
      try {
        await state.updateProfile(name, handle);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }
}
