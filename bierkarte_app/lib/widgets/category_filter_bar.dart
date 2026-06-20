import 'package:flutter/material.dart';

import '../models/beer_place.dart';
import '../theme/app_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  final Set<PlaceCategory> selected;
  final ValueChanged<PlaceCategory> onToggle;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBlue,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: PlaceCategory.values.map((category) {
            final isSelected = selected.contains(category);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text('${category.markerEmoji} ${category.label}'),
                selected: isSelected,
                onSelected: (_) => onToggle(category),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
