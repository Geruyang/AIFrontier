# 新闻来源与刷新机制

AI Frontier 1.4 使用以下 9 个公开订阅源。链接属于发布机构自己的域名；每条新闻保留机构署名、发布日期与原文链接。来源类型表示发布主体，不代表 App 已独立核实其所有结论。

| 来源 | 订阅地址 | 类型 |
| --- | --- | --- |
| OpenAI News | https://openai.com/news/rss.xml | 官方公告 |
| Google AI | https://blog.google/technology/ai/rss/ | 官方公告 |
| Google DeepMind | https://deepmind.google/blog/rss.xml | 官方研究公告 |
| NVIDIA AI | https://blogs.nvidia.com/blog/category/generative-ai/feed/ | 官方公告 |
| Microsoft AI | https://www.microsoft.com/en-us/ai/blog/feed/ | 官方公告 |
| AWS Machine Learning | https://aws.amazon.com/blogs/machine-learning/feed/ | 官方公告 |
| Hugging Face | https://huggingface.co/blog/feed.xml | 官方站点的社区与研究文章 |
| MIT News · AI | https://news.mit.edu/rss/topic/artificial-intelligence2 | 大学新闻 |
| Berkeley AI Research | https://bair.berkeley.edu/blog/feed.xml | 大学研究公告 |

## 筛选与边界

只展示过去一个日历月内、已发布且含有效原文链接的 AI 相关重要消息。教程、课程、网络研讨会等内容不进入新闻流；具有发布、研究、安全、政策等信号的内容优先。移除常见跟踪参数后去重，最多保留 200 条。此筛选是明确的本地启发式规则，不是独立的事实核查或完整行业覆盖。官方公告、大学新闻与研究介绍都不能直接视为经过同行评审的研究结论。

部分机构发布频率较低，合法订阅源也可能暂时没有符合条件的新内容；不为填满列表而伪造新闻、修改发布日期或放宽时效。当前窗口外的已收藏文章仍可在收藏中阅读。

## 同步

- 使用期间每 300 秒检查一次；回到前台时，若上次尝试已满 300 秒或从未刷新，则立即获取。
- 下拉刷新始终可以立即发起请求；已有请求执行时合并，避免并发重复请求。
- 离开前台取消该场景的定时任务和正在进行的前台请求。取消不会显示为网络故障，不覆盖成功缓存或刷新时间。
- 网络失败保留仍在时效内的缓存。自动重试等待下一轮，手动刷新可立即重试。
- 进入后台与后台任务结束时登记下一次系统后台刷新，最早请求时间为 5 分钟后；已有更早的请求会被保留。旧版本 6 小时后的请求会被新的较早请求替换。
- **iOS 决定实际后台运行时间，不保证每 5 分钟唤醒 App。** 低电量、用户使用习惯、后台刷新设置及系统调度等可能影响执行。该实现没有宣称或使用持续后台运行。

Apple 的 [`earliestBeginDate` 文档](https://developer.apple.com/documentation/backgroundtasks/bgtaskrequest/earliestbegindate)明确说明这是最早开始时间，不保证指定时刻启动。

## 实际核验

2026-09-27 使用 `scripts/verify-live-feeds.command`，通过 App 本身的 URLSession 请求器、XML 解析器与筛选器校验上述全部来源。9 个源均成功返回可解析文章；本次合并获得 47 条符合近月规则的消息。在线内容会继续变化，该数量不是 App 的固定承诺。

新增回归测试覆盖：5 分钟边界、时钟回拨、已有后台请求不被推迟、及时缓存跳过自动请求、手动强制刷新、失败重试节流、刷新重叠与取消、主要模型名称的识别。实际后台唤醒间隔不能由模拟器测试证明。
