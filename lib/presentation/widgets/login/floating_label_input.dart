// lib/presentation/widgets/login/floating_label_input.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class FloatingLabelInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isFirst;
  final bool isLast;
  final FocusNode? focusNode;

  const FloatingLabelInput({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isFirst = false,
    this.isLast = false,
    this.focusNode,
  });

  @override
  State<FloatingLabelInput> createState() => _FloatingLabelInputState();
}

class _FloatingLabelInputState extends State<FloatingLabelInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  bool get _hasText => widget.controller.text.isNotEmpty;
  bool get _isFocused => _focusNode.hasFocus;
  bool get _shouldFloatLabel => _isFocused || _hasText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    
    // 초기 상태 설정
    if (_shouldFloatLabel) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      if (_shouldFloatLabel) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onTextChange() {
    setState(() {
      if (_shouldFloatLabel && !_animationController.isCompleted) {
        _animationController.forward();
      } else if (!_shouldFloatLabel && _animationController.isCompleted) {
        _animationController.reverse();
      }
    });
  }

  BorderRadius _getBorderRadius() {
    if (widget.isFirst && widget.isLast) {
      return BorderRadius.circular(AppDimensions.borderRadius);
    } else if (widget.isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.borderRadius),
        topRight: Radius.circular(AppDimensions.borderRadius),
      );
    } else if (widget.isLast) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(AppDimensions.borderRadius),
        bottomRight: Radius.circular(AppDimensions.borderRadius),
      );
    } else {
      return BorderRadius.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        color: _isFocused ? AppColors.white : AppColors.inputBackground,
        border: Border.all(
          color: _isFocused ? AppColors.inputFocused : AppColors.inputBorder,
          width: 1,
        ),
        borderRadius: _getBorderRadius(),
      ),
      child: Stack(
        children: [
          // 입력 필드
          Positioned.fill(
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeRegular,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: _shouldFloatLabel ? 20 : 12,
                  bottom: _shouldFloatLabel ? 4 : 12,
                ),
              ),
            ),
          ),
          // 플로팅 라벨
          Positioned(
            left: 16,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    _animation.value * -15 + (_shouldFloatLabel ? 10 : 25),
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: _animation.value * -4 + 16,
                      color: _isFocused 
                          ? AppColors.grey 
                          : AppColors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}