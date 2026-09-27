# AI Frontier 1.5.0 — 64 个新闻来源与品牌启动画面

本版为 build 7，最低 iOS 18。

- 新闻来源由 9 个扩展到 **64 个 RSS/Atom 端点，覆盖 52 个发布机构分组**。包括官方研究、大学、公共研究机构与可靠科技媒体；每条保留原文链接。
- 全部 64 源通过真实请求与生产解析检查；核验时解析 3,687 篇，筛选出 197 篇近月去重 AI 新闻。数量是核验时快照。
- 增加来源名称、域名与类型搜索；最多 6 个并发请求，减少集中占用网络。
- 新增深海蓝、青绿与紫色轨道的原生启动画面，与应用现有品牌一致，不增加人为等待。
- 修复 RSS 命名时区和备用日期字段解析，避免遗漏有效文章。
- 保留使用时每 5 分钟检查及系统后台刷新请求。实际后台时机由 iOS 决定。

通过 65 项逻辑测试和 3 项相关界面回归；最终 64 源目录再次通过 65 项逻辑测试与来源搜索界面测试。真机归档、签名导出、模拟器构建与静态分析均通过。

[来源核验清单](https://github.com/Geruyang/AIFrontier/blob/v1.5.0/docs/NEWS-SOURCES-1.5.0.md) · [验证报告](https://github.com/Geruyang/AIFrontier/blob/v1.5.0/docs/VERIFICATION-1.5.0.md) · [启动画面预览](https://github.com/Geruyang/AIFrontier/blob/v1.5.0/docs/images/launch-screen-1.5.0.png)

## 下载

| 文件 | 用途 |
| --- | --- |
| AIFrontier-1.5.0-signed.ipa | App Store 分发签名包；不能直接安装到任意 iPhone |
| AIFrontier-1.5.0-simulator.zip | 通用 iOS Simulator Release 应用；解压后执行 `xcrun simctl install booted AIFrontier.app` |
| SHA256SUMS-1.5.0.txt | 两个二进制包的 SHA-256 校验值 |
| Source code (zip / tar.gz) | 此版本的源码、测试和核验文档 |

真机本地运行可从源码构建并选择自己的签名团队。模拟器不支持 Apple 翻译引擎；本机 Intel / iOS 26.5 的原生玻璃导航外观异常仍待其他宿主或真机复核，详见验证报告。
