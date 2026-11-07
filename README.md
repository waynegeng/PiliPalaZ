<div align="center">
  <img width="144" height="144" src="assets/images/logo/logo_android.png" alt="PiliPalaZ logo">
  <h1>PiliPalaZ</h1>
  <p>基于 Flutter 的 B 站第三方客户端</p>
</div>

由 [waynegeng](https://github.com/waynegeng) 基于 [shenshiaba/PiliPalaX-Community-Fix](https://github.com/shenshiaba/PiliPalaX-Community-Fix) 修改，保留完整 Git 历史与 GPL-3.0 许可证。

## 1.2.3 的改动

- 修复纯净首页搜索框点过后，从播放页返回自动弹出输入法：离开页面或切换主导航时清除焦点，返回后保留关键词，点击搜索框仍可正常输入。
- 版本 `1.2.3+114518`，沿用应用标识和签名，可覆盖升级。

## 1.2.2 的改动

- “我的”收藏视频直接复用原收藏夹的横向卡片、列数和间距，移除收藏夹管理入口。
- “我的”顶部移除标题，展示原关于页的大图标；版本、更新、仓库及其它关于信息直接放入一般设置，旧关于路由兼容跳转。
- 纯净首页搜索框上移，键盘弹出时保持原位置；右上角保留消息与用户头像，使用原入口行为。
- 版本 `1.2.2+114517`，沿用应用标识和签名，可覆盖升级 1.2.1。

## 1.2.1 的改动

- 设置恢复原版图标、行距和字号；五个一级分类内直接展示设置项，不再经过主题、其他、音视频等分类菜单。
- 动态标签允许全部隐藏：只显示默认标签内容，并完全隐藏顶栏；默认为 Up 时保留 UP 选择栏。
- 媒体库更名“我的”，四个入口改为 2×2 按钮。下方直接展示横向收藏视频列表，使用吸顶标签切换收藏夹，支持完整收藏夹列表、分页、刷新和独立滚动位置。
- 版本 `1.2.1+114516`，应用标识与签名保持不变，可直接覆盖升级 PiliPalaZ 1.2.0。

## 1.2.0 的改动

- 更名为 PiliPalaZ；Dart 包名 `pilipalaz`，Android/iOS 应用标识 `com.waynegeng.pilipalaz`，版本 `1.2.0+114515`。可与 PiliPalaX 共存，登录与设置独立保存。
- 动态页“投稿”复用首页的视频卡片和列宽设置，保留封面、标题、作者、时长及接口提供的统计信息，点击直接播放。其它类型仍使用动态卡片。
- “动态标签页”支持全部、投稿、番剧、专栏、Up 的显示/隐藏、拖动排序、默认标签和恢复默认，保存立即生效（1.2.1 起允许全部隐藏）。隐藏 Up 同时隐藏 UP 主选择栏并清除筛选。
- 动态顶栏默认上滑收起、下滑恢复；切换标签、回到顶部会恢复显示，可在动态设置关闭。
- 设置实际重组为一般设置、播放设置、首页设置、动态设置、账号设置。旧设置值继续使用，旧默认动态标签迁移为稳定标识。
- 关于、下载和更新检查指向本仓库；没有 Release 时显示“暂无发布版本”。移除 QQ 群、TG 群及问题反馈入口，保留错误日志。

保留此前修复：

- 全屏双指张开切换“裁剪”，捏合切换“自动”；锁定时不触发。
- 退出全屏或播放页面后恢复应用方向设置，取消过期旋转任务。
- **首页设置 → 纯净首页**：首页显示偏上居中的搜索框与消息、头像入口，原地输入并回车直达搜索结果，不打开搜索记录页。
- 上游直播首页及动态接口兼容修复。

## 下载与安装

[本仓库 Releases](https://github.com/waynegeng/PiliPalaZ/releases) · [签名 APK 构建记录](https://github.com/waynegeng/PiliPalaZ/actions/workflows/build-apk.yml)

若尚未建立 Release，可从成功构建的 `PiliPalaZ-release` Artifact 下载通用架构 `app-release.apk`（GitHub Artifact 下载需要登录）。安装 PiliPalaZ 无需卸载 PiliPalaX；首次安装需重新登录并配置设置。

## 设置位置

- **一般设置**：颜色、深浅、字号、导航外观、横屏适配、图片质量、提示、帧率、启动页、震动、代理、缓存、更新、日志、开发人员选项、应用信息与仓库。
- **播放设置**：手势、全屏、弹幕、字幕、后台播放、简介、评论、AI 总结、快速收藏、画质、音质、解码、缓冲、输出。
- **首页设置**：纯净首页、标签、背景、列宽、顶底栏、搜索、来源、刷新保留、过滤。
- **动态设置**：标签/默认标签、顶栏收起、UP 栏位置、全部关注 UP、未读标记、其它动态瀑布流。
- **账号设置**：隐私及退出登录。

## 构建

使用 Flutter **3.24.4** / Dart **3.5.4**、Java **21**、Android SDK **34**、Build Tools **34.0.0**、NDK **27.0.12077973**。

```bash
flutter pub get --enforce-lockfile
flutter test --no-pub
flutter build apk --release --no-pub
```

锁文件使用 `pub.flutter-io.cn`。在访问 pub.dev 的环境中，可将锁文件域名替换为 `https://pub.dev` 后保留 `--enforce-lockfile` 安装；GitHub 构建工作流已自动处理镜像及 Maven 仓库。

Release 签名通过环境变量 `KEYSTORE`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD` 提供。不要提交密钥与密码。手动运行 **Build installable APK** 会使用仓库 `PILIPALA_ANDROID_*` 签名 secrets，执行回归测试、构建、签名检查及 SHA-256 校验。沿用本 fork 原签名，应用 ID 独立。旧的多平台 Release 工作流改为手动触发。

验证范围与设备验收步骤见 [test/README.md](test/README.md)。本次未连接真机；自动测试和 APK 检查不代表已经验证原生播放、旋转及共存安装。

## 来源与许可证

感谢所有上游作者与贡献者：

- [guozhigq/pilipala](https://github.com/guozhigq/pilipala)
- [orz12/PiliPalaX](https://github.com/orz12/PiliPalaX)
- [shenshiaba/PiliPalaX-Community-Fix](https://github.com/shenshiaba/PiliPalaX-Community-Fix)

本项目采用 [GNU General Public License v3.0](LICENSE)。分发修改版本或 APK 时，请同时提供对应源代码、保留许可证与作者署名，并标明修改内容。本项目与哔哩哔哩官方无隶属关系。
