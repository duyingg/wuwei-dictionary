# 五味字典

五味字典是一款以手机端为主要使用场景的离线中文单字典应用，提供单字查询、拼音与部首索引、笔顺展示、多音字学习、诗词与传统文化内容，并支持导入和切换皮肤。

## 主要功能

- 离线单字查询与简繁对应
- 拼音、部首、笔画等索引
- 汉字笔顺动画
- 多音字闯关与学习
- 诗词、百家姓等传统文化内容
- 可导入的 `.hanzi-skin` 皮肤包

## 开发环境

- Flutter 3.47 或兼容版本
- JDK 21（Android 构筑脚本会自动查找兼容的 JDK 17–24）
- Android SDK 与 Build-Tools 35
- Git LFS

克隆后先取得 LFS 数据并安装依赖：

```powershell
git lfs install
git lfs pull
flutter pub get --enforce-lockfile
```

运行检查：

```powershell
.\build-apk.ps1 -ValidateOnly
```

构筑本地测试 APK：

```powershell
.\build-apk.ps1
```

默认 APK 使用调试签名，只适合本地安装。公开发布前请配置私有发布密钥并执行：

```powershell
.\build-apk.ps1 -RequireReleaseSigning
```

## 数据与许可证

应用使用的开源字典、诗词、字形和简繁转换数据保留在仓库中。详细来源与许可证位置见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。大于 GitHub 普通文件限制的数据通过 Git LFS 管理。

## 许可证

五味字典自身代码采用 [MIT License](LICENSE)，版权所有 © 2026 duyingg。第三方数据和资源继续遵循各自的原始许可证。
