import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/mini_player.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // Hive.registerAdapter(TrackAdapter()); // to be uncommented once generated
  await Hive.openBox('favorites');
  await Hive.openBox('albums');

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
              NowPlayingScreen(),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.currentTab != 3) const MiniPlayer(),
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
                    icon: Icon(Icons.play_circle_filled_rounded),
                    label: 'Now Playing',
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
