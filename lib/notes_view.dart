import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:html/parser.dart' as html_parser;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_theme.dart';
import 'note.dart';
import 'tag.dart';
import 'color_utils.dart';
import 'note_card.dart';

class NotesByTagView extends StatelessWidget {
  final List<Tag> allTags;
  final List<Note> listNotes;

  const NotesByTagView({
    super.key,
    required this.allTags,
    required this.listNotes,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    for (final tag in allTags) {
      final notesForTag = listNotes.where((n) => n.tags.contains(tag.id)).toList();
      if (notesForTag.isEmpty) continue;

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tag.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag.name,
                style: TextStyle(
                  color: useWhiteForeground(tag.color) ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              children: notesForTag.map((note) => NoteCard(note: note)).toList(),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: widgets),
    );
  }
}

class NotesMasonryView extends StatelessWidget {
  final List<Tag> allTags;
  final List<Note> pinnedNotes;
  final List<Note> sharedNotes;
  final List<Note> otherNotes;
  const NotesMasonryView({
    super.key,
    required this.allTags,
    required this.pinnedNotes,
    required this.sharedNotes,
    required this.otherNotes,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
            ? 3
            : 2;
    const spacing = 12.0;

    final List<_Section> sections = [
      if (pinnedNotes.isNotEmpty) _Section('Notes épinglées', pinnedNotes),
      if (sharedNotes.isNotEmpty) _Section('Notes partagées', sharedNotes),
      _Section('Autres', otherNotes),
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final s = sections[i];
        if (s.notes.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _SectionHeader(title: s.title),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing),
              child: MasonryGridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                itemCount: s.notes.length,
                itemBuilder: (context, index) {
                  final n = s.notes[index];
                  return _NoteCreamCard(note: n, allTags: allTags);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _Section {
  final String title;
  final List<Note> notes;
  _Section(this.title, this.notes);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Theme.of(context).customColors.textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _NoteCreamCard extends StatelessWidget {
  final Note note;
  final List<Tag> allTags;
  const _NoteCreamCard({required this.note, required this.allTags});

  Tag? _findTag(int id) {
    try {
      return allTags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  String stripHtmlTags(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    return document.body?.text ?? '';
  }

  String _truncateContent(String text) {
    const maxLength = 100;
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    } else {
      return text;
    }
  }

  Widget _getNoteIcon(BuildContext context) {
    if (note.icon != null && note.icon!.isNotEmpty) {
      if (note.icon!.startsWith('data:image/svg+xml')) {
        try {
          final uriData = Uri.parse(note.icon!).data;
          if (uriData != null) {
            var svgString = uriData.contentAsString();
            final styleRegex =
                RegExp(r'<style.*?>.*?</style>', multiLine: true, dotAll: true);
            svgString = svgString.replaceAll(styleRegex, '');

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SvgPicture.string(
                svgString,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            );
          }
        } catch (e) {
          // Fallback for parsing errors
        }
      } else if (note.icon!.startsWith('data:image')) {
        try {
          final commaIndex = note.icon!.indexOf(',');
          if (commaIndex != -1) {
            final base64String = note.icon!.substring(commaIndex + 1);
            final imageBytes = base64Decode(base64String);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.memory(
                imageBytes,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            );
          }
        } catch (e) {
          // Fallback
        }
      } else {
        // Assume it's an emoji
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            note.icon!,
            style: const TextStyle(fontSize: 18),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final title = (note.title.isEmpty) ? 'NOTE SANS TITRE' : note.title;
    final cleanContent = stripHtmlTags(note.content);
    final truncatedContent = _truncateContent(cleanContent);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).customColors.noteCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 186, 186, 186).withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getNoteIcon(context),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).customColors.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // callback onPin
                },
                child: Icon(
                  note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18,
                  color: Theme.of(context).customColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (cleanContent.trim().isNotEmpty)
            Text(
              truncatedContent,
              style: TextStyle(
                color: Theme.of(context).customColors.textColor,
                height: 1.25,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                color: hint.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 12),
          if (note.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.tags.map((tagId) {
                final t = _findTag(tagId);
                final chipText = t?.name ?? 'TAG $tagId';
                final chipColor = t?.color ?? const Color(0xFFFFF5E8);
                final borderColor = border.withOpacity(0.25);
                final fg = useWhiteForeground(chipColor)
                    ? Colors.white
                    : textDark.withOpacity(0.85);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      color: fg,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}