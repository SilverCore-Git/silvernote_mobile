import 'dart:math';

import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const appUrl = 'https://test-clerk.dev.silvernote.fr/';
const String clerkPublishableKey = String.fromEnvironment('PUBLISHABLE_KEY', defaultValue: '');

const _border = Color(0xFF2F2F2F);
const _textDark = Color(0xFF2A2A2A);
const _hint = Color(0xFF7F7F7F);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: const Color(0xFFF28C28),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF28C28)),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2A2420),
  primaryColor: const Color(0xFFF28C28),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF28C28)),
);

class CustomColors {
  final Color noteCardColor;
  final Color textColor;
  CustomColors({required this.noteCardColor, required this.textColor});
}

final customColorsLight = CustomColors(
  noteCardColor: const Color(0xFFFFF5E8),
  textColor: const Color(0xFF222222),
);

final customColorsDark = CustomColors(
  noteCardColor: const Color(0xFF3A322D),
  textColor: const Color(0xFFEAE0D7),
);

extension CustomThemeExtension on ThemeData {
  CustomColors get customColors =>
      brightness == Brightness.dark ? customColorsDark : customColorsLight;
}

class ThemeController extends ChangeNotifier {
  bool _isDark = false;

  ThemeData get theme => _isDark ? darkTheme : lightTheme;

  bool get isDark => _isDark;

  void toggleTheme(bool isDark) {
    _isDark = isDark;
    notifyListeners();
  }
}

final themeController = ThemeController();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ClerkAuth(
      config: ClerkAuthConfig(publishableKey: clerkPublishableKey),
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeController.theme,
            home: const SilverNoteApp(),
          );
        },
      ),
    ),
  );
}

class SilverNoteApp extends StatelessWidget {
  const SilverNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top - 7.5;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, _) {
          final inset = MediaQuery.of(context).viewInsets.bottom;
          final maxShift = 105.0;
          final shift = inset.clamp(0.0, maxShift);

          return Stack(
            children: [
              Container(
                height: topPadding,
                color: Theme.of(context).primaryColor,
              ),
              Center(
                child: AnimatedPadding(
                  padding: EdgeInsets.only(bottom: shift),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: ClerkErrorListener(
                    child: ClerkAuthBuilder(
                      signedInBuilder: (context, auth) {
                        final user = auth.user;
                        final userId = user?.id;
                        return HomePage(userId: userId);
                      },
                      signedOutBuilder: (context, authState) =>
                          const ClerkAuthentication(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
    // Diffère pour avoir un BuildContext correctement monté sous ClerkAuth
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notes = await appelApi(context);
      if (!mounted) return;
      setState(() {
        allNotesSource = notes;
        listNotes = List<Note>.from(notes);
        // sharedNotes si besoin: filtre sur une règle ou laisse vide selon ton API
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
      _refreshTurns += 1.0; // déclenche exactement 1 tour
      isRotating = true;     // si tu veux aussi un état loading
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
      final activeIds = allTags
          .where((t) => t.active)
          .map((t) => t.id)
          .toList();
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
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
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
                  DangerCard(title: 'Attention', content: 'Important alert'),
                Expanded(
                  child: notesViewMode == 'tag'
                      ? NotesByTagView(allTags: allTags, listNotes: listNotes)
                      : NotesMasonryView(
                          allTags: allTags,
                          pinnedNotes: listNotes
                              .where((n) => n.pinned)
                              .toList(),
                          sharedNotes: sharedNotes,
                          otherNotes: listNotes
                              .where((n) => !n.pinned)
                              .toList(),
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
  final userId = user?.id;
  debugPrint('appelApi: userId=$userId');

  if (userId == null || userId.isEmpty) {
    debugPrint('appelApi: userId manquant');
    return <Note>[];
  }

  final uri = Uri.parse('https://api.silvernote.fr/api/db/get/user/notes?user_id=$userId');
  debugPrint('appelApi: GET $uri'); // log 2

  try {

      const String coarseToken = String.fromEnvironment('COARSE_TOKEN', defaultValue: '');

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': '$coarseToken',
      },
    );

    debugPrint('appelApi: status=${resp.statusCode} len=${resp.body.length}'); // log 3

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('status=${resp.statusCode}');
      debugPrint('body[0..300]=${resp.body.substring(0, resp.body.length.clamp(0, 300))}');
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
        .map((e) {
          if (e is Map) {
            return NoteApiMapper.fromApi(e.cast<String, dynamic>());
          } else {
            return null;
          }
        })
        .whereType<Note>()
        .toList();

    debugPrint('appelApi: parsed notes=${notes.length}');
    return notes;
  } catch (e) {
    debugPrint('appelApi: error $e');
    return <Note>[];
  }
}

/// NAVBAR Widget
class NavBar extends StatelessWidget {
  final bool isRotating;
  final Color primaryColor;
  final VoidCallback onReload;
  final double refreshTurns;

  const NavBar({
    super.key,
    required this.isRotating,
    required this.primaryColor,
    required this.onReload,
    required this.refreshTurns,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icon/SilverNote_Logo.svg',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SilverNote',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onReload,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 400), // vitesse du tour
                    turns: refreshTurns,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _divider = Color(0x33FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).customColors.noteCardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).customColors.noteCardColor,
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: Theme.of(context).customColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).customColors.textColor,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Paramètres généraux
          const __SettingsSectionTitle('Paramètres généraux'),
          const SizedBox(height: 16),
          __SettingsRowLabelControl(
            label: 'Theme',
            control: __ThemeDropdown(
              isDark: themeController.isDark,
              onChanged: (val) {
                themeController.toggleTheme(val);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _divider),

          const SizedBox(height: 16),
          const __SettingsSectionTitle('Paramètres base de données'),
          const SizedBox(height: 16),

          __SettingsRowActionRight(
            label: 'Télécharger la base de donnée',
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF28C28),
                foregroundColor: Theme.of(context).customColors.textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _onDownload,
              child: const Text('Télécharger'),
            ),
          ),
          const SizedBox(height: 16),

          __SettingsRowActionRight(
            label: 'Téléverser une base de donnée',
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF28C28), width: 2),
                foregroundColor: Theme.of(context).customColors.textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Theme.of(context).customColors.noteCardColor,
              ),
              onPressed: _onUpload,
              child: const Text('Téléversez un fichier'),
            ),
          ),
          const SizedBox(height: 16),

          __SettingsRowActionRight(
            label: 'Réinitialiser les données',
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE25524),
                foregroundColor: Theme.of(context).customColors.textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _onReset,
              child: const Text('Réinitialiser'),
            ),
          ),
        ],
      ),
    );
  }

  void _onDownload() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Téléchargement...')));
  }

  void _onUpload() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Téléversement...')));
  }

  void _onReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A322D),
        title: const Text(
          'Réinitialiser les données',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cette action supprimera toutes les données locales.',
          style: TextStyle(color: Color(0xFFEAE0D7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFE25524)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Données réinitialisées.')));
    }
  }
}

