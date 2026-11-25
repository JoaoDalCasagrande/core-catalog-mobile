import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Um pedaço colorido da régua (uma peça da build).
class RulerSegment {
  final int cents;
  final Color color;

  const RulerSegment(this.cents, this.color);
}

/// A "régua" do orçamento: cada peça ocupa uma fatia proporcional ao preço,
/// com a linha de limite do orçamento e as marcas de 0%, 25%, 50%, 75% e 100%.
///
/// Como no web, a escala vai até o maior valor entre orçamento e total,
/// para a régua não sair da tela quando a build estoura.
class BudgetRuler extends StatelessWidget {
  const BudgetRuler({
    super.key,
    required this.segments,
    required this.maxBudgetCents,
    this.showLimit = true,
  });

  final List<RulerSegment> segments;
  final int maxBudgetCents;
  final bool showLimit;

  static const _trackHeight = 16.0;
  static const _marks = [0, 25, 50, 75, 100];

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.cents);
    final scale = [maxBudgetCents, total, 1].reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double x(num cents) => (cents / scale) * width;

        return SizedBox(
          height: _trackHeight + 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Trilho + fatias
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _trackHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    color: AppColors.bgSunken,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in segments)
                          Container(
                            width: x(s.cents).clamp(0, width).toDouble().floorToDouble(),
                            color: s.color,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Linha do limite do orçamento
              if (showLimit)
                Positioned(
                  left: (x(maxBudgetCents) - 1).clamp(0, width - 2).toDouble(),
                  top: -4,
                  width: 2,
                  height: _trackHeight + 8,
                  child: const ColoredBox(color: AppColors.textPrimary),
                ),
              // Marcas da escala
              for (final p in _marks) ...[
                Positioned(
                  left: (x(maxBudgetCents * p / 100) - 0.5)
                      .clamp(0, width - 1)
                      .toDouble(),
                  top: _trackHeight + 4,
                  width: 1,
                  height: 6,
                  child: const ColoredBox(color: AppColors.borderStrong),
                ),
                Positioned(
                  left: x(maxBudgetCents * p / 100),
                  top: _trackHeight + 12,
                  child: FractionalTranslation(
                    translation: Offset(
                      p == 0 ? 0 : (p == 100 ? -1 : -0.5),
                      0,
                    ),
                    child: Text(
                      formatMark(maxBudgetCents * p / 100),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
