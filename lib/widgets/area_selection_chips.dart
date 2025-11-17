import 'package:flutter/material.dart';
import '../models/area_info.dart';

/// エリア選択チップ
class AreaSelectionChips extends StatelessWidget {
  final String? selectedArea;
  final Function(String?) onAreaSelected;

  const AreaSelectionChips({
    super.key,
    required this.selectedArea,
    required this.onAreaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 「全て」チップ
          _buildChip(
            context: context,
            area: null,
            label: '全て',
            emoji: '🗺️',
            isSelected: selectedArea == null,
          ),
          
          const SizedBox(width: 8),
          
          // 各エリアチップ
          ...AreaInfo.areas.map((area) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                context: context,
                area: area,
                label: area.displayName,
                emoji: area.emoji,
                isSelected: selectedArea == area.id,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// チップを構築
  Widget _buildChip({
    required BuildContext context,
    required AreaInfo? area,
    required String label,
    required String emoji,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onAreaSelected(area?.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
