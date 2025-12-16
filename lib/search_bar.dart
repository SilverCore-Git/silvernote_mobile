import 'package:flutter/material.dart';

import '../app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const SearchBarWidget({super.key, required this.controller, this.hintText = ''});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).customColors.textColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).customColors.noteCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
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