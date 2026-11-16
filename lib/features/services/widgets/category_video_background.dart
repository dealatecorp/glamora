import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../models/salon_models.dart';

class CategoryVideoBackground extends StatefulWidget {
  const CategoryVideoBackground({super.key, this.category});

  final ServiceCategory? category;

  @override
  State<CategoryVideoBackground> createState() =>
      _CategoryVideoBackgroundState();
}

class _CategoryVideoBackgroundState extends State<CategoryVideoBackground> {
  VideoPlayerController? _controller;
  VideoPlayerController? _outgoingController;
  String? _asset;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) _loadCategory(widget.category!);
  }

  @override
  void didUpdateWidget(covariant CategoryVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadCategory(widget.category);
    }
  }

  Future<void> _loadCategory(ServiceCategory? category) async {
    final request = ++_loadRequest;
    if (category == null) {
      if (mounted) {
        setState(() {
          _controller = null;
          _asset = null;
          _outgoingController = null;
        });
      }
      return;
    }
    final asset = category.videoAsset;
    if (_asset == asset) return;

    try {
      final next = await _CategoryVideoStore.controllerFor(asset);
      if (!mounted || request != _loadRequest) return;
      await next.play();
      if (!mounted || request != _loadRequest) return;

      final previous = _controller;
      setState(() {
        _outgoingController = previous;
        _controller = next;
        _asset = asset;
      });

      if (previous != null && !identical(previous, next)) {
        Future<void>.delayed(const Duration(milliseconds: 650), () {
          if (identical(_outgoingController, previous)) {
            _outgoingController = null;
          }
        });
      }
    } catch (_) {
      return;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_asset),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryVideoStore {
  static final Map<String, VideoPlayerController> _controllers = {};
  static final Map<String, Future<VideoPlayerController>> _pending = {};

  static Future<VideoPlayerController> controllerFor(String asset) {
    final existing = _controllers[asset];
    if (existing != null && existing.value.isInitialized) {
      return Future.value(existing);
    }
    return _pending[asset] ??= _create(asset);
  }

  static Future<VideoPlayerController> _create(String asset) async {
    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      _controllers[asset] = controller;
      return controller;
    } finally {
      _pending.remove(asset);
    }
  }
}

extension ServiceCategoryVideoX on ServiceCategory {
  String get videoAsset {
    switch (this) {
      case ServiceCategory.face:
        return 'assets/videos/face.mp4';
      case ServiceCategory.hair:
        return 'assets/videos/hair.mp4';
      case ServiceCategory.bodyWaxing:
        return 'assets/videos/body_waxing.mp4';
      case ServiceCategory.nails:
        return 'assets/videos/nails.mp4';
      case ServiceCategory.wellness:
        return 'assets/videos/wellness.mp4';
      case ServiceCategory.grooming:
        return 'assets/videos/grooming.mp4';
      case ServiceCategory.makeUp:
        return 'assets/videos/makeup.mp4';
      case ServiceCategory.events:
        return 'assets/videos/event.mp4';
    }
  }
}
