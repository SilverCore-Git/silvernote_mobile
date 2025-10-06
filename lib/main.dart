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
                            return const MainPage();
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

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isRotating = false;
  bool ifOpenCreateTag = false;
  bool tip = false;
  bool ifDangerCard = false;

  List<Tag> allTags = []; 
  List<Note> listNotes = [];
  List<Note> sharedNotes = [];

  @override
  void initState() {
    super.initState();
    // TODO : GO TO EDITOR
  }

  void reloadList() async {
    if (isRotating) return;

    setState(() {
      isRotating = true;
    });

    // TODO : RELOAD DATA HERE

    setState(() {
      isRotating = false;
    });
  }

  void addTagFilter(int tagId) {
    setState(() {
        // TODO : APPLY FILTER TAGS
    });
  }

  void createNewNote() {
    // TODO : GO TO EDITOR
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SilverNote'),
        actions: [
          GestureDetector(
            onTap: reloadList,
            child: RotationTransition(
              turns: AlwaysStoppedAnimation(isRotating ? 1 : 0),
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar placeholder
          Container(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (value) {
                // TODO : ADD RESEARCH
              },
            ),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allTags.length,
              itemBuilder: (context, index) {
                final tag = allTags[index];
                return GestureDetector(
                  onTap: () => addTagFilter(tag.id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: tag.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tag.active ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(tag.name)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listNotes.length,
              itemBuilder: (context, index) {
                final note = listNotes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
// TODO : EXEMPLES HERE :
class Tag {
  final int id;
  final String name;
  bool active;
  final Color color;

  Tag({required this.id, required this.name, this.active = false, required this.color});
}

class Note {
  final int id;
  final String title;
  final String content;
  final List<int> tags;
  final bool pinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.pinned,
  });
}
