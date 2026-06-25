# Build Android — SDK 36 + 16 KB page size

Salenote Android target **compileSdk / targetSdk 36**, hỗ trợ **16 KB page size** (Google Play).

## Yêu cầu máy build

| Thành phần | Phiên bản |
|---|---|
| **Flutter SDK** | **3.19+** (build được). **3.35+** khuyến nghị cho engine 16 KB đầy đủ |
| **JDK** | **17** |
| **Android SDK** | Platform **36** |
| RAM | 8 GB+ (build APK arm64 ~4 GB) |

```powershell
flutter upgrade
flutter doctor -v
# Đảm bảo Java 17 và Android SDK 36 OK
```

## Cấu hình đã bật trong project

- `compileSdk 36`, `targetSdk 36`, `minSdk 24`
- AGP **8.9.1**, Gradle **8.11.1**, Kotlin **2.1.0**
- NDK **r28** — ELF align 16 KB
- `packaging.jniLibs.useLegacyPackaging = false` — zip-align 16 KB
- Edge-to-edge Android 15+: `MainActivity` + `SystemInsetsScope` + `values-v35/styles.xml`

## Build APK release

```powershell
cd app
flutter pub get
.\build_release_apk.ps1
# Output: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

Universal (nhiều RAM hơn):

```powershell
.\build_release_apk.ps1 -Universal
```

## Build AAB cho Google Play

```powershell
flutter build appbundle --release --target-platform android-arm64
```

## Kiểm tra 16 KB (tuỳ chọn)

Trên máy có Android SDK:

```powershell
# Sau khi build APK
$sdk = $env:ANDROID_HOME
& "$sdk\cmdline-tools\latest\bin\apkanalyzer.bat" apk summary build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

Hoặc upload AAB lên Play Console → **App bundle explorer** → xem cảnh báo 16 KB.

## Edge-to-edge (Android 15+)

- **Android 15+**: nội dung không tràn status/nav bar nhờ `SystemInsetsScope` + `SafeArea` bottom nav.
- **Android 14 trở xuống**: `viewPadding` ≈ 0 → giao diện giữ nguyên như trước.

## Lưu ý minSdk 24

Thiết bị Android 7.0 trở xuống (API < 24) không cài được bản mới. Đây là mặc định Flutter 3.35+ và cần cho toolchain hiện đại.
