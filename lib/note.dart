import 'package:flutter/material.dart';

class Note {
  final int id;
  final String title;
  final String content;
  final List<int> tags;
  final bool pinned;
  final IconData icon;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.pinned,
    required this.icon,
  });
}