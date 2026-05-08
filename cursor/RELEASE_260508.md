# release-260508 说明

> 这是个人使用的发布分支。基于上游主分支 `b7b40c557 Release 2.0.7`（`upstream/main`），
> 合入了两条本地分支的全部改动：`6vDiy`（功能集合）+ `byo`（包名/品牌定制）。

## 合入分支与功能列表

### `6vDiy` —— 功能定制集合

5 个功能性 commit + 1 个 rebase 后的修复 commit：

1. **稍后再看：长按视频卡片直接添加** (`feat: enable direct add video to watch later with long press`)
   - 新增设置项「长按直接添加到稍后再看」(`SettingBoxKey.longPressToWatchLater`，默认关闭)。
   - 开启后长按视频卡片直接调用 `UserHttp.toViewLater`，不再弹出图片保存对话框；关闭则保持上游行为。
   - 主要文件：`lib/common/widgets/image/image_save.dart`、`lib/pages/setting/models/extra_settings.dart`、`lib/utils/storage_*.dart`。

2. **底部导航：增加「稍后再看」标签 + 双击置顶/刷新** (`feat: add later page to bottom navigation and enable double tap to scroll/refresh`)
   - `NavigationBarType` 新增 `later` 项；底部栏配置在 `lib/pages/setting/pages/bar_set.dart` 中默认不勾选「稍后再看」（与上游 `MainController.setNavBarConfig` 行为一致）。
   - 新增 `LaterPageController`，挂在 `MainController` 上，用于双击底部「稍后再看」标签时滚动到顶部或下拉刷新。
   - 主要文件：`lib/pages/later/page_controller.dart`、`lib/models/common/nav_bar_config.dart`、`lib/pages/main/controller.dart`。

3. **稍后再看页：去 Tab + 滑动删除 + 撤销** (`feat: refactor watch later page - remove tabs, add swipe-to-delete with undo`)
   - 「稍后再看」页移除多 Tab，仅展示「全部」列表。
   - 列表项支持左滑（`Dismissible`）删除；底部出现「撤销」浮层，5 秒内可恢复。
   - 主要文件：`lib/pages/later/{view,child_view,controller,base_controller}.dart`、`lib/pages/later_search/controller.dart`。

4. **新增 Pin 功能（视频 / 专栏置顶）** (`feat: add Pin functionality for videos and articles`)
   - 在「我的」页顶部展示 Pin 项；视频/专栏的右上角菜单新增「Pin」操作。
   - 一次只 Pin 一个内容，可在「我的」页一键取消。
   - 持久化键：`SettingBoxKey.pinnedItem`。
   - 主要文件：`lib/services/pin_service.dart`、`lib/pages/{video,mine,article}/view.dart`。

5. **专栏：阅读位置记忆 + 滚动到顶按钮** (`feat: add article reading position tracking and scroll-to-top button`)
   - 新增 `ArticleReadingPositionService`，按 `type:id` 维度记忆每篇文章的滚动位置（带防抖 1s）。
   - 重新进入文章时自动恢复上次的阅读位置。
   - 视图层只接入 `controller.articleScrollController` 与 `saveReadingPosition` 钩子；上游 main 已自带 FAB 与底部操作栏，未单独再加滚动到顶按钮。
   - 主要文件：`lib/services/article_reading_position_service.dart`、`lib/pages/article/{controller,view}.dart`。

6. **rebase 后修复** (`fix: post-rebase compile errors in later page controllers`)
   - `lib/pages/later/page_controller.dart`：把不存在的 `package:PiliPlus/utils/extension.dart` 替换为 `extension/get_ext.dart` + `extension/scroll_controller_ext.dart`。
   - `lib/pages/later_search/controller.dart`：`UserHttp.toViewDel` 现在返回 `LoadingState<void>`，改用 `isSuccess` / `toast()`，去掉过时 import。

### `byo` —— 包名 / 品牌定制

1 个 commit：**`change package name to com.hexverse.piliplus and app name to PiliPlusV and app icon`**

- Android `applicationId` / `namespace`：`com.example.piliplus` → `com.hexverse.piliplus`，`MainActivity.kt` 同步迁移到 `com/hexverse/piliplus/`。
- Android 显示名：`PiliPlus` → `PiliPlusV`（同时保留上游新加的 `search` / `offline_video` 字符串）。
- iOS Bundle Identifier：`com.hexverse.piliplus`，`CFBundleDisplayName`：`PiliPlusV`。
- 全套 iOS / macOS / Android 应用图标替换。
- 注：`AndroidManifest.xml` 与 `res/xml-v25/shortcuts.xml` 中的 shortcut action 字符串仍是 `com.example.piliplus.SHORTCUT`，两边一致即可，不影响功能。

## 构建产物

放在 `bin/`（未纳入 git）：

