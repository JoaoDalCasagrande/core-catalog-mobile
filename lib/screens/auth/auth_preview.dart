import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AuthPreview extends StatelessWidget {
  const AuthPreview({super.key});

  static const _items = [
    ('CPU', 'Ryzen 7 7800X3D', 'R\$ 1.899,00'),
    ('GPU', 'GeForce RTX 4070 Super', 'R\$ 4.299,00'),
    ('RAM', 'Corsair Vengeance DDR5 32 GB', 'R\$ 799,00'),
    ('Armazenamento', 'Samsung 990 PRO 1 TB', 'R\$ 749,00'),
  ];

  static const _segments = [
    (23.5, AppColors.brand),
    (53.7, AppColors.brand2),
    (9.8, AppColors.brand3),
    (9.1, AppColors.brand4),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appCardDecoration(color: AppColors.bgPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sua build, dentro do orçamento',
              style: AppText.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Some o preço e o consumo de cada peça e veja na régua quanto ainda cabe.',
            style: AppText.subtitle,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 14,
              color: AppColors.bgSunken,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (percent, color) in _segments)
                    Expanded(
                      flex: (percent * 10).round(),
                      child: ColoredBox(color: color),
                    ),
                  const Expanded(flex: 39, child: SizedBox()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: Text('R\$ 7.746,00 de R\$ 8.000,00',
                    style: AppText.label),
              ),
              Text('357 W', style: AppText.secondary),
            ],
          ),
          const SizedBox(height: 8),
          for (final (category, name, price) in _items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(category, style: AppText.secondary),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(price,
                      style: AppText.label
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
