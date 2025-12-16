import 'package:flutter/material.dart';

class NewNoteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NewNoteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFF28C28),
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}