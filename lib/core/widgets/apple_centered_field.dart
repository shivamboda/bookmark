import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any widget or input so that when tapped or focused,
/// it smoothly scrolls to the vertical center of the viewport,
/// matching Apple iOS form aesthetics.
class AppleCenteredField extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final Duration delay;
  final Duration scrollDuration;
  final Curve curve;

  const AppleCenteredField({
    super.key,
    required this.child,
    this.focusNode,
    this.delay = const Duration(milliseconds: 220),
    this.scrollDuration = const Duration(milliseconds: 320),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  State<AppleCenteredField> createState() => _AppleCenteredFieldState();
}

class _AppleCenteredFieldState extends State<AppleCenteredField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(AppleCenteredField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChanged);
      _effectiveFocusNode.addListener(_handleFocusChanged);
    }
  }

  void _handleFocusChanged() {
    if (_effectiveFocusNode.hasFocus) {
      _centerInViewport();
    }
  }

  void _centerInViewport() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(widget.delay, () {
      if (mounted && _effectiveFocusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5, // 0.5 = Vertically centered in visible viewport
          duration: widget.scrollDuration,
          curve: widget.curve,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A drop-in replacement for TextFormField that automatically centers itself
/// in the viewport on focus and tap, just like Apple iOS native apps.
class AppleCenteredTextFormField extends StatefulWidget {
  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  const AppleCenteredTextFormField({
    super.key,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  @override
  State<AppleCenteredTextFormField> createState() => _AppleCenteredTextFormFieldState();
}

class _AppleCenteredTextFormFieldState extends State<AppleCenteredTextFormField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(AppleCenteredTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChanged);
      _effectiveFocusNode.addListener(_handleFocusChanged);
    }
  }

  void _handleFocusChanged() {
    if (_effectiveFocusNode.hasFocus) {
      _centerInViewport();
    }
  }

  void _centerInViewport() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5, // Center vertically in viewport
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      style: widget.style,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textCapitalization: widget.textCapitalization,
      autofocus: widget.autofocus,
      scrollPadding: const EdgeInsets.symmetric(vertical: 220, horizontal: 20),
      onTap: () {
        _centerInViewport();
        widget.onTap?.call();
      },
    );
  }
}
