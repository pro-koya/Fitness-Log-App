import 'package:flutter/material.dart';
import 'tutorial_spotlight.dart';
import 'tutorial_tooltip.dart';

/// Tutorial overlay using Overlay/OverlayEntry (screen coordinates).
/// No coordinate conversion: target rect from localToGlobal is used as-is.
/// Works consistently regardless of SafeArea, screen, or parent structure.
class TutorialOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String tooltipMessage;
  final VoidCallback? onSkip;
  final bool isActive;

  const TutorialOverlay({
    super.key,
    required this.targetKey,
    required this.tooltipMessage,
    this.onSkip,
    this.isActive = true,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      // Defer insertion until after build; Overlay.insert() triggers setState on Overlay.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) _insertOverlay();
      });
    }
  }

  @override
  void didUpdateWidget(covariant TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Defer all overlay mutations; insert/remove trigger markNeedsBuild on Overlay.
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) _insertOverlay();
      });
    } else if (!widget.isActive && oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _removeOverlay());
    } else if (widget.isActive &&
        (oldWidget.targetKey != widget.targetKey ||
            oldWidget.tooltipMessage != widget.tooltipMessage)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _removeOverlay();
        if (mounted && widget.isActive) _insertOverlay();
      });
    } else if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _insertOverlay() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (overlayContext) {
        final rect = _getTargetRectInScreen();
        if (rect == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _entry?.markNeedsBuild();
          });
          return const SizedBox.shrink();
        }
        final screenSize = MediaQuery.sizeOf(overlayContext);
        return _TutorialOverlayContent(
          targetRect: rect,
          screenSize: screenSize,
          tooltipMessage: widget.tooltipMessage,
          onSkip: widget.onSkip,
          onLayoutChange: () => _entry?.markNeedsBuild(),
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  /// Target rect in screen (global) coordinates. Overlay uses the same coordinate system.
  Rect? _getTargetRectInScreen() {
    final renderBox = widget.targetKey.currentContext?.findRenderObject()
        as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      return null;
    }
    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
  }

  @override
  Widget build(BuildContext context) {
    // This widget does not draw anything; overlay is drawn via OverlayEntry.
    return const SizedBox.shrink();
  }
}

/// Content drawn in the overlay (screen coordinates).
class _TutorialOverlayContent extends StatefulWidget {
  final Rect targetRect;
  final Size screenSize;
  final String tooltipMessage;
  final VoidCallback? onSkip;
  final VoidCallback onLayoutChange;

  const _TutorialOverlayContent({
    required this.targetRect,
    required this.screenSize,
    required this.tooltipMessage,
    required this.onSkip,
    required this.onLayoutChange,
  });

  @override
  State<_TutorialOverlayContent> createState() => _TutorialOverlayContentState();
}

class _TutorialOverlayContentState extends State<_TutorialOverlayContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLayoutChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dimmed layer with spotlight hole - IgnorePointer so taps reach the button
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: CustomPaint(
              size: widget.screenSize,
              painter: TutorialSpotlight(targetRect: widget.targetRect),
            ),
          ),
        ),
        // Tooltip (screen coordinates: targetRect is already global)
        TutorialTooltip(
          message: widget.tooltipMessage,
          targetRect: widget.targetRect,
          containerSize: widget.screenSize,
          onSkip: widget.onSkip,
        ),
      ],
    );
  }
}
