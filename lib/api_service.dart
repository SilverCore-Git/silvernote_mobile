import 'dart:convert';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'note.dart';

extension NoteApiMapper on Note {
  static IconData _pickIcon(String? icon, String title, String content) {
    if (icon != null && icon.isNotEmpty) return Icons.note;
    if (title.toLowerCase().contains('todo')) return Icons.checklist;
    return Icons.note_alt;
  }

  static Note fromApi(Map<String, dynamic> j) {
    final title = (j['title'] ?? '').toString();
    final content = (j['content'] ?? '').toString();
    final pinned = (j['pinned'] ?? false) == true;
    final tags = (j['tags'] is List)
        ? (j['tags'] as List)
            .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList()
        : <int>[];

    return Note(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      title: title.isEmpty ? 'Note sans titre' : title,
      content: content,
      tags: tags,
      pinned: pinned,
      icon: _pickIcon(j['icon'] as String?, title, content),
    );
  }
}

Future<List<Note>> appelApi(BuildContext context) async {
  final auth = ClerkAuth.of(context);
  final user = auth.user;
  final session = auth.session;
  final userId = user?.id;
  final rippedToken = session?.lastActiveToken?.jwt;


  debugPrint('appelApi: userId=$userId');

  if (userId == null || userId.isEmpty) {
    debugPrint('appelApi: userId manquant');
    return <Note>[];
  }

  final uri =
      Uri.parse('https://api.silvernote.fr/api/db/get/user/notes?user_id=$userId');
  debugPrint('appelApi: GET $uri'); // log 2
  

  try {

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $rippedToken',
      },
    );

    debugPrint('appelApi: status=${resp.statusCode} len=${resp.body.length}'); // log 3

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('status=${resp.statusCode}');
      debugPrint(
          'body[0..300]=${resp.body.substring(0, resp.body.length.clamp(0, 300))}');
      return <Note>[];
    }

    final dynamic decoded = json.decode(resp.body);
    if (decoded is! Map) {
      debugPrint('appelApi: JSON racine non-objet: ${decoded.runtimeType}');
      return <Note>[];
    }

    final map = decoded;
    final ok = map['success'] == true;
    debugPrint('appelApi: success=$ok');

    final rawNotes = map['notes'];
    if (rawNotes is! List) {
      debugPrint('appelApi: notes non-liste: ${rawNotes.runtimeType}');
      return <Note>[];
    }

    final notes = rawNotes
        .map((e) => e is Map ? NoteApiMapper.fromApi(e.cast<String, dynamic>()) : null)
        .whereType<Note>()
        .toList();

    debugPrint('appelApi: parsed notes=${notes.length}');
    return notes;
  } catch (e) {
    debugPrint('appelApi: error $e');
    return <Note>[];
  }
}