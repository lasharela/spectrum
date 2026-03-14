import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class UiTestScreen extends StatelessWidget {
  const UiTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FButton(
          onPress: () {},
          child: const Text('Primary'),
        ),
        const SizedBox(height: 16),
        FButton(
          variant: FButtonVariant.secondary,
          onPress: () {},
          child: const Text('Secondary'),
        ),
        const SizedBox(height: 16),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () {},
          child: const Text('Outline'),
        ),
      ],
    );
  }
}
