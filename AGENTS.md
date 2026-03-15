# AGENTS.md

이 저장소에서 작업할 때 참고할 수 있는 간단한 작업 가이드입니다.

## 프로젝트 개요

- 프로젝트명: `Chosun Survivor`
- 기술 스택: `Flutter + Flame`
- 주 타깃: `Windows`
- 장르: 뱀파이어 서바이버즈 스타일 생존 액션

## 우선 확인할 실행 명령

### 개발 실행

```bash
flutter run -d windows
```

### 정적 분석

```bash
flutter analyze --no-pub
```

`flutter analyze`를 그냥 실행하면 패키지 최신 버전 안내가 같이 나올 수 있으니, 보통은 `--no-pub`를 권장합니다.

### 테스트

```bash
flutter test
```

### Windows 디버그 빌드

```bash
flutter build windows --debug --no-pub
```

## 코드 구조

- `lib/main.dart`
  - 앱 진입점
- `lib/app`
  - 로비, 선택 화면, 상점, 오버레이, 맵 에디터
- `lib/game/survivor_game.dart`
  - 메인 게임 루프와 충돌, 드랍, HUD 갱신
- `lib/game/survivor_entities.dart`
  - 플레이어, 적, 무기 개체, 투사체, 특수 무기 컴포넌트
- `lib/game/survivor_run_config.dart`
  - 캐릭터, 무기, 맵 정의 데이터
- `lib/game/survivor_meta_progression.dart`
  - 상점 영구 강화 정의
- `lib/game/survivor_profile_repository.dart`
  - 프로필 저장 / 로드
- `lib/game/custom_map_repository.dart`
  - 커스텀 맵 저장 / 로드
- `test`
  - 위젯 테스트와 핵심 규칙 테스트

## 작업 시 유의사항

- 이 프로젝트는 `한 파일에 몰아넣기`보다 역할별 분리를 선호합니다.
- 새 기능을 추가할 때는 가능하면 아래 순서를 유지합니다.
  1. 데이터 정의
  2. 게임 로직 연결
  3. UI 반영
  4. 테스트 보강
- 새 무기나 새 캐릭터를 추가하면 보통 함께 확인해야 할 위치는 다음과 같습니다.
  - `survivor_run_config.dart`
  - `survivor_entities.dart`
  - `survivor_game.dart`
  - `survivor_upgrades.dart`
  - 관련 위젯 테스트

## 저장 데이터

앱 지원 디렉터리에 아래 파일이 저장됩니다.

- `profile.json`
  - 골드
  - 상점 영구 강화 레벨
- `custom_maps.json`
  - 사용자 제작 맵

테스트 중 프로필 상태가 꼬였다고 느껴지면 이 파일들을 확인하면 됩니다.

## 입력 관련 메모

- 키보드와 Xbox 패드를 모두 지원합니다.
- 선택 화면 입력은 셸 레벨에서 직접 처리하는 경우가 많습니다.
- 메뉴 선택, 레벨업 카드 선택, 패드 입력을 수정할 때는 위젯 포커스와 셸 입력이 충돌하지 않는지 같이 확인하는 편이 안전합니다.

## 문서 갱신 기준

게임의 흐름이나 기능 목록이 바뀌면 아래 문서도 함께 갱신하는 것을 권장합니다.

- `README.md`
- 이 `AGENTS.md`

특히 아래 항목은 변경 시 README에 반영하는 편이 좋습니다.

- 캐릭터 목록
- 무기 목록
- 상점 영구 강화 목록
- 조작 키
- 실행 / 빌드 명령
- 저장 데이터 구조
