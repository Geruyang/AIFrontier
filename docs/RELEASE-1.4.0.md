# AI Frontier 1.4.0 — 全新界面与更广的 AI 资讯

本版为 build 6，最低 iOS 18。

- 全新深海蓝、青绿与电光紫界面，学习进度卡、杂志式新闻头条、主题趋势与个人资料库保持统一视觉风格。
- 新闻来源由 4 个扩展到 9 个，新增 Microsoft AI、AWS Machine Learning、Hugging Face、MIT 与 Berkeley AI Research。
- 使用时每 5 分钟检查新闻，回到前台按需更新；后台请求最早 5 分钟执行。**实际后台执行时机由 iOS 决定，不保证固定五分钟唤醒。**
- 将同步与来源详情收纳到按需入口；正常使用不再显示缓存、翻译引擎等执行说明。
- 新增按发布者搜索资讯，以及从趋势主题打开相关文章。
- 修复刷新取消、前后台快速切换、重复刷新和深色按钮对比度等边界问题。
- 保持本地优先、中英双语、600 节课程、1,980 道题、学习记录与收藏功能。

验证范围见[验证报告](https://github.com/Geruyang/AIFrontier/blob/v1.4.0/docs/VERIFICATION-1.4.0.md)，来源及同步边界见[新闻来源说明](https://github.com/Geruyang/AIFrontier/blob/v1.4.0/docs/NEWS-SOURCES.md)。

## 下载内容

| 文件 | 用途 |
| --- | --- |
| AIFrontier-1.4.0-signed.ipa | App Store 分发签名包，供 App Store Connect 分发；不能直接安装到任意 iPhone |
| AIFrontier-1.4.0-simulator.zip | 通用 iOS Simulator Release 应用；解压后执行 `xcrun simctl install booted AIFrontier.app` |
| SHA256SUMS-1.4.0.txt | 两个二进制文件的 SHA-256 校验值 |
| Source code (zip / tar.gz) | 此版本对应的源码及测试 |

真机本地运行请从源码构建，并选择自己的签名团队。模拟器不支持 Apple 翻译引擎；缓存、回退与界面验证使用隔离测试数据。

## 已知验证限制

本机 Intel / iOS 26.5 模拟器的系统玻璃导航存在渲染异常，在旧版及独立原生 TabView 示例中均可复现；导航功能测试通过，真机导航外观仍待复核。详情见验证报告。
