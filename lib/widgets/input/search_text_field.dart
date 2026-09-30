import 'package:flutter/material.dart';
import 'package:songify_flutter/models/search_type.dart';

import '../../theme.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController searchController;
  final SearchType searchType;

  final Widget? suffixIcon;
  final void Function(String text)? onSubmitted;
  final void Function(String text)? onChanged;

  const SearchTextField({
    super.key,
    required this.searchController,
    this.searchType = SearchType.all,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: searchType.hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.darkSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primaryYellow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primaryYellow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
        ),
      ),
      onSubmitted: onSubmitted,
      onChanged: onChanged,
    );
  }
}
