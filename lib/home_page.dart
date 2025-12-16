import 'package:flutter/material.dart';

import 'note.dart';
import 'tag.dart';
import 'api_service.dart';
import 'create_tag_dialog.dart';
import 'danger_card.dart';
import 'nav_bar.dart';
import 'new_note_button.dart';
import 'notes_view.dart';
import 'search_bar.dart';
import 'tag_list.dart';

class HomePage extends StatefulWidget {
  final String? userId;
  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _refreshTurns = 0.0;

  /// TODO : Données simulées
  List<Tag> allTags = [
    Tag(id: 1, name: 'Important', color: Colors.orange, active: false),
    Tag(id: 2, name: 'Travail', color: Colors.blue, active: true),
  ];
  List<Note> listNotes = [];
  late List<Note> allNotesSource;
  List<Note> sharedNotes = [
    Note(
      id: 3,
      title: 'Note partagée',
      content: 'Contenu partagé',
      tags: [],
      pinned: false,
      icon: Icons.share,
    ),
  ];

  bool ifOpenCreateTag = false;
  String tagName = '';
  Color tagColor = Colors.orange;

  bool isRotating = false;
  bool ifDangerCard = false;
  bool tip = false;

  String notesViewMode = 'default';

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notes = await appelApi(context);
      if (!mounted) return;
      setState(() {
        allNotesSource = notes;
        listNotes = List<Note>.from(notes);
        sharedNotes = [];
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> reloadList() async {
    setState(() {
      _refreshTurns += 1.0;
      isRotating = true;
    });
    final notes = await appelApi(context);
    if (!mounted) return;
    setState(() {
      allNotesSource = notes;
      listNotes = List<Note>.from(notes);
      isRotating = false;
    });
  }

  void addTagFilter(int tagId) {
    setState(() {
      final tag = allTags.firstWhere((t) => t.id == tagId);
      tag.active = !tag.active;
      final activeIds = allTags.where((t) => t.active).map((t) => t.id).toList();
      if (activeIds.isEmpty) {
        listNotes = List<Note>.from(allNotesSource);
        notesViewMode = 'default'; // optionnel
        return;
      }
      listNotes = allNotesSource.where((n) {
        return n.tags.any((tid) => activeIds.contains(tid));
      }).toList();
      notesViewMode = 'default';
    });
  }

  void createNewNote() {
    // TODO : Nav vers autre page pour créer note
  }

  void openCreateTag() {
    setState(() {
      ifOpenCreateTag = true;
    });
  }

  void closeCreateTag() {
    setState(() {
      ifOpenCreateTag = false;
      tagName = '';
      tagColor = Colors.orange;
    });
  }

  void createTag() {
    setState(() {
      allTags.add(
        Tag(
          id: allTags.length + 1,
          name: tagName,
          color: tagColor,
          active: false,
        ),
      );
      closeCreateTag();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: NavBar(
          isRotating: isRotating,
          primaryColor: Theme.of(context).primaryColor,
          onReload: reloadList,
          refreshTurns: _refreshTurns,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: searchController,
                  hintText: 'Recherche...',
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: TagList(
                    tags: allTags,
                    onTagTap: addTagFilter,
                    onAddTag: openCreateTag,
                  ),
                ),
                const SizedBox(height: 8),
                if (tip)
                  const DangerCard(
                    title: 'Tip of the week',
                    content: 'You can create a new note with +',
                  ),
                if (ifDangerCard)
                  const DangerCard(title: 'Attention', content: 'Important alert'),
                Expanded(
                  child: notesViewMode == 'tag'
                      ? NotesByTagView(allTags: allTags, listNotes: listNotes)
                      : NotesMasonryView(
                          allTags: allTags,
                          pinnedNotes: listNotes.where((n) => n.pinned).toList(),
                          sharedNotes: sharedNotes,
                          otherNotes: listNotes.where((n) => !n.pinned).toList(),
                        ),
                ),
              ],
            ),
          ),
          if (ifOpenCreateTag)
            Positioned.fill(
              child: GestureDetector(
                onTap: closeCreateTag,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: CreateTagDialog(
                      initialColor: tagColor,
                      initialName: tagName,
                      onCancel: closeCreateTag,
                      onCreate: (String name, Color color) {
                        tagName = name;
                        tagColor = color;
                        createTag();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: NewNoteButton(onPressed: createNewNote),
    );
  }
}