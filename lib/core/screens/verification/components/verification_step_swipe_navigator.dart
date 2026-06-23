import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';

class VerificationStepSwipeNavigator extends StatefulWidget {
  static const navigatorKey = Key('verification-step-swipe-navigator');

  final Widget child;
  final bool canSwipeLeft;
  final bool canSwipeRight;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final String? swipeLeftHint;
  final String? swipeRightHint;

  const VerificationStepSwipeNavigator({
    super.key,
    required this.child,
    required this.canSwipeLeft,
    required this.canSwipeRight,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeLeftHint,
    this.swipeRightHint,
  });

  static const _swipeVelocityThreshold = 120.0;
  static const _swipeDistanceThreshold = 48.0;
  static const _maxVisualOffset = 64.0;
  static const _dragResistance = 0.5;

  @override
  State<VerificationStepSwipeNavigator> createState() =>
      _VerificationStepSwipeNavigatorState();
}

class _VerificationStepSwipeNavigatorState
    extends State<VerificationStepSwipeNavigator>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  double _verticalExtent = 0;
  late AnimationController _snapController;
  Animation<double>? _snapAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_snapAnimation != null) {
          setState(() => _dragExtent = _snapAnimation!.value);
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double get _visualOffset {
    final resisted = _dragExtent * VerificationStepSwipeNavigator._dragResistance;
    final clamped = resisted.clamp(
      -VerificationStepSwipeNavigator._maxVisualOffset,
      VerificationStepSwipeNavigator._maxVisualOffset,
    );
    if (!widget.canSwipeLeft && clamped < 0) return 0;
    if (!widget.canSwipeRight && clamped > 0) return 0;
    return clamped;
  }

  double get _hintOpacity {
    final progress = (_visualOffset.abs() /
            VerificationStepSwipeNavigator._maxVisualOffset)
        .clamp(0.0, 1.0);
    return 0.55 + (progress * 0.45);
  }

  void _onDragStart(DragStartDetails details) {
    if (_isAnimating) return;
    _snapController.stop();
    _snapAnimation = null;
    _dragExtent = 0;
    _verticalExtent = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    _dragExtent += details.delta.dx;
    _verticalExtent += details.delta.dy.abs();

    if (_verticalExtent > _dragExtent.abs() * 1.35 &&
        _dragExtent.abs() < 16) {
      return;
    }

    if (!widget.canSwipeLeft && _dragExtent < 0) {
      _dragExtent = 0;
    }
    if (!widget.canSwipeRight && _dragExtent > 0) {
      _dragExtent = 0;
    }

    setState(() {});
  }

  Future<void> _animateTo(double target, {VoidCallback? onComplete}) async {
    _isAnimating = true;
    _snapAnimation = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    await _snapController.forward(from: 0);
    _snapController.reset();
    _snapAnimation = null;
    _dragExtent = 0;
    _isAnimating = false;
    onComplete?.call();
    if (mounted) setState(() {});
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.primaryVelocity ?? 0;
    final swipeLeft = widget.canSwipeLeft &&
        (_dragExtent < -VerificationStepSwipeNavigator._swipeDistanceThreshold ||
            velocity < -VerificationStepSwipeNavigator._swipeVelocityThreshold);
    final swipeRight = widget.canSwipeRight &&
        (_dragExtent > VerificationStepSwipeNavigator._swipeDistanceThreshold ||
            velocity > VerificationStepSwipeNavigator._swipeVelocityThreshold);

    if (swipeLeft) {
      unawaited(
        _animateTo(
          -VerificationStepSwipeNavigator._maxVisualOffset * 2,
          onComplete: widget.onSwipeLeft,
        ),
      );
      return;
    }

    if (swipeRight) {
      unawaited(
        _animateTo(
          VerificationStepSwipeNavigator._maxVisualOffset * 2,
          onComplete: widget.onSwipeRight,
        ),
      );
      return;
    }

    unawaited(_animateTo(0));
  }

  void _onDragCancel() {
    if (_isAnimating) return;
    unawaited(_animateTo(0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurfaceVariant;
    final leftHint = widget.swipeLeftHint;
    final rightHint = widget.swipeRightHint;
    final showHints =
        (widget.canSwipeLeft && leftHint != null) ||
        (widget.canSwipeRight && rightHint != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            key: VerificationStepSwipeNavigator.navigatorKey,
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: _onDragCancel,
            child: Transform.translate(
              offset: Offset(_visualOffset, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: 1 - (_visualOffset.abs() / 200).clamp(0.0, 0.08),
                child: widget.child,
              ),
            ),
          ),
        ),
        if (showHints) ...[
          const SizedBox(height: SvSpacing.sm),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: _hintOpacity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.canSwipeRight && rightHint != null) ...[
                  Icon(
                    Icons.keyboard_double_arrow_left,
                    size: 18,
                    color: hintColor,
                  ),
                  const SizedBox(width: SvSpacing.xs),
                  Flexible(
                    child: Text(
                      rightHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hintColor,
                      ),
                    ),
                  ),
                ],
                if (widget.canSwipeRight &&
                    rightHint != null &&
                    widget.canSwipeLeft &&
                    leftHint != null)
                  const SizedBox(width: SvSpacing.md),
                if (widget.canSwipeLeft && leftHint != null) ...[
                  Flexible(
                    child: Text(
                      leftHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: SvSpacing.xs),
                  Icon(
                    Icons.keyboard_double_arrow_right,
                    size: 18,
                    color: hintColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
