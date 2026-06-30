import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _alphaController;
  late Animation<double> _alphaAnim;
  
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  
  late AnimationController _waveController;
  late Animation<double> _waveHeightMultiplier;

  @override
  void initState() {
    super.initState();
    
    _alphaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _alphaAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _alphaController, curve: Curves.easeInOutCirc));
    
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.05).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack));
    
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _waveHeightMultiplier = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _waveController, curve: Curves.fastOutSlowIn));
    
    _waveController.repeat(reverse: true);
    _alphaController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _alphaController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_alphaAnim, _scaleAnim]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _alphaAnim.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/splashlogo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double heightMultiplier;
  
  WavePainter(this.heightMultiplier);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryYellow
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
      
    const int barCount = 5;
    const double spacing = 8.0;
    const double barWidth = 6.0;
    
    final double totalWidth = (barCount * barWidth) + ((barCount - 1) * spacing);
    final double startX = (size.width - totalWidth) / 2;
    final double centerY = size.height / 2;
    
    for (int i = 0; i < barCount; i++) {
      // Base height 55 equivalent in Compose, math.sin to generate wave pattern
      final double activeHeight = 55.0 * (0.3 + 0.7 * math.sin((i + 1) * 0.8)) * heightMultiplier;
      final double x = startX + (i * (barWidth + spacing));
      
      canvas.drawLine(
        Offset(x, centerY - activeHeight / 2),
        Offset(x, centerY + activeHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => heightMultiplier != oldDelegate.heightMultiplier;
}
