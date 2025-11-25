import 'package:flutter/material.dart';
class AppIdentityIcon extends StatelessWidget {
  const AppIdentityIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.group,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
