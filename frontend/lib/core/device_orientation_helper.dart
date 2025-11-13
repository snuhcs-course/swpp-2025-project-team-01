import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 디바이스가 태블릿인지 확인 (화면 shortestSide 기반)
bool isTabletDevice(BuildContext context) {
  final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
  return isTablet;
}

/// 디바이스 타입에 따라 화면 방향 설정
/// 태블릿: 자유 회전 허용, 핸드폰: 세로 고정
void lockToCurrentOrientation(BuildContext context) {
  final isTablet = isTabletDevice(context);

  if (isTablet) {
    // 태블릿: 자유 회전 허용
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  } else {
    // 핸드폰: 세로 모드로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
