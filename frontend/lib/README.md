# Frontend 디렉토리
lib/
├─ main.dart                     # 앱 엔트리, MaterialApp + 라우터 연결
├─ app_router.dart               # 라우트 테이블 및 onGenerateRoute 정의

├─ core/                         # 앱 전역에서 쓰이는 공통 코드
│  ├─ theme/
│  │  ├─ color_scheme.dart       # ColorScheme, ThemeExtension(AppHighlights) 정의
│  │  └─ app_theme.dart          # ThemeData(light/dark) 정의
│  ├─ constants.dart             # 여백/라운드/쉐도우 등 디자인 토큰
│  └─ utils.dart                 # 공통 유틸 (시간 포맷, HEX 변환 등)

├─ data/
│  ├─ models.dart                # Subject, Lecture, Tag 모델
│  └─ repository.dart            # In-memory 저장소 (추후 Hive/Remote로 교체 가능)

├─ shared/
│  └─ widgets.dart               # 재사용 가능한 작은 위젯(PrimaryButton, EmptyState 등)

├─ features/
│  ├─ home/                      # 메인 홈 화면
│  │  ├─ home_screen.dart        # 홈 메인 (필터/즐겨찾기/드로어/리스트)
│  │  └─ home_widgets.dart       # 홈 전용 소규모 위젯(필터바, 패널, 타일 등)

│  ├─ search/
│  │  └─ search_screen.dart      # 검색 화면

│  ├─ edit/                      # 수업 추가 화면
│  │  └─ lecture_form_screen.dart

│  ├─ subjects/
│  │  └─ subjects_edit_screen.dart # 과목 수정 화면 (과목별 강의 정렬/삭제 등)

│  ├─ tags/
│  │  └─ tags_edit_screen.dart   # 태그 수정 화면 (이름/색상 변경, 추가/삭제)

│  ├─ player/
│  │  └─ player_screen.dart      # 강의 플레이어 (세로/가로 전환, 슬라이드/스크립트/컨트롤)

│  └─ settings/                  # 설정 메인 + 상세 화면
│     ├─ settings_screen.dart    # 설정 메인 목록
│     ├─ display_mode_screen.dart# 디스플레이 모드
│     ├─ tts_screen.dart         # TTS 설정
│     ├─ accessibility_screen.dart # 접근성 설정
│     ├─ language_screen.dart    # 언어 선택
│     └─ help_screen.dart        # Help


# 업무 분담
## 최은우
	•	담당 폴더: features/home/, features/edit/, features/search/
	•	홈 화면(필터, 즐겨찾기, 드로어), 수업 추가 화면, 검색 화면 구현

## 윤수
	•	담당 폴더: features/settings/, features/subjects/, features/tags/
	•	설정 메인 + 상세 페이지(디스플레이, TTS, 접근성, 언어, Help), 과목 수정 화면, 태그 수정 화면 구현

## 정상현
	•	담당 폴더: features/player/
	•	플레이어 화면(세로/가로 전환, 슬라이드, 스크립트, 컨트롤 UI) 구현