import 'package:flutter/material.dart';

class SwipeArrowHint extends StatefulWidget {
  const SwipeArrowHint({super.key});

  @override
  State<SwipeArrowHint> createState() => _SwipeArrowHintState();
}

class _SwipeArrowHintState extends State<SwipeArrowHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
      child: Row(
        children: const [
          Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
          Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
          Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}
