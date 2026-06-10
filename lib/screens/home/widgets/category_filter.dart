// lib/screens/home/widgets/category_filter.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../models/event_model.dart';

class CategoryFilter extends StatelessWidget {
  final EventCategory? selectedCategory;
  final Function(EventCategory?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<Map<String, dynamic>> categories = [
    {'label': 'Tout', 'icon': '🌟', 'value': null},
    {'label': 'Concert', 'icon': '🎵', 'value': EventCategory.concert},
    {'label': 'Soirée', 'icon': '🎉', 'value': EventCategory.soiree},
    {'label': 'Rencontre', 'icon': '🤝', 'value': EventCategory.rencontre},
    {'label': 'Jeux', 'icon': '🎮', 'value': EventCategory.jeux},
    {'label': 'Sport', 'icon': '⚽', 'value': EventCategory.sport},
    {'label': 'Culture', 'icon': '🎭', 'value': EventCategory.culture},
    {'label': 'Festival', 'icon': '🎪', 'value': EventCategory.festival},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['value'];

          return GestureDetector(
            onTap: () => onCategorySelected(category['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Text(category['icon'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    category['label'],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}