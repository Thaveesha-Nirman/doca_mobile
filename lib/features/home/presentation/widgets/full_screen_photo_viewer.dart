import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

class FullScreenPhotoViewer extends StatefulWidget {
  const FullScreenPhotoViewer({
    required this.photos,
    this.initialIndex = 0,
    super.key,
  });

  final List<Uint8List> photos;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<Uint8List> photos,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => FullScreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable, pinch-to-zoom photo pager
          PageView.builder(
            controller: _pageController,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: total,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isZoomed = false;
              });
            },
            itemBuilder: (_, index) {
              return _ZoomablePhotoPage(
                bytes: widget.photos[index],
                onZoomChanged: (zoomed) {
                  if (_isZoomed != zoomed) {
                    setState(() => _isZoomed = zoomed);
                  }
                },
              );
            },
          ),

          // Top bar: close button + photo counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isZoomed
                        ? 'Double-tap to reset zoom'
                        : 'Pinch or double-tap to zoom',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomablePhotoPage extends StatefulWidget {
  const _ZoomablePhotoPage({
    required this.bytes,
    required this.onZoomChanged,
  });

  final Uint8List bytes;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhotoPage> createState() => _ZoomablePhotoPageState();
}

class _ZoomablePhotoPageState extends State<_ZoomablePhotoPage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_notifyZoomState);
  }

  @override
  void dispose() {
    _controller.removeListener(_notifyZoomState);
    _controller.dispose();
    super.dispose();
  }

  void _notifyZoomState() {
    final scale = _controller.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05);
  }

  void _handleDoubleTap() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      _controller.value = Matrix4.identity();
      return;
    }

    const double targetScale = 2.5;
    final tapPos = _doubleTapDetails?.localPosition;
    if (tapPos != null) {
      final dx = -tapPos.dx * (targetScale - 1);
      final dy = -tapPos.dy * (targetScale - 1);
      _controller.value = Matrix4.diagonal3Values(targetScale, targetScale, 1.0)
        ..setTranslationRaw(dx, dy, 0.0);
    } else {
      _controller.value = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        child: SizedBox.expand(
          child: Center(
            child: Image.memory(
              widget.bytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}