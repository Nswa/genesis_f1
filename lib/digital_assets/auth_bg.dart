import 'package:flutter/material.dart';

class AuthBackground extends StatefulWidget {
  final Widget? child;

  const AuthBackground({Key? key, this.child}) : super(key: key);

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _radiusAnim = Tween<double>(
      begin: 1.3,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _radiusAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -1.5),
              radius: _radiusAnim.value,
              colors: const [
                Color.fromARGB(80, 24, 4, 65),
                Color.fromARGB(255, 0, 0, 0),
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
