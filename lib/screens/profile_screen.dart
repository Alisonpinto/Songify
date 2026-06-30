import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Profile Image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkSurface,
                      border: Border.all(color: AppTheme.primaryYellow, width: 3),
                      image: state.userProfileImage != null
                          ? DecorationImage(
                              image: NetworkImage(state.userProfileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: state.userProfileImage == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: AppTheme.textSecondary,
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (state.isLoggedIn)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: AppTheme.textSecondary),
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
                  // Stats Row (only if logged in)
                  if (state.isLoggedIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Playlists', state.albumNames.length.toString()),
                        _buildStatItem('Total Songs', state.songsList.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                  // Settings List
                  _buildSettingsItem(Icons.settings_rounded, 'Settings'),
                  _buildSettingsItem(Icons.history_rounded, 'Listening History'),
                  _buildSettingsItem(Icons.info_outline_rounded, 'About'),
                  const SizedBox(height: 20),
                  // Auth Button
                  OutlinedButton(
                    onPressed: () async {
                      if (state.isLoggedIn) {
                        await Supabase.instance.client.auth.signOut();
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryYellow),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text(
                      state.isLoggedIn ? 'Log Out' : 'Log In',
                      style: const TextStyle(
                        color: AppTheme.primaryYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

  Widget _buildSettingsItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
      onTap: () {},
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
