import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  final String currentPeriod;
  final Function(String) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton(context, 'day', 'يوم'),
          _buildPeriodButton(context, 'week', 'أسبوع'),
          _buildPeriodButton(context, 'month', 'شهر'),
          _buildPeriodButton(context, 'year', 'سنة'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, String period, String label) {
    final isSelected = currentPeriod == period;
    
    return Expanded(
      child: InkWell(
        onTap: () => onPeriodChanged(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
