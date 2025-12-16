import 'package:flutter/material.dart';

class DangerCard extends StatelessWidget {
  final String title;
  final String content;

  const DangerCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.red[700];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15)],
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}