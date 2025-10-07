import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // In-app notification overlay
  OverlayEntry? _overlayEntry;
  bool _isShowingNotification = false;

  // Show in-app notification for new message
  void showMessageNotification(
    BuildContext context,
    ChatMessage message, {
    VoidCallback? onTap,
  }) {
    if (_isShowingNotification) return;

    _isShowingNotification = true;
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    _overlayEntry = OverlayEntry(
      builder: (context) => _MessageNotificationWidget(
        message: message,
        onTap: () {
          _hideNotification();
          onTap?.call();
        },
        onDismiss: _hideNotification,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Auto-hide after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _hideNotification();
    });
  }

  void _hideNotification() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowingNotification = false;
    }
  }

  // Show call notification
  void showCallNotification(
    BuildContext context,
    String callerName, {
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    if (_isShowingNotification) return;

    _isShowingNotification = true;
    
    // Strong haptic feedback for calls
    HapticFeedback.heavyImpact();

    _overlayEntry = OverlayEntry(
      builder: (context) => _CallNotificationWidget(
        callerName: callerName,
        onAccept: () {
          _hideNotification();
          onAccept?.call();
        },
        onDecline: () {
          _hideNotification();
          onDecline?.call();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Show simple snackbar notification
  void showSnackbarNotification(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.blue[800],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _MessageNotificationWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _MessageNotificationWidget({
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_MessageNotificationWidget> createState() => _MessageNotificationWidgetState();
}

class _MessageNotificationWidgetState extends State<_MessageNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanUpdate: (details) {
              if (details.delta.dy < -5) {
                _dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[800],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message.content,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallNotificationWidget extends StatefulWidget {
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _CallNotificationWidget({
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_CallNotificationWidget> createState() => _CallNotificationWidgetState();
}

class _CallNotificationWidgetState extends State<_CallNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue[800],
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Incoming call',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                GestureDetector(
                  onTap: widget.onDecline,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                // Accept button
                GestureDetector(
                  onTap: widget.onAccept,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
