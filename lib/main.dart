import 'dart:math';

import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

const appUrl = 'https://test-clerk.dev.silvernote.fr/';
const String clerkPublishableKey = 'pk_test_aW52aXRpbmctZmluY2gtNTIuY2xlcmsuYWNjb3VudHMuZGV2JA';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilverNoteApp());
}

class SilverNoteApp extends StatelessWidget {
  const SilverNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top - 7.5;
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: clerkPublishableKey),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, _) {
              final inset = MediaQuery.of(context).viewInsets.bottom;
              final maxShift = 105.0;
              final shift = inset.clamp(0.0, maxShift);
              return Stack(
                children: [
                  Container(height: topPadding, color: const Color(0xFFF28C28)),
                  Center(
                    child: AnimatedPadding(
                      padding: EdgeInsets.only(bottom: shift),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: ClerkErrorListener(
                        child: ClerkAuthBuilder(
                          signedInBuilder: (context, auth) {
                            // Ici on remplace la WebView par un écran classique vide / à compléter
                            return const HomePage();
                          },
                          signedOutBuilder: (context, authState) {
                            return const ClerkAuthentication();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// TODO : Données simulées
  List<Tag> allTags = [
    Tag(id: 1, name: 'Important', color: Colors.orange, active: false),
    Tag(id: 2, name: 'Travail', color: Colors.blue, active: true),
  ];
  List<Note> listNotes = [
    Note(id: 1, title: 'Note 1', content: 'Contenu 1', tags: [1, 2], pinned: true, icon: Icons.note),
    Note(id: 2, title: 'Note 2', content: 'Contenu 2', tags: [], pinned: false, icon: Icons.note_alt),
  ];
  List<Note> sharedNotes = [
    Note(id: 3, title: 'Note partagée', content: 'Contenu partagé', tags: [], pinned: false, icon: Icons.share),
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void reloadList() {
    setState(() {
      isRotating = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        isRotating = false;
        // Rechargez ici vos données
      });
    });
  }

  void addTagFilter(int tagId) {
    setState(() {
      final tag = allTags.firstWhere((t) => t.id == tagId);
      tag.active = !tag.active;
      // appliquer filtres sur notes
    });
  }

  void createNewNote() {
    // Nav vers autre page pour créer note
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
      allTags.add(Tag(id: allTags.length + 1, name: tagName, color: tagColor, active: false));
      closeCreateTag();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF28C28);
    final bgColor = const Color(0xFF111111);
    //final surfaceColor = const Color(0xFF222222);
    //final textColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: NavBar(
          isRotating: isRotating,
          primaryColor: primaryColor,
          onReload: reloadList,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
            child: Column(
              children: [
                SearchBar(
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
                  DangerCard(
                    title: 'Tip of the week',
                    content: 'You can create a new note with +',
                  ),
                if (ifDangerCard)
                  DangerCard(
                    title: 'Attention',
                    content: 'Important alert',
                  ),
                Expanded(
                  child: notesViewMode == 'tag'
                      ? NotesByTagView(allTags: allTags, listNotes: listNotes)
                      : NotesDefaultView(
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
      floatingActionButton: NewNoteButton(
        onPressed: createNewNote,
      ),
    );
  }
}

/// NAVBAR Widget
class NavBar extends StatelessWidget {
  final bool isRotating;
  final Color primaryColor;
  final VoidCallback onReload;

  const NavBar({
    super.key,
    required this.isRotating,
    required this.primaryColor,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TODO SVG logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('SilverNote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            ),
            GestureDetector(
              onTap: onReload,
              child: RotationTransition(
                turns: AlwaysStoppedAnimation(isRotating ? 1 : 0),
                child: Container(
                  width: 32,
                  height: 32,
                  // TODO SVG reload icon bg
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SEARCH BAR Widget
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const SearchBar({super.key, required this.controller, this.hintText = ''});

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        cursorColor: Colors.white,
        style: TextStyle(color: textColor),
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
          suffixIcon: controller.text.isEmpty
              ? GestureDetector(
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: Icon(Icons.search, color: Colors.white60),
                )
              : GestureDetector(
                  onTap: () => controller.clear(),
                  child: Icon(Icons.close, color: Colors.white60),
                ),
        ),
      ),
    );
  }
}

/// TAGS LIST Widget
class TagList extends StatelessWidget {
  final List<Tag> tags;
  final void Function(int) onTagTap;
  final VoidCallback onAddTag;

  const TagList({super.key, required this.tags, required this.onTagTap, required this.onAddTag});

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
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tag.color,
                    borderRadius: BorderRadius.circular(40),
                    border: tag.active ? Border.all(color: Colors.black, width: 2) : null,
                  ),
                  child: Text(tag.name, style: TextStyle(color: useWhiteForeground(tag.color) ? Colors.white : Colors.black)),
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
            child: const Center(child: Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          ),
        ),
      ],
    );
  }
}

/// NOTES VIEWS

class NotesByTagView extends StatelessWidget {
  final List<Tag> allTags;
  final List<Note> listNotes;

  const NotesByTagView({super.key, required this.allTags, required this.listNotes});

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    for (final tag in allTags) {
      final notesForTag = listNotes.where((n) => n.tags.contains(tag.id)).toList();
      if (notesForTag.isEmpty) continue;

      widgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tag.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tag.name, style: TextStyle(color: useWhiteForeground(tag.color) ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ),
          Column(
            children: notesForTag.map((note) => NoteCard(note: note)).toList(),
          ),
        ],
      ));
      widgets.add(const SizedBox(height: 12));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: widgets),
    );
  }
}

class NotesDefaultView extends StatelessWidget {
  final List<Note> pinnedNotes;
  final List<Note> sharedNotes;
  final List<Note> otherNotes;

  const NotesDefaultView({super.key, required this.pinnedNotes, required this.sharedNotes, required this.otherNotes});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          SectionHeader(title: 'Notes épinglées'),
          ...pinnedNotes.map((note) => NoteCard(note: note)),
        ],
        if (sharedNotes.isNotEmpty) ...[
          SectionHeader(title: 'Notes partagées'),
          ...sharedNotes.map((note) => NoteCard(note: note)),
        ],
        if (pinnedNotes.isNotEmpty || sharedNotes.isNotEmpty) ...[
          SectionHeader(title: 'Autres'),
        ],
        ...otherNotes.map((note) => NoteCard(note: note)),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}