- `bin/PiliPlusV-release-260508.apk` —— Android Release APK（`flutter build apk --release`）。
- `bin/PiliPlusV-release-260508-unsigned.ipa` —— iOS 未签名 IPA，用于 AltStore / Sideloadly 等本地重签名工具。
  - 由 `flutter build ipa --release --no-codesign` 产出 `build/ios/archive/Runner.xcarchive`，再手工 `Payload/Runner.app` 打包得到。

构建说明：

- Flutter SDK：`3.41.9-stable`（与 `pubspec.yaml > environment.flutter` 一致；用 asdf 装在 `~/.asdf/installs/flutter/3.41.9-stable`）。
- 因为本机走代理偶发故障，构建时 unset 了 `ALL_PROXY/HTTP_PROXY/...`，并用 `PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` 走国内镜像。
- 依赖解析后会出现「`gt3_flutter_plugin` / `GT3Captcha-iOS` 不支持 arm64 模拟器」的警告——只影响 Apple Silicon 模拟器调试，**真机 release 包不受影响**。

## 后续 main 更新时的操作建议

> 默认前提：`upstream` 远端是 `bggRGjQaUbCoE/PiliPlus`，本地有 `main` 跟踪 `upstream/main`。

### 推荐：分支独立维护，按需重建 release

1. **更新本地 `main`**

   ```bash
   git fetch upstream
   git checkout main
   git reset --hard upstream/main      # 个人镜像，main 直接对齐上游
   ```

2. **将 `6vDiy` 与 `byo` 重新 rebase 到新 main**

   ```bash
   git checkout 6vDiy && git rebase main      # 解决冲突
   git checkout byo   && git rebase main      # 解决冲突
   ```

   常见冲突类型与思路：
   - **稍后再看页面**：上游若再次重构 Tab/列表，优先保留上游结构，把 `Dismissible` + 撤销 / `Pref.longPressToWatchLater` 这类小钩子重新接进去。
   - **专栏页**：只需要保留 `controller.articleScrollController = scrollController` 与 `listener` 中调用 `saveReadingPosition` 的两段；不要跟上游的 FAB/底栏布局抢。
   - **`extra_settings.dart`**：用与同文件其它项一致的 `SwitchModel` 包装新设置项（避免再次踩 `SettingsModel` vs `SwitchModel` 的差异）。
   - **`utils/extension.dart`**：项目里只有 `utils/extension/...` 子文件；任何指向 `utils/extension.dart` 的 import 都要替换。
   - **`UserHttp.toViewDel` / 类似接口**：现在返回 `LoadingState<void>`，要用 `isSuccess` / `toast()`，不要再用 map 风格 `res['status']` / `res['msg']`。
   - **`byo`**：基本只是 Android `applicationId` / `MainActivity.kt` 路径 / `app_name` / 图标，遇到上游 `string.xml` 新增字符串时，保留上游新增、把 `app_name` 改回 `PiliPlusV`。

3. **重建 release 分支**

   每次发布建议起一个新名字（例如 `release-YYMMDD`），简单干净：

   ```bash
   git checkout main
   git checkout -B release-YYMMDD
   git merge --no-ff 6vDiy -m "Merge branch '6vDiy' into release-YYMMDD"
   git merge --no-ff byo   -m "Merge branch 'byo'   into release-YYMMDD"
   ```

   合并通常无冲突——因为冲突已在 `6vDiy` / `byo` 自己的 rebase 阶段解决过。

4. **构建并验证**

   ```bash
   unset ALL_PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy all_proxy
   export PUB_HOSTED_URL=https://pub.flutter-io.cn
   export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

   flutter pub get
   flutter analyze --no-pub                  # 应只剩 info / warning，不允许有 error
   flutter build apk --release               # → build/app/outputs/flutter-apk/app-release.apk
   flutter build ipa --release --no-codesign # → build/ios/archive/Runner.xcarchive

   # 打包 unsigned IPA
   mkdir -p bin/_p/Payload
   cp -R build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app bin/_p/Payload/
   (cd bin/_p && zip -qr ../PiliPlusV-release-YYMMDD-unsigned.ipa Payload)
   rm -rf bin/_p
   cp build/app/outputs/flutter-apk/app-release.apk bin/PiliPlusV-release-YYMMDD.apk
   ```

5. **更新这份文档**：把 `release-260508` 替换为新版本号，列出新合入的 commit、新冲突要点。

### 不推荐的做法

- 直接在 release 分支上长期开发（这是「构建结果」分支，不接受新功能；新功能去对应的 `6vDiy` / `byo` / 新 feature 分支）。
- `git pull --rebase upstream main` 到 `6vDiy` 之后又 force-push：会把 commit hash 全打散，下次再 rebase 时旧的解决方案还得再做一次。要么本地保留稳定 hash，要么在第 2 步之前先备份分支：`git branch 6vDiy-backup-$(date +%Y%m%d)`。
- 把 `gt3_flutter_plugin` 在模拟器上「能跑」的 hack 提交进 release 分支：上游已知问题，等插件修复或自行替换更稳。
