import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 디바이스가 태블릿인지 확인 (화면 비율 기반)
/// 태블릿은 가로세로 비율이 정사각형에 가까움 (4:3 = 0.75)
/// 핸드폰은 가로세로 비율이 길쭉함 (16:9 = 0.56, 20:9 = 0.45)
bool isTabletDevice(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final aspectRatio = size.shortestSide / size.longestSide;
  // 비율이 0.6 이상이면 태블릿으로 판단
  return aspectRatio >= 0.6;
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
