import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';

/// Slim, persistent search bar for the Golfers page.
/// Stays pinned at the top and filters all views (Discover, Requests, Friends).
class GolferSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onChanged;
  final bool hasActiveFilters;

  const GolferSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFilterPressed,
    this.onChanged,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fairwayLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              cursorColor: AppColors.sunsetGold,
              decoration: InputDecoration(
                hintText: 'Search golfers...',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          // Filter button
          GestureDetector(
            onTap: onFilterPressed,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: hasActiveFilters
                    ? AppColors.fairwayLight.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
