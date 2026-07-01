import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:random_avatar/random_avatar.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (state.isLoggedIn)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Profile Image
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkCard,
                      border: Border.all(color: AppTheme.primaryYellow, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryYellow.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      image: state.userProfileImage != null
                          ? DecorationImage(
                              image: NetworkImage(state.userProfileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: state.userProfileImage == null
                        ? ClipOval(
                            child: RandomAvatar(
                              state.userName,
                              trBackground: false,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  // User Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.userName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (state.isLoggedIn)
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 22, color: AppTheme.textSecondary),
                          onPressed: () {
                            _showEditProfileDialog(context, state);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // User Email/Handle
                  Text(
                    state.userHandle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (state.isLoggedIn) ...[
                    // Stats Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Playlists', state.albumNames.length.toString()),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.textMuted.withOpacity(0.2),
                          ),
                          _buildStatItem('Total Songs', state.songsList.length.toString()),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Not Logged In Call to Action
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryYellow.withOpacity(0.1),
                            AppTheme.darkCard,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_sync_rounded, size: 48, color: AppTheme.primaryYellow),
                          const SizedBox(height: 16),
                          const Text(
                            "Sync Your Music",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Log in to save your playlists and sync your music library across all your devices.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Log In or Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }



  void _showEditProfileDialog(BuildContext context, AppState state) {
    String newName = state.userName;
    String newHandle = state.userHandle;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              controller: TextEditingController(text: newName)..selection = TextSelection.fromPosition(TextPosition(offset: newName.length)),
              onChanged: (val) => newName = val,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: "Handle",
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              controller: TextEditingController(text: newHandle)..selection = TextSelection.fromPosition(TextPosition(offset: newHandle.length)),
              onChanged: (val) => newHandle = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await state.updateProfile(newName, newHandle);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: AppTheme.primaryYellow)),
          ),
        ],
      ),
    );
  }
}
