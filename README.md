<div align="center">

# <img src="docs/assets/icons/savings.svg" width="40" align="top"> LevelUp Money Life

**แอปบริหารเงินส่วนตัว + Gamification RPG — บันทึกรายการจบใน 3 วินาที**

![Flutter](https://img.shields.io/badge/Flutter-3.38.9-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.8-0175C2?style=flat-square&logo=dart&logoColor=white)
![Drift](https://img.shields.io/badge/Drift-SQLite-003B57?style=flat-square&logo=sqlite&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-Storage-FFA000?style=flat-square)
![BLoC](https://img.shields.io/badge/State-BLoC-8A2BE2?style=flat-square)
![Tests](https://img.shields.io/badge/Tests-31%2F31-22C55E?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

</div>

## <img src="docs/assets/icons/features.svg" width="30" align="top"> ฟีเจอร์เด่น

| | ฟีเจอร์ | สรุป |
| :---: | :--- | :--- |
| <img src="docs/assets/icons/quick-add.svg" width="24"> | **QuickAdd + SmartNumpad** | ประเภท / หมวด / ยอด / โน้ต ใน Bottom Sheet เดียว คำนวณ `+` `-` ได้ |
| <img src="docs/assets/icons/template.svg" width="24"> | **QuickTemplate** | แตะครั้งเดียวบันทึกรายการโปรด + แนะนำ Top 5 ที่ใช้บ่อย |
| <img src="docs/assets/icons/sync.svg" width="24"> | **Reactive Sync** | Drift Stream อัปเดตทุกหน้าแบบ Real-time ไม่ต้อง Reload |
| <img src="docs/assets/icons/gamification.svg" width="24"> | **Gamification RPG** | Level, Rank, Daily Quest, Streak และ `+XP` Toast |
| <img src="docs/assets/icons/budget.svg" width="24"> | **Budget 50/30/20** | แบ่ง Needs / Wants / Savings พร้อมเตือน Overbudget และกราฟ Cash Flow |
| <img src="docs/assets/icons/settings.svg" width="24"> | **Settings** | ธีม System/Light/Dark, ภาษา TH/EN, Export/Import JSON แบบ Offline |

## <img src="docs/assets/icons/architecture.svg" width="30" align="top"> สถาปัตยกรรม

Clean Architecture + Feature-Driven

```mermaid
graph LR
    UI[Pages & Widgets] -->|Event| BLOC[BLoC]
    BLOC --> REPO[Repositories]
    REPO --> DRIFT[(Drift SQLite)]
    REPO --> HIVE[(Hive)]
    DRIFT -.->|Stream| REPO -.->|emit.forEach| BLOC -.->|State| UI
```

## <img src="docs/assets/icons/tech-stack.svg" width="30" align="top"> Tech Stack

| หมวด | ไลบรารี |
| :--- | :--- |
| State | `flutter_bloc`, `equatable` |
| DI | `get_it` |
| Routing | `auto_route` |
| Database | `drift` (SQLite), `hive` (Key-Value) |
| UI | `flutter_tailwind_colors`, `toastification` |
| i18n | `flutter_localizations`, `intl` (`.arb`) |

## <img src="docs/assets/icons/structure.svg" width="30" align="top"> โครงสร้างโปรเจกต์

```text
lib/
├── config/        # Environment & App Config
├── domain/        # datasource, models, repositories, services
├── feature/       # dashboard, budget, gamification, transaction, home
├── i18n/          # TH / EN
├── router/        # AutoRoute
├── shared/        # bloc, components, tokens (Design System)
├── locator.dart   # Dependency Injection
└── main.dart
```

## <img src="docs/assets/icons/getting-started.svg" width="30" align="top"> เริ่มต้นใช้งาน

ต้องมี: [FVM](https://fvm.app/) หรือ Flutter `3.38.9`, Android Studio / Xcode

```bash
git clone https://github.com/Theeraphat-S/levelup-money-life-mobile.git
cd levelup-money-life-mobile
fvm use 3.38.9
fvm flutter pub get
dart run build_runner build --delete-conflicting-outputs
fvm flutter run --flavor dev -t lib/main.dart --dart-define=flavor=dev
```

## <img src="docs/assets/icons/codegen.svg" width="30" align="top"> Code Generation

| งาน | คำสั่ง |
| :--- | :--- |
| Drift / AutoRoute | `dart run build_runner build --delete-conflicting-outputs` (หรือ `watch`) |
| i18n | `./generate_i18n.sh` — รวม `.arb` ใน `lib/i18n/locals/<page>/` |
| Feature ใหม่ | `./create_feature.sh <name> [--appbar] [--bottombar]` |

## <img src="docs/assets/icons/testing.svg" width="30" align="top"> Testing

```bash
flutter analyze
flutter test
```

ครอบคลุม Drift Streams, GamificationEngine, SmartNumpad Parser, QuickTemplate และ Layout 320–360dp (ไม่มี Overflow)

## <img src="docs/assets/icons/build.svg" width="30" align="top"> Build & Deploy

Flavors: `local`, `dev`, `prod`

| แพลตฟอร์ม | Dev | Prod |
| :--- | :--- | :--- |
| Android | `./build_apk_dev.sh` | `./build_apk_prod.sh` |
| iOS | `./build_ipa_dev.sh` | `fvm flutter build ipa --release` |
| Windows | `build_windows_dev.bat` | `build_windows_prod.bat` |

iOS: `cd ios && pod install` แล้วตั้ง Signing ใน `ios/Runner.xcworkspace`

## <img src="docs/assets/icons/standards.svg" width="30" align="top"> Coding Standards

- ศัพท์ Domain ยึดตาม [`CONTEXT.md`](CONTEXT.md)
- State / Event ใช้ `Equatable` ทุกตัว, รับ Stream ผ่าน `emit.forEach`
- DI ใน [`locator.dart`](lib/locator.dart): Repository → `registerLazySingleton`, BLoC → `registerFactory`
- ตั้งชื่อ: ไฟล์ `snake_case`, คลาส `UpperCamelCase`, ตัวแปร `lowerCamelCase`

## <img src="docs/assets/icons/license.svg" width="30" align="top"> License

[MIT](LICENSE) © [Theeraphat-S](https://github.com/Theeraphat-S) · Icons by [Lordicon](https://lordicon.com/)
