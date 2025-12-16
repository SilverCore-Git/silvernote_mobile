import 'package:flutter/material.dart';

import 'note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onPin;
  final VoidCallback? onClick;

  const NoteCard({super.key, required this.note, this.onPin, this.onClick});

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.grey[900];
    final textColor = Colors.white;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: bgColor,
      child: ListTile(
        leading: Icon(note.icon, color: Colors.orangeAccent),
        title: Text(
          note.title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(note.content, style: TextStyle(color: textColor)),
        trailing: IconButton(
          icon: Icon(
            note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: Colors.orangeAccent,
          ),
          onPressed: onPin,
        ),
        onTap: onClick,
      ),
    );
  }
}