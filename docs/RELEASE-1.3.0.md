# AI Frontier 1.3.0 — 学习连续性与可靠性改进

本版为 build 5，最低 iOS 18。

- 新增“继续学习”和“待复习课程”，保留最好成绩并显示最近测验结果。
- 测验至少三分之二正确才计入完成；旧数据自动兼容迁移。
- 资讯收藏独立保存标题、摘要与原文链接，不再随近一个月的新闻缓存消失。
- 修复清除学习记录误删资讯收藏、全部课程筛选被重置、空搜索缺少提示的问题。
- 开始答题后退出需确认；设置入口固定在资料库工具栏。
- 修复新闻嵌套字段解析、订阅到期与商品加载失败处理、大量收藏时的翻译缓存淘汰问题。
- 保持本地优先、中英双语、600 节课程、1,980 道题，以及无自建账号/云模型服务的设计。

验证过程与范围见 [验证报告](https://github.com/Geruyang/AIFrontier/blob/v1.3.0/docs/VERIFICATION-1.3.0.md)。

## 下载内容

| 文件 | 用途 |
| --- | --- |
| AIFrontier-1.3.0-signed.ipa | App Store 分发签名包，供 App Store Connect 分发；不能直接安装到任意 iPhone |
| AIFrontier-1.3.0-simulator.zip | 通用 iOS Simulator Release 应用；解压后执行 `xcrun simctl install booted AIFrontier.app` |
| SHA256SUMS-1.3.0.txt | 二进制文件 SHA-256 校验值 |
| Source code (zip / tar.gz) | 当前 release tag 对应的完整源码和测试 |

开发者自用包与测试设备信息不在公开发行附件中。真机本地运行请从源码构建，在 Xcode 中选择自己的签名团队。
