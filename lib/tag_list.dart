import 'package:flutter/material.dart';

import 'tag.dart';
import 'color_utils.dart';

class TagList extends StatelessWidget {
  final List<Tag> tags;
  final void Function(int) onTagTap;
  final VoidCallback onAddTag;

  const TagList({
    super.key,
    required this.tags,
    required this.onTagTap,
    required this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return GestureDetector(
                onTap: () => onTagTap(tag.id),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tag.color,
                    borderRadius: BorderRadius.circular(40),
                    border: tag.active
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      color: useWhiteForeground(tag.color)
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 4),
          ),
        ),
        GestureDetector(
          onTap: onAddTag,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF28C28)),
            ),
            child: const Center(
              child: Text(
                '+',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}