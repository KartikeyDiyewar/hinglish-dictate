import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages system overlay visibility based on keyboard state.
/// Overlay appears ONLY when keyboard is open — battery-efficient design.
class OverlayService {
  OverlayService._();
  static final OverlayService _instance = OverlayService._();
  factory OverlayService() => _instance;

  OverlayEntry? _overlayEntry;
  bool _isKeyboardVisible = false;
  bool _isRecording = false;

  bool get isKeyboardVisible => _isKeyboardVisible;
  bool get isRecording => _isRecording;

  /// Start listening for keyboard visibility changes.
  /// Call this from the main app widget.
  void init(BuildContext context) {
    SystemChannels.textInput.invokeMethod('TextInput.show');
    _setupKeyboardListener(context);
  }

  void _setupKeyboardListener(BuildContext context) {
    // Listen for keyboard show/hide via system channels
    SystemChannels.textInput.setMethodCallHandler((call) async {
      if (call.method == 'TextInput.show') {
        _isKeyboardVisible = true;
        _showOverlay(context);
      } else if (call.method == 'TextInput.hide') {
        _isKeyboardVisible = false;
        _hideOverlay();
      }
    });
  }

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const _DictateFloatingButton(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void setRecording(bool value) {
    _isRecording = value;
  }

  void dispose() {
    _hideOverlay();
  }
}

/// Floating overlay button — appears when keyboard is visible.
class _DictateFloatingButton extends StatefulWidget {
  const _DictateFloatingButton();

  @override
  State<_DictateFloatingButton> createState() => _DictateFloatingButtonState();
}

class _DictateFloatingButtonState extends State<_DictateFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
        _animController.reset();
      }
    });
    OverlayService().setRecording(_isRecording);
    // Parent will handle actual speech logic
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = OverlayService();
    if (!overlay.isKeyboardVisible && !_isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 12,
      bottom: 12,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording ? _pulseAnim.value : 1.0,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red.withValues(alpha: 0.9)
                    : Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: _isRecording
                        ? Colors.red.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
