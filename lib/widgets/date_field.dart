import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Campo de data (substitui o `<input type="date">` do web).
/// Trabalha com o texto "AAAA-MM-DD"; null quando vazio.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    var current = value != null ? DateTime.tryParse(value!) : null;
    if (current != null && current.isAfter(now)) current = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: label,
    );
    if (picked != null) onChanged(toIsoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: appInputDecoration(
          label: label,
          hint: 'dd/mm/aaaa',
          suffixIcon: hasValue && enabled
              ? IconButton(
                  tooltip: 'Limpar data',
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined),
        ).copyWith(enabled: enabled),
        child: Text(
          hasValue ? formatDateBr(value) : '',
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
