import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool enableHover;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.enableHover = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHover) return;
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.enableHover ? _scaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color ?? AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered && widget.onTap != null
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  if (_isHovered && widget.onTap != null)
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: _elevationAnimation.value + 4,
                      offset: Offset(0, _elevationAnimation.value / 2 + 2),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.transparent, // Handled by container decoration
                  child: Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
