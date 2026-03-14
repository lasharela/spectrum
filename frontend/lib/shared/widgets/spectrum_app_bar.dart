import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class SpectrumAppBar extends StatelessWidget {
  final String title;

  const SpectrumAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return FHeader.nested(
      title: Text(title),
      titleAlignment: Alignment.center,
      prefixes: [
        FHeaderAction(
          icon: const Icon(Icons.notifications_outlined),
          onPress: () {},
        ),
      ],
      suffixes: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: FAvatar.raw(size: 34),
        ),
      ],
    );
  }
}
