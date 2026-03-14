import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class GreetingCard extends StatelessWidget {
  final String userName;

  const GreetingCard({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: Text('Welcome back, $userName!'),
      subtitle: const Text("Here's what's happening today"),
    );
  }
}