// Widgets privés renommés pour éviter tout conflit

class __SettingsSectionTitle extends StatelessWidget {
  final String text;
  const __SettingsSectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).customColors.textColor,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    );
  }
}

class __SettingsRowLabelControl extends StatelessWidget {
  final String label;
  final Widget control;
  const __SettingsRowLabelControl({required this.label, required this.control});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).customColors.textColor,
              fontSize: 16,
            ),
          ),
        ),
        control,
      ],
    );
  }
}

class __SettingsRowActionRight extends StatelessWidget {
  final String label;
  final Widget child;
  const __SettingsRowActionRight({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).customColors.textColor,
              fontSize: 16,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class __ThemeDropdown extends StatelessWidget {
  final bool isDark; // booléen représentant ton thème personnalisé
  final ValueChanged<bool> onChanged;

  const __ThemeDropdown({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).customColors.noteCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).customColors.textColor,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: isDark,
          items: const [
            DropdownMenuItem<bool>(value: false, child: Text('Clair')),
            DropdownMenuItem<bool>(value: true, child: Text('Sombre')),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
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
    final textColor = Theme.of(context).customColors.textColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).customColors.noteCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        cursorColor: Theme.of(context).customColors.textColor,
        style: TextStyle(color: textColor),
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).customColors.textColor),
          border: InputBorder.none,
          suffixIcon: controller.text.isEmpty
              ? GestureDetector(
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context).customColors.textColor,
                  ),
                )
              : GestureDetector(
                  onTap: () => controller.clear(),
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).customColors.textColor,
                  ),
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

/// NOTES VIEWS

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
      final notesForTag = listNotes
          .where((n) => n.tags.contains(tag.id))
          .toList();
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
                  color: useWhiteForeground(tag.color)
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              children: notesForTag
                  .map((note) => NoteCard(note: note))
                  .toList(),
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
    final spacing = 12.0;

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
              padding: EdgeInsets.symmetric(horizontal: spacing),
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
      margin: EdgeInsets.symmetric(vertical: 8),
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

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

  @override
  Widget build(BuildContext context) {
    // Hauteur variable façon masonry selon contenu
    final title = (note.title.isEmpty) ? 'NOTE SANS TITRE' : note.title;
    final content = note.content;

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
          // Ligne titre + pin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO SVG emoji/icône
              Icon(
                note.icon,
                size: 18,
                color: Theme.of(context).customColors.textColor,
              ),
              const SizedBox(width: 8),
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

          if (content.trim().isNotEmpty)
            Text(
              content,
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
                color: _hint.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: 12),

          // Tags en bas si présents
          if (note.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: note.tags.map((tagId) {
                final t = _findTag(tagId);
                final chipText = t?.name ?? 'TAG $tagId';
                final chipColor = t?.color ?? const Color(0xFFFFF5E8);
                final borderColor = _border.withOpacity(0.25);
                final fg = useWhiteForeground(chipColor)
                    ? Colors.white
                    : _textDark.withOpacity(0.85);

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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
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
      onPressed: onPressed,
      child: const Icon(Icons.add),
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
                      border: Border.all(
                        color: const Color(0xFFF28C28),
                        width: 2,
                      ),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF28C28),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Créer mon dossier'.toUpperCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onCancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A1E00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Annuler'.toUpperCase()),
                  ),
                ),
              ],
            ),
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
  int v = sqrt(
    pow(backgroundColor.red, 2) * 0.299 +
        pow(backgroundColor.green, 2) * 0.587 +
        pow(backgroundColor.blue, 2) * 0.114,
  ).round();
  return v < 130 + bias;
}

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
