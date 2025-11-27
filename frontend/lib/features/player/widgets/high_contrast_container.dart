import 'package:flutter/material.dart';

class HighContrastContainer extends StatelessWidget {
  const HighContrastContainer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // HiveManager를 통해 설정을 직접 확인하거나, 부모로부터 enabled를 받을 수 있음.
    // 여기서는 enabled 파라미터를 우선하고, 기본적으로 HiveManager를 확인하는 패턴을 권장하지만
    // 호출하는 쪽에서 StreamBuilder/ValueListenableBuilder 등을 사용할 것이므로
    // 단순하게 enabled 상태에 따라 필터를 적용하는 역할만 수행.

    if (!enabled) {
      return child;
    }

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: child,
    );
  }
}
