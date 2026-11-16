import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:saloon_application/core/theme/app_theme.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/auth/auth_gate.dart';
import 'package:saloon_application/features/auth/repositories/auth_repository.dart';
import 'package:saloon_application/features/auth/state/auth_controller.dart';
import 'package:saloon_application/features/auth/services/auth_storage.dart';
import 'package:saloon_application/features/customer/customer_website_screen.dart';
import 'package:saloon_application/navigation/app_shell.dart';

void main() {
  runApp(const SaloonApp());
}

class SaloonApp extends StatefulWidget {
  const SaloonApp({super.key});

  @override
  State<SaloonApp> createState() => _SaloonAppState();
}

class _SaloonAppState extends State<SaloonApp> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(
      repository: DemoAuthRepository(),
      storage: SharedPreferencesAuthStorage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glamora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
      routes: {
        '/app': (_) =>
            AppShell(session: _controller.session, authController: _controller),
        '/customer': (_) => CustomerWebsiteScreen(repository: DemoRepository()),
      },
      home: SplashScreen(next: AuthGate(controller: _controller)),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});
  final Widget next;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) => _completed
      ? widget.next
      : _GlamoraSplashView(
          onComplete: () {
            if (mounted) setState(() => _completed = true);
          },
        );
}

class _GlamoraSplashView extends StatefulWidget {
  const _GlamoraSplashView({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_GlamoraSplashView> createState() => _GlamoraSplashViewState();
}

class _GlamoraSplashViewState extends State<_GlamoraSplashView> {
  VideoPlayerController? _controller;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(
      'assets/branding/splash/glamora-splash-loading.mp4',
    );
    try {
      await controller.initialize();
      controller.addListener(_handleVideoState);
      await controller.setLooping(false);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) widget.onComplete();
    }
  }

  void _handleVideoState() {
    final controller = _controller;
    if (_didComplete || controller == null || !controller.value.isInitialized) {
      return;
    }
    final duration = controller.value.duration;
    if (duration > Duration.zero &&
        controller.value.position >=
            duration - const Duration(milliseconds: 80)) {
      _didComplete = true;
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoState);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller == null || !controller.value.isInitialized)
            const ColoredBox(color: Colors.black)
          else
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
        ],
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Image(
        image: AssetImage('assets/branding/auth/auth-background-mobile.jpg'),
        fit: BoxFit.cover,
      ),
      child,
    ],
  );
}
