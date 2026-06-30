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
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Please provide your URL and Anon Key)
  await Supabase.initialize(
    url: 'https://ubwwgncpgrkmqsjevteq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVid3dnbmNwZ3JrbXFzamV2dGVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MzkyODIsImV4cCI6MjA5ODQxNTI4Mn0.2u9JM1Qai6SWNQOM9ziqbHDuIRkxpFpYSrx0iA2SwVQ',
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.songify.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

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
        return Scaffold(
          body: IndexedStack(
            index: state.currentTab,
            children: const [
              HomeScreen(),
              DiscoverScreen(),
              LibraryScreen(),
              ProfileScreen(),
            ],
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
