// lib/presentation/widgets/login/input_container.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import 'floating_label_input.dart';

class InputContainer extends StatelessWidget {
  final List<FloatingLabelInput> inputs;

  const InputContainer({
    super.key,
    required this.inputs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < inputs.length; i++) ...[
            FloatingLabelInput(
              label: inputs[i].label,
              controller: inputs[i].controller,
              obscureText: inputs[i].obscureText,
              onChanged: inputs[i].onChanged,
              validator: inputs[i].validator,
              keyboardType: inputs[i].keyboardType,
              focusNode: inputs[i].focusNode,
              isFirst: i == 0,
              isLast: i == inputs.length - 1,
            ),
            if (i < inputs.length - 1)
              Container(
                height: 1,
                color: AppColors.inputBorder,
              ),
          ],
        ],
      ),
    );
  }
}