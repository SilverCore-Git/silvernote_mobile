import 'package:flutter/material.dart';

class Tag {
  final int id;
  final String name;
  final Color color;
  bool active;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    this.active = false,
  });
}