/// NOTE CARD Widget
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
        title: Text(note.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(note.content, style: TextStyle(color: textColor)),
        trailing: IconButton(
          icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.orangeAccent),
          onPressed: onPin,
        ),
        onTap: onClick,
      ),
    );
  }
}

/// Danger card for warnings/tips
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
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

/// New note button widget
class NewNoteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NewNoteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFF28C28),
      child: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}

/// Dialog to create a new tag
class CreateTagDialog extends StatefulWidget {
  final String initialName;
  final Color initialColor;
  final void Function(String, Color) onCreate;
  final VoidCallback onCancel;

  const CreateTagDialog({
    super.key,
    this.initialName = '',
    required this.initialColor,
    required this.onCreate,
    required this.onCancel,
  });

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
  late TextEditingController _nameController;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _color = widget.initialColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF28C28), width: 2),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Mon dossier',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Couleur du dossier',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                GestureDetector(
                  onTap: () => _pickColor(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF28C28), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onCreate.call(_nameController.text, _color);
                    },
                    child: Text('Créer mon dossier'.toUpperCase()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF28C28),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onCancel,
                    child: Text('Annuler'.toUpperCase()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A1E00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    setState(() {
      _color = _color == Colors.orange ? Colors.blue : Colors.orange;
    });
  }
}

bool useWhiteForeground(Color backgroundColor, {double bias = 0.0}) {
  int v = sqrt(pow(backgroundColor.red, 2) * 0.299 +
          pow(backgroundColor.green, 2) * 0.587 +
          pow(backgroundColor.blue, 2) * 0.114)
      .round();
  return v < 130 + bias;
}

class Tag {
  final int id;
  final String name;
  final Color color;
  bool active;

  Tag({required this.id, required this.name, required this.color, this.active = false});
}

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
