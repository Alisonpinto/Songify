import 'package:flutter/material.dart';
import 'package:songify_flutter/models/search_type.dart';
import 'package:songify_flutter/theme.dart';

class SearchTypeChip extends StatelessWidget {
  final SearchType searchType;
  final bool selected;
  final void Function(SearchType type, bool selected)? onSelected;

  const SearchTypeChip({super.key, required this.searchType, this.selected = false, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(searchType.label),
      selected: selected,
      selectedColor: AppTheme.primaryYellow,
      backgroundColor: AppTheme.darkCard,
      labelStyle: TextStyle(color: selected ? Colors.black : AppTheme.textPrimary, fontWeight: FontWeight.bold),
      onSelected: onSelected != null ? (selected) => onSelected!(searchType, selected) : null,
    );
  }
}
