import 'package:flutter/material.dart';

import '../app_theme.dart';

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
          const _SettingsSectionTitle('Paramètres généraux'),
          const SizedBox(height: 16),
          _SettingsRowLabelControl(
            label: 'Theme',
            control: _ThemeDropdown(
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
          const _SettingsSectionTitle('Paramètres base de données'),
          const SizedBox(height: 16),

          _SettingsRowActionRight(
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

          _SettingsRowActionRight(
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

          _SettingsRowActionRight(
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25524)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Données réinitialisées.')));
    }
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String text;
  const _SettingsSectionTitle(this.text);
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

class _SettingsRowLabelControl extends StatelessWidget {
  final String label;
  final Widget control;
  const _SettingsRowLabelControl({required this.label, required this.control});
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

class _SettingsRowActionRight extends StatelessWidget {
  final String label;
  final Widget child;
  const _SettingsRowActionRight({required this.label, required this.child});
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

class _ThemeDropdown extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ThemeDropdown({required this.isDark, required this.onChanged});

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