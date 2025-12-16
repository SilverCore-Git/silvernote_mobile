import 'package:flutter/material.dart';

import 'note.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onPin;
  final VoidCallback? onClick;

  const NoteCard({super.key, required this.note, this.onPin, this.onClick});



  Widget _getNoteIcon() {
    if (note.icon != null && note.icon!.isNotEmpty) {
      if (note.icon!.startsWith('data:image/svg+xml')) {
        try {
          final uriData = Uri.parse(note.icon!).data;
          if (uriData != null) {
            var svgString = uriData.contentAsString();
            final styleRegex =
                RegExp(r'<style.*?>.*?</style>', multiLine: true, dotAll: true);
            svgString = svgString.replaceAll(styleRegex, '');
            return SvgPicture.string(
              svgString,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            );
          }
        } catch (e) {

        }

      } else if (note.icon!.startsWith('data:image')) {
        try {
          final commaIndex = note.icon!.indexOf(',');
          if (commaIndex != -1) {
            final base64String = note.icon!.substring(commaIndex + 1);
            final imageBytes = base64Decode(base64String);
            return Image.memory(
              imageBytes,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            );
          }
        } catch (e) {
          // Fallback
        }

      } else {
        // Assume it's an emoji
        return Text(
          note.icon!,
          style: const TextStyle(fontSize: 24),
        );
      }
    }
    return const Icon(Icons.article_outlined, color: Colors.orangeAccent);
  }



  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.grey[900];
    final textColor = Colors.white;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: bgColor,
      child: ListTile(
        leading: _getNoteIcon(),
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