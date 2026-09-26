import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/album_detail_screen.dart';
import 'screens/library_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/mini_player.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file or --dart-define
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fall back to environment definitions if .env is missing
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } else {
    debugPrint(
      'Warning: Supabase credentials missing. Provide SUPABASE_URL and SUPABASE_ANON_KEY via .env or --dart-define.',
    );
  }

  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.example.songify.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
      );
    } catch (_) {}
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const SongifyApp(),
    ),
  );
}

class SongifyApp extends StatelessWidget {
  const SongifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Songify',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }
    
    return Consumer<AppState>(
      builder: (context, state, child) {
        final glowColor = MiniPlayer.getTrackColor(state.currentTrack);

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  glowColor.withValues(alpha: 0.22),
                  AppTheme.darkBackground,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
            child: IndexedStack(
              index: state.currentTab,
              children: const [
                HomeScreen(),
                DiscoverScreen(),
                LibraryScreen(),
                ProfileScreen(),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              NavigationBar(
                backgroundColor: AppTheme.darkSurface,
                indicatorColor: AppTheme.primaryYellow.withOpacity(0.15),
                selectedIndex: state.currentTab,
                onDestinationSelected: state.changeTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_rounded),
                    label: 'Discover',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_rounded),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
