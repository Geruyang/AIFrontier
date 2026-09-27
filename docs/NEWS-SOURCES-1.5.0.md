# 1.5.0 新闻来源核验清单

核验时间：2026-09-27T09:20:14Z（UTC）。

## 结果与计数口径

- 最终保留 **64 个独立 RSS/Atom 订阅端点**，对应 **52 个发布机构分组**。原有 9 个来源全部保留。64 个输入 URL 和 64 个最终重定向 URL 分别互不重复。
- 分组按已识别的共同发布机构/母机构合并：Google AI、DeepMind、Google Research、Google Cloud 合并为 Alphabet；Microsoft AI、Microsoft Research、GitHub 合并为 Microsoft；NVIDIA 两频道、AWS 两频道、Mozilla 两频道各合并；MIT News 与 MIT Technology Review 合并；Ars Technica 与 WIRED 合并为 Condé Nast；TechRadar 与 Tom’s Hardware 合并为 Future；TechCrunch 与 InfoWorld 合并为 Regent。其余每个登记发布组织分别计数。此数是透明的发布机构分组，不是所有品牌的最终受益所有权审计。
- Regent 合并依据：[Regent 官方收购公告](https://www.regentco.com/news/regent-acquires-techcrunch-from-yahoo)。
- 类别：官方公告 24、官方研究 7、官方开源/社区研究 2、大学新闻 1、大学研究 2、专业媒体 26、研究机构 2。官方合计 33，大学 3，专业媒体 26，公共研究机构 2。
- 最终保留项全部经真实 GET 和应用生产 `URLSessionFeedFetcher` / `FeedParser` 验证；共解析 **3,687** 篇具备非空标题、有效原文 HTTP(S) URL 与真实可解析日期的文章。生产 `NewsSelection` 在核验时得到 **197** 篇最近一个月内、通过 AI 重要性规则、按原文 URL 去重的新闻。
- “64 来源”不表示每次都有 64 个来源供稿。未通过日期窗口/重要性规则的文章不会为了凑数显示；同机构不同频道也不是相互独立的新闻机构。

## 方法与限制

1. 实测 109 个候选端点；候选发现检查最多 8 并发，最终生产 GET 最多 6 并发。检查 HTTP 状态、大小、RSS/Atom 根节点、条目、标题、原文链接与发布时间。HTTP 200 返回 HTML 或空 feed 不算通过。
2. 最终验证使用当前源码（1.5 User-Agent、15 秒超时、5 MB 上限、生产日期解析与 AI 筛选），未使用人为补日期、抓网页生成 RSS 或聚合站冒充原始来源。
3. CMU 提供带 EDT 的 pubDate 及有效 ISO 8601 dc:date；生产解析现逐个尝试真实日期字段并支持命名时区，不再因为优先字段失败丢弃有效发布日期。
4. 保留原有 Berkeley AI Research：最新条目为 2026-07-29，本轮最近一月入选为 0。Ollama 最新条目为 2026-08-31，本轮重要性筛选为 0。订阅本身仍有效；不伪造新鲜度。
5. 媒体来源可能覆盖其他科技主题或有付费阅读限制；应用依旧只选符合 AI 主题/重要性的 feed 条目，原文访问遵循媒体自身规则。链接核验指生产解析获得有效原文 URL，不代表逐篇完整正文下载或事实核查。
6. GET 成功和数量是此时快照，不保证所有第三方来源将来持续可用。服务需继续容忍单源失效。

## 保留的来源

“有效/入选”依次为生产 parser 解析条目数、生产当月 AI 重要性规则筛选数；最终合并再次按原文 URL 去重。以下链接均来自实测 feed 元数据。

| 来源 / 发布机构分组 | 类别 | Feed | 有效/入选 | 最新发布日期 UTC | 原文样本 |
|---|---|---|---:|---|---|
| [OpenAI News](https://openai.com/news/) / OpenAI News | 官方公告 | [RSS/Atom](https://openai.com/news/rss.xml) | 1230/22 | 2026-09-25T19:00:00Z | [Proaction boosts sales 60% and saves 75+ hours with Codex](https://openai.com/index/proaction) |
| [Google AI](https://blog.google/technology/ai/) / Alphabet / Google | 官方公告 | [RSS/Atom](https://blog.google/technology/ai/rss/) | 20/3 | 2026-09-23T18:00:00Z | [Google Beam expands with new regions, partners, and customers](https://blog.google/innovation-and-ai/technology/research/google-beam-expansion/) |
| [Google DeepMind](https://deepmind.google/blog/) / Alphabet / Google | 官方研究 | [RSS/Atom](https://deepmind.google/blog/rss.xml) | 100/6 | 2026-09-24T16:20:39Z | [Introducing Gemini 3.8 Live with Live Avatar](https://deepmind.google/blog/introducing-gemini-38-live-with-live-avatar/) |
| [NVIDIA AI](https://blogs.nvidia.com/) / NVIDIA | 官方公告 | [RSS/Atom](https://blogs.nvidia.com/blog/category/generative-ai/feed/) | 18/5 | 2026-09-23T02:30:22Z | [At AI Day Singapore, NVIDIA and Partners Showcase AI Advancements Across Southeast Asia](https://blogs.nvidia.com/blog/ai-day-singapore/) |
| [Microsoft AI](https://www.microsoft.com/en-us/ai/blog/) / Microsoft | 官方公告 | [RSS/Atom](https://www.microsoft.com/en-us/ai/blog/feed/) | 10/0 | 2026-09-16T22:36:04Z | [Microsoft’s commitment for AI in education](https://blogs.microsoft.com/blog/2026/09/16/microsofts-commitment-for-ai-in-education/) |
| [AWS Machine Learning](https://aws.amazon.com/blogs/machine-learning/) / Amazon / AWS | 官方公告 | [RSS/Atom](https://aws.amazon.com/blogs/machine-learning/feed/) | 20/4 | 2026-09-25T16:29:50Z | [Scaling MoE reinforcement learning on Amazon EKS with EFA and DeepEP with 40% more throughput](https://aws.amazon.com/blogs/machine-learning/scaling-moe-reinforcement-learning-on-amazon-eks-with-efa-and-deepep-with-40-more-throughput/) |
| [Hugging Face](https://huggingface.co/blog) / Hugging Face | 官方开源/社区研究 | [RSS/Atom](https://huggingface.co/blog/feed.xml) | 868/2 | 2026-09-24T14:08:57Z | [Accelerating vision-language models with LFM2.5-VL-DSpark](https://huggingface.co/blog/LiquidAI/lfm2-5-vl-dspark) |
| [MIT News · AI](https://news.mit.edu/topic/artificial-intelligence2) / MIT | 大学新闻 | [RSS/Atom](https://news.mit.edu/rss/topic/artificial-intelligence2) | 50/5 | 2026-09-25T20:15:00Z | [MIT students gain a humanist lens on technical innovation in Tulsa, Oklahoma](https://news.mit.edu/2026/mit-students-gain-humanist-lens-technical-innovation-tulsa-oklahoma-0925) |
| [Berkeley AI Research](https://bair.berkeley.edu/blog/) / Berkeley AI Research | 大学研究 | [RSS/Atom](https://bair.berkeley.edu/blog/feed.xml) | 10/0 | 2026-07-29T09:00:00Z | [From CUDA to MLX: How K-Search Brings Decades of Kernel Expertise to Apple Silicon](http://bair.berkeley.edu/blog/2026/07/29/cuda-to-mlx-k-search/) |
| [Apple Machine Learning Research](https://machinelearning.apple.com/) / Apple Machine Learning Research | 官方研究 | [RSS/Atom](https://machinelearning.apple.com/rss.xml) | 10/3 | 2026-09-24T00:00:00Z | [Compressing Streaming Neural Audio Encoders via Latent-Space Distillation](https://machinelearning.apple.com/research/latent-space-distillation) |
| [Microsoft Research](https://www.microsoft.com/en-us/research/) / Microsoft | 官方研究 | [RSS/Atom](https://www.microsoft.com/en-us/research/feed/) | 10/0 | 2026-09-23T16:01:36Z | [Offloaded inference for real-world physical AI robotics](https://www.microsoft.com/en-us/research/blog/offloaded-inference-for-real-world-physical-ai-robotics/) |
| [NVIDIA Technical Blog](https://developer.nvidia.com/blog/) / NVIDIA | 官方公告 | [RSS/Atom](https://developer.nvidia.com/blog/feed/) | 100/6 | 2026-09-24T15:00:00Z | [Efficient MoE Training for Biological Foundation Models](https://developer.nvidia.com/blog/efficient-moe-training-for-biological-foundation-models/) |
| [AWS News Blog](https://aws.amazon.com/blogs/aws/) / Amazon / AWS | 官方公告 | [RSS/Atom](https://aws.amazon.com/blogs/aws/feed/) | 20/4 | 2026-09-24T20:58:46Z | [Introducing enhanced custom event buses in Amazon EventBridge for enterprise-scale event-driven applications](https://aws.amazon.com/blogs/aws/introducing-enhanced-custom-event-buses-in-amazon-eventbridge-for-enterprise-scale-event-driven-applications/) |
| [GitHub Blog](https://github.blog/) / Microsoft | 官方公告 | [RSS/Atom](https://github.blog/feed/) | 10/1 | 2026-09-25T18:00:00Z | [GitHub Copilot app for Beginners: How to build custom workflows with canvases](https://github.blog/ai-and-ml/github-copilot/github-copilot-app-for-beginners-how-to-build-custom-workflows-with-canvases/) |
| [Cloudflare Blog](https://blog.cloudflare.com/) / Cloudflare Blog | 官方公告 | [RSS/Atom](https://blog.cloudflare.com/rss/) | 20/4 | 2026-09-25T13:00:00Z | [Agents can now set up your website’s security with Turnstile Spin](https://blog.cloudflare.com/turnstile-spin/) |
| [Mozilla Blog](https://blog.mozilla.org/) / Mozilla | 官方公告 | [RSS/Atom](https://blog.mozilla.org/en/feed/) | 20/2 | 2026-09-24T17:00:00Z | [Classic, Private, or Smart? Choose the right Firefox window for every task](https://blog.mozilla.org/en/firefox/firefox-window-types/) |
| [Salesforce AI Research](https://www.salesforce.com/blog/category/ai-research/) / Salesforce AI Research | 官方研究 | [RSS/Atom](https://www.salesforce.com/blog/category/ai-research/feed/) | 10/0 | 2026-09-01T23:53:58Z | [Operational Intelligence: Turning Enterprise Data Into Enterprise Decisions with AI](https://www.salesforce.com/blog/operational-intelligence/) |
| [Arm Newsroom](https://newsroom.arm.com/) / Arm Newsroom | 官方公告 | [RSS/Atom](https://newsroom.arm.com/feed) | 6/0 | 2026-09-21T12:00:09Z | [Arm joins EuroCDP to accelerate Europe’s next generation of innovators](https://newsroom.arm.com/blog/arm-joins-eurocdp-europe-chip-innovation) |
| [Ollama Blog](https://ollama.com/blog) / Ollama Blog | 官方公告 | [RSS/Atom](https://ollama.com/blog/rss.xml) | 58/0 | 2026-08-31T00:00:00Z | [Ollama's transparent pricing](https://ollama.com/blog/transparent-pricing) |
| [JetBrains AI](https://blog.jetbrains.com/ai/) / JetBrains AI | 官方公告 | [RSS/Atom](https://blog.jetbrains.com/ai/feed/) | 12/0 | 2026-09-17T12:39:40Z | [Building a RAG Pipeline for Semantic Code Search: A Developer Diary and Field Notes](https://blog.jetbrains.com/ai/2026/09/building-a-rag-pipeline-for-semantic-code-search-a-developer-diary-and-field-notes/) |
| [Red Hat Blog](https://www.redhat.com/en/blog) / Red Hat Blog | 官方公告 | [RSS/Atom](https://www.redhat.com/en/rss/blog) | 10/3 | 2026-09-25T00:00:00Z | [Red Hat Enterprise Linux 10 STIG automation now matches DISA STIG V1R2](https://www.redhat.com/en/blog/red-hat-enterprise-linux-10-stig-automation-now-matches-disa-stig-v1r2) |
| [Docker Blog](https://www.docker.com/blog/) / Docker Blog | 官方公告 | [RSS/Atom](https://www.docker.com/blog/feed/) | 10/2 | 2026-09-24T17:15:00Z | [Manufacturing Trust for AI Agents ／ Docker’s WeAreDevelopers Keynote](https://www.docker.com/blog/manufacturing-trust-for-ai-agents-keynote/) |
| [Ubuntu Blog](https://ubuntu.com/blog) / Ubuntu Blog | 官方公告 | [RSS/Atom](https://ubuntu.com/blog/feed) | 12/2 | 2026-09-23T15:09:20Z | [Fine tune your own custom LLM with Canonical Charmed Kubeflow and Feast](https://ubuntu.com//blog/fine-tune-your-own-custom-llm-with-canonical-charmed-kubeflow-and-feast) |
| [Databricks Blog](https://www.databricks.com/blog) / Databricks Blog | 官方公告 | [RSS/Atom](https://www.databricks.com/feed) | 10/2 | 2026-09-25T16:00:00Z | [From Data to Dialogue: How S&P Global Energy Made Its Structured Data Estate Conversational with Databricks Genie Agents and MCP](https://www.databricks.com/blog/data-dialogue-how-sp-global-energy-made-its-structured-data-estate-conversational-databricks) |
| [Together AI Blog](https://www.together.ai/blog) / Together AI Blog | 官方研究 | [RSS/Atom](https://www.together.ai/blog/rss.xml) | 81/2 | 2026-09-23T00:00:00Z | [How to train your own Jev for $17](https://www.together.ai/blog/how-to-train-your-own-jev) |
| [TechCrunch · AI](https://techcrunch.com/category/artificial-intelligence/) / Regent | 专业媒体 | [RSS/Atom](https://techcrunch.com/category/artificial-intelligence/feed/) | 20/0 | 2026-09-27T01:30:00Z | [Google tests buying from Walmart-owned Flipkart through Gemini and AI Mode in India](https://techcrunch.com/2026/09/26/google-tests-buying-from-walmart-owned-flipkart-through-gemini-and-ai-mode-in-india/) |
| [The Verge · AI](https://www.theverge.com/ai-artificial-intelligence) / The Verge · AI | 专业媒体 | [RSS/Atom](https://www.theverge.com/rss/ai-artificial-intelligence/index.xml) | 10/3 | 2026-09-26T16:34:59Z | [OpenAI pauses training of its ‘most capable models’](https://www.theverge.com/ai-artificial-intelligence/1001049/openai-training-pause) |
| [Ars Technica](https://arstechnica.com/) / Condé Nast | 专业媒体 | [RSS/Atom](https://feeds.arstechnica.com/arstechnica/index) | 20/0 | 2026-09-26T10:45:09Z | [Tesla’s big electric truck faces an even bigger infrastructure challenge](https://arstechnica.com/cars/2026/09/teslas-big-electric-truck-faces-an-even-bigger-infrastructure-challenge/) |
| [WIRED · AI](https://www.wired.com/tag/artificial-intelligence/) / Condé Nast | 专业媒体 | [RSS/Atom](https://www.wired.com/feed/tag/ai/latest/rss) | 10/0 | 2026-09-26T10:30:00Z | [Meta’s Muse Is Adults-Only. Why Does It Look Like a Kids’ Toy?](https://www.wired.com/story/meta-muse-is-adults-only-why-does-it-look-like-a-cute-kids-toy/) |
| [MIT Technology Review](https://www.technologyreview.com/) / MIT | 专业媒体 | [RSS/Atom](https://www.technologyreview.com/feed/) | 10/1 | 2026-09-25T12:10:00Z | [The Download: the Pentagon’s AI-powered lie detector and young organ limits](https://www.technologyreview.com/2026/09/25/1145157/the-download-pentagon-ai-lie-detector-young-organ-limits/) |
| [ZDNET](https://www.zdnet.com/) / ZDNET | 专业媒体 | [RSS/Atom](https://www.zdnet.com/news/rss.xml) | 25/2 | 2026-09-25T16:51:43Z | [This one WatchOS 27 feature just solved my biggest issue with Apple Watch](https://www.zdnet.com/uncategorized/watchos-27-update-fix-apple-watch/) |
| [Engadget](https://www.engadget.com/) / Engadget | 专业媒体 | [RSS/Atom](https://www.engadget.com/rss.xml) | 20/0 | 2026-09-27T00:30:00Z | [Why we won't know how visible the iPhone Duo's crease is for a long time](https://www.engadget.com/2266671/iphone-duo-wont-know-how-visible-crease-for-long-time/) |
| [The Next Web](https://thenextweb.com/) / The Next Web | 专业媒体 | [RSS/Atom](https://thenextweb.com/feed) | 10/1 | 2026-09-26T17:08:09Z | [Australian inquiry asks Altman and Amodei to testify](https://thenextweb.com/news/australia-senate-inquiry-altman-amodei-openai-medicare) |
| [The Register · AI](https://www.theregister.com/software/ai_ml/) / The Register · AI | 专业媒体 | [RSS/Atom](https://www.theregister.com/software/ai_ml/headlines.atom) | 50/1 | 2026-09-18T14:25:00Z | [KDE turns 30 and someone's brought an AI-native desktop proposal](https://www.theregister.com/software/2026/09/18/kde-turns-30-and-someones-brought-an-ai-native-desktop-proposal/5297282) |
| [IEEE Spectrum · AI](https://spectrum.ieee.org/artificial-intelligence) / IEEE Spectrum · AI | 专业媒体 | [RSS/Atom](https://spectrum.ieee.org/feeds/topic/artificial-intelligence.rss) | 30/6 | 2026-09-22T15:00:05Z | [Why Read a Research Paper When You Can Turn It Into an AI Agent?](https://spectrum.ieee.org/paper2agent-ai-agents-research-papers) |
| [TechRadar](https://www.techradar.com/) / Future | 专业媒体 | [RSS/Atom](https://www.techradar.com/rss) | 50/1 | 2026-09-27T08:00:00Z | [How to watch Tall Tales & Murder for *FREE* – stream the Dublin Trilogy adaptation from anywhere](https://www.techradar.com/how-to-watch/tv-shows/tall-tales-and-murder-free) |
| [Tom's Hardware](https://www.tomshardware.com/) / Future | 专业媒体 | [RSS/Atom](https://www.tomshardware.com/feeds/all) | 50/4 | 2026-09-26T15:10:00Z | [27-year-old GTA 2 gets full path tracing and 60 FPS frame generation via RTX Remix](https://www.tomshardware.com/video-games/pc-gaming/27-year-old-gta-2-gets-full-path-tracing-and-60-fps-frame-generation-via-rtx-remix-custom-direct3d-9-wrapper-modernizes-classic-with-custom-direct3d-9-bridge-unlocks-dynamic-lighting) |
| [SiliconANGLE](https://siliconangle.com/) / SiliconANGLE | 专业媒体 | [RSS/Atom](https://siliconangle.com/feed/) | 30/15 | 2026-09-26T15:08:15Z | [CoreWeave’s next test: From GPU scarcity to a durable AI cloud](https://siliconangle.com/2026/09/26/coreweaves-next-test-from-gpu-scarcity-to-a-durable-ai-cloud/) |
| [GeekWire](https://www.geekwire.com/) / GeekWire | 专业媒体 | [RSS/Atom](https://www.geekwire.com/feed/) | 35/9 | 2026-09-26T15:13:46Z | [Live show: Amazon, Meta and the fight over the future of AI; Plus, is Seattle still the place to build?](https://www.geekwire.com/2026/live-show-amazon-meta-and-the-fight-over-the-future-of-ai-plus-is-seattle-still-the-place-to-build/) |
| [404 Media](https://www.404media.co/) / 404 Media | 专业媒体 | [RSS/Atom](https://www.404media.co/rss/) | 15/1 | 2026-09-26T21:59:39Z | [Alien Life Can Survive on This Tiny Moon—We Just Need to Go Find It](https://www.404media.co/alien-life-can-survive-on-this-tiny-moon-we-just-need-to-go-find-it/) |
| [Platformer](https://www.platformer.news/) / Platformer | 专业媒体 | [RSS/Atom](https://www.platformer.news/rss/) | 15/4 | 2026-09-25T02:04:25Z | [Can Muse make us forget the metaverse?](https://www.platformer.news/meta-connect-2026-muse-vr-glasses/) |
| [Rest of World](https://restofworld.org/) / Rest of World | 专业媒体 | [RSS/Atom](https://restofworld.org/feed/) | 12/0 | 2026-09-24T10:00:00Z | [China is excelling in health tech. That’s good news for the world](https://restofworld.org/2026/china-ai-healthcare-biotech-drugs/?utm_source=rss&utm_medium=rss&utm_campaign=feeds) |
| [Science News](https://www.sciencenews.org/) / Science News | 专业媒体 | [RSS/Atom](https://www.sciencenews.org/feed) | 20/0 | 2026-09-25T15:00:00Z | [These are the first feathers ever found in fossilized dinosaur poop](https://www.sciencenews.org/article/dino-poop-fossil-feathers-extinction) |
| [New Scientist · Technology](https://www.newscientist.com/subject/technology/) / DMGT | 专业媒体 | [RSS/Atom](https://www.newscientist.com/subject/technology/feed/) | 10/0 | 2026-09-24T08:26:15Z | [OpenAI agent hacked an Australian government healthcare website](https://www.newscientist.com/article/2590599-openai-agent-hacked-an-australian-government-healthcare-website/?utm_campaign=RSS%7CNSNS&utm_content=technology&utm_medium=RSS&utm_source=NSNS) |
| [InfoQ · AI](https://www.infoq.com/ai-ml-data-eng/) / InfoQ · AI | 专业媒体 | [RSS/Atom](https://feed.infoq.com/ai-ml-data-eng/) | 15/3 | 2026-09-27T06:46:00Z | [GKE Pod Snapshots Cut Model Load Times, and Move the Work to Snapshot Lifecycle Management](https://www.infoq.com/news/2026/09/gke-pod-snapshots-benchmarks/?utm_campaign=infoq_content&utm_source=infoq&utm_medium=feed&utm_term=AI%2C+ML+%26+Data+Engineering) |
| [InfoWorld](https://www.infoworld.com/) / Regent | 专业媒体 | [RSS/Atom](https://www.infoworld.com/feed/) | 20/7 | 2026-09-25T17:30:01Z | [OpenAI wants you to use AI — but not to train its AI](https://www.infoworld.com/article/4226849/openai-wants-you-to-use-ai-but-not-to-train-its-ai-2.html) |
| [The New Stack](https://thenewstack.io/) / The New Stack | 专业媒体 | [RSS/Atom](https://thenewstack.io/feed/) | 26/8 | 2026-09-26T15:00:00Z | [Avoiding vendor lock-in through an open-source approach: a developer’s perspective](https://thenewstack.io/avoiding-vendor-lock-in/) |
| [HPCwire](https://www.hpcwire.com/) / HPCwire | 专业媒体 | [RSS/Atom](https://www.hpcwire.com/feed/) | 10/5 | 2026-09-25T22:18:14Z | [ALCF Summer Students Explore HPC, AI, and Scientific Computing](https://www.hpcwire.com/off-the-wire/alcf-summer-students-explore-hpc-ai-and-scientific-computing/) |
| [Google Research](https://research.google/blog/) / Alphabet / Google | 官方研究 | [RSS/Atom](https://research.google/blog/rss/) | 100/0 | 2026-09-24T19:40:00Z | [Automating coherent long-form video generation](https://research.google/blog/coherent-long-form-video-generation/) |
| [Google Cloud Blog](https://cloud.google.com/blog/) / Alphabet / Google | 官方公告 | [RSS/Atom](https://cloudblog.withgoogle.com/rss/) | 20/5 | 2026-09-25T16:00:00Z | [What’s new with Google Cloud](https://cloud.google.com/blog/topics/inside-google-cloud/whats-new-google-cloud/) |
| [GitLab Blog](https://about.gitlab.com/blog/) / GitLab Blog | 官方公告 | [RSS/Atom](https://about.gitlab.com/atom.xml) | 20/1 | 2026-09-23T00:00:00Z | [GitLab Critical Patch Release: 19.4.1, 19.3.3, 19.2.7](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-1-released/) |
| [Elastic Blog](https://www.elastic.co/blog/) / Elastic Blog | 官方公告 | [RSS/Atom](https://www.elastic.co/blog/feed) | 40/2 | 2026-09-25T00:00:00Z | [DevRel newsletter — September 2026](https://www.elastic.co/blog/devrel-newsletter-september-2026) |
| [Mozilla AI Blog](https://blog.mozilla.ai/) / Mozilla | 官方研究 | [RSS/Atom](https://blog.mozilla.ai/rss/) | 15/1 | 2026-09-17T11:32:08Z | [Benchmarking Local LLM Servers: llama.cpp, llamafile, LM Studio, and Ollama](https://blog.mozilla.ai/benchmarking-local-llm-servers-llama-cpp-llamafile-lm-studio-and-ollama/) |
| [PyTorch Blog](https://pytorch.org/blog/) / PyTorch Blog | 官方开源/社区研究 | [RSS/Atom](https://pytorch.org/feed/) | 10/3 | 2026-09-24T21:06:09Z | [Accelerate Your AI Journey with new Introduction Track at PyTorch Conference NA 2026 and PyTorch Associate Training](https://pytorch.org/blog/accelerate-your-ai-journey-with-new-introduction-track-at-pytorch-conference-na-2026-and-pytorch-associate-training/) |
| [Carnegie Mellon SCS](https://www.cs.cmu.edu/news) / Carnegie Mellon University | 大学研究 | [RSS/Atom](https://www.cs.cmu.edu/news/feed) | 20/9 | 2026-09-25T16:00:00Z | [CMU Expands Privacy Engineering Program to Include AI Governance](https://www.cylab.cmu.edu/news/2026/09/01-privacy-engineering-and-ai-governance.html) |
| [BBC Technology](https://www.bbc.com/news/technology) / BBC Technology | 专业媒体 | [RSS/Atom](https://feeds.bbci.co.uk/news/technology/rss.xml) | 21/0 | 2026-09-26T02:50:56Z | [OpenAI bots meddled with multiple US government agency sites](https://www.bbc.co.uk/news/articles/cw62jje658dlo?at_medium=RSS&at_campaign=rss) |
| [The Guardian · AI](https://www.theguardian.com/technology/artificialintelligenceai) / The Guardian · AI | 专业媒体 | [RSS/Atom](https://www.theguardian.com/technology/artificialintelligenceai/rss) | 20/5 | 2026-09-27T09:00:01Z | [Bill Gates says unchecked AI could ‘cause a billion deaths’ in call for regulation](https://www.theguardian.com/us-news/2026/sep/27/bill-gates-artificial-intelligence-kristen-welker) |
| [The New York Times · Technology](https://www.nytimes.com/section/technology) / The New York Times · Technology | 专业媒体 | [RSS/Atom](https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml) | 29/3 | 2026-09-27T09:01:20Z | [OpenAI’s A.I. Went Rogue and Meddled With U.S. Government Websites](https://www.nytimes.com/2026/09/25/technology/openais-ai-us-government-websites.html) |
| [NIST News](https://www.nist.gov/news-events/news) / NIST News | 研究机构 | [RSS/Atom](https://www.nist.gov/news-events/news/rss.xml) | 40/0 | 2026-09-18T12:00:00Z | [NIST Awards More Than $1.7 Million to Support Cybersecurity Workforce Development Across 8 States](https://www.nist.gov/news-events/news/2026/09/nist-awards-more-17-million-support-cybersecurity-workforce-development) |
| [U.S. National Science Foundation](https://www.nsf.gov/news) / U.S. National Science Foundation | 研究机构 | [RSS/Atom](https://www.nsf.gov/rss/rss_www_news.xml) | 15/1 | 2026-09-21T20:47:33Z | [Podcast: Can prosthetic limbs feel touch? (haptic feedback)](https://www.nsf.gov/news/podcast-can-prosthetic-limbs-feel-touch-haptic-feedback) |
| [Cisco Blogs](https://blogs.cisco.com/) / Cisco Blogs | 官方公告 | [RSS/Atom](https://blogs.cisco.com/feed) | 9/2 | 2026-09-25T15:00:54Z | [New webinar series now on demand: Secure Networking Ecosystem Insights](https://blogs.cisco.com/networking/new-webinar-series-now-on-demand-secure-networking-ecosystem-insights) |
| [SAP News](https://news.sap.com/) / SAP News | 官方公告 | [RSS/Atom](https://news.sap.com/feed/) | 30/5 | 2026-09-24T13:15:00Z | [SAP Named a Leader in the 2026 IDC MarketScape for AI-Enabled Direct Spend](https://news.sap.com/2026/09/sap-a-leader-2026-idc-marketscape-ai-enabled-direct-spend/) |
| [Dell Technologies Blog](https://www.dell.com/en-us/blog/) / Dell Technologies Blog | 官方公告 | [RSS/Atom](https://www.dell.com/en-us/blog/feed/) | 10/0 | 2026-09-24T18:00:32Z | [Sovereign AI Is a Control Problem, not a Location Problem](https://www.dell.com/en-us/blog/sovereign-ai-is-a-control-problem-not-a-location-problem/) |
| [Samsung Global Newsroom](https://news.samsung.com/global/) / Samsung Global Newsroom | 官方公告 | [RSS/Atom](https://news.samsung.com/global/feed) | 50/11 | 2026-09-23T22:00:00Z | [Samsung at the Forefront of Korea’s AI RAN Projects with KT and SK Telecom](https://news.samsung.com/global/samsung-at-the-forefront-of-koreas-ai-ran-projects-with-kt-and-sk-telecom) |

## 未保留候选

下表保留候选测试结果，避免将失败或空壳订阅统计为有效来源。测试中的失败不表示网站永久失效；CMU 因生产解析修复通过而已加入上表。

| 候选 | 端点 | 本次不纳入原因 |
|---|---|---|
| IBM Research | [候选 URL](https://research.ibm.com/blog/rss.xml) | HTTP 404 |
| IBM Think | [候选 URL](https://www.ibm.com/think/rss) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| Adobe Blog | [候选 URL](https://blog.adobe.com/en/publish/feed.xml) | HTTP 404 |
| Intel Community AI | [候选 URL](https://community.intel.com/t5/Blogs/ct-p/blogs/rss) | HTTP 403 |
| Qualcomm OnQ | [候选 URL](https://www.qualcomm.com/rss/blog) | HTTP 404 |
| Cohere Blog | [候选 URL](https://cohere.com/blog/rss.xml) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| Mistral AI News | [候选 URL](https://mistral.ai/news/rss.xml) | HTTP 404 |
| Stability AI | [候选 URL](https://stability.ai/news?format=rss) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| Replicate Blog | [候选 URL](https://replicate.com/blog/rss) | 可解析，但最新文章 2026-04-15，优先排除数月未更新频道。 |
| Modal Blog | [候选 URL](https://modal.com/blog/feed.xml) | HTTP 404 |
| PyTorch Blog | [候选 URL](https://pytorch.org/feed.xml) | HTTP 404 |
| TensorFlow Blog | [候选 URL](https://blog.tensorflow.org/feeds/posts/default?alt=rss) | HTTP 000 / curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to blog.tensorflow.org:443 |
| JAX Blog | [候选 URL](https://jax-ml.github.io/jax-blog/feed.xml) | HTTP 404 |
| LangChain Blog | [候选 URL](https://blog.langchain.com/rss/) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| LlamaIndex Blog | [候选 URL](https://www.llamaindex.ai/blog/rss.xml) | HTTP 404 |
| Vercel Blog | [候选 URL](https://vercel.com/atom) | 可解析，但约 3.68 MB、1611 条历史记录，接近 5 MB 上限；优先采用较精简来源。 |
| Cursor Blog | [候选 URL](https://cursor.com/blog/rss.xml) | HTTP 404 |
| Snowflake Blog | [候选 URL](https://www.snowflake.com/en/blog/feed/) | HTTP 404 |
| Anyscale Blog | [候选 URL](https://www.anyscale.com/blog/rss.xml) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| Weights & Biases | [候选 URL](https://wandb.ai/fully-connected/rss.xml) | 初次 50 条；生产复核及 curl 复核均变为 739 字节空 feed（0 条），排除不稳定空壳。 |
| Stanford HAI | [候选 URL](https://hai.stanford.edu/news/rss.xml) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| Stanford AI Lab | [候选 URL](https://ai.stanford.edu/blog/feed.xml) | XML 有 15 项但使用相对原文链接，生产解析为 0；首条为旧 LinkBERT 内容，未纳入。 |
| Cornell Chronicle | [候选 URL](https://news.cornell.edu/rss) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| Oxford News | [候选 URL](https://www.ox.ac.uk/news-and-events/news-listing/feed) | HTTP 403 |
| Cambridge Research | [候选 URL](https://www.cam.ac.uk/research/news/rss.xml) | HTTP 404 |
| UCL News | [候选 URL](https://www.ucl.ac.uk/news/rss.xml) | HTTP 403 |
| VentureBeat · AI | [候选 URL](https://venturebeat.com/category/ai/feed/) | HTTP 429 |
| Fast Company | [候选 URL](https://www.fastcompany.com/latest/rss) | 初轮生产解析为 0（命名时区/日期兼容）；未在本轮最终清单中重新验证，未计入。 |
| Fortune · AI | [候选 URL](https://fortune.com/section/artificial-intelligence/feed/) | HTTP 404 |
| Axios · Technology | [候选 URL](https://api.axios.com/feed/technology) | HTTP 404 |
| Tech Xplore · AI | [候选 URL](https://techxplore.com/rss-feed/machine-learning-ai-news/) | 初轮生产解析为 0（命名时区/日期兼容）；未在本轮最终清单中重新验证，未计入。 |
| ScienceDaily · AI | [候选 URL](https://www.sciencedaily.com/rss/computers_math/artificial_intelligence.xml) | 初轮生产解析为 0（命名时区/日期兼容）；未在本轮最终清单中重新验证，未计入。 |
| Nature · Machine Learning | [候选 URL](https://www.nature.com/subjects/machine-learning.rss) | 初次成功；最终生产 GET/解析一次 invalidFeed，后续 curl 恢复。保守排除间歇故障端点。 |
| BigDATAwire | [候选 URL](https://www.datanami.com/feed/) | HTTP 403 |
| Simon Willison | [候选 URL](https://simonwillison.net/atom/everything/) | 可解析；个人研究/评论订阅，本次优先采用机构官方与专业新闻编辑部，未计入。 |
| Hugging Face Daily Papers | [候选 URL](https://huggingface.co/papers/rss) | HTTP 401 |
| Sebastian Raschka | [候选 URL](https://magazine.sebastianraschka.com/feed) | 可解析；个人研究/评论订阅，本次优先采用机构官方与专业新闻编辑部，未计入。 |
| Import AI | [候选 URL](https://importai.substack.com/feed) | 可解析；个人研究/评论订阅，本次优先采用机构官方与专业新闻编辑部，未计入。 |
| Interconnects | [候选 URL](https://www.interconnects.ai/feed) | 可解析；个人研究/评论订阅，本次优先采用机构官方与专业新闻编辑部，未计入。 |
| ChinAI | [候选 URL](https://chinai.substack.com/feed) | 可解析；个人研究/评论订阅，本次优先采用机构官方与专业新闻编辑部，未计入。 |
| MongoDB Blog | [候选 URL](https://www.mongodb.com/blog/rss) | HTTP 404 |
| Atlassian Blog | [候选 URL](https://www.atlassian.com/blog/feed) | HTTP 200，但返回 HTML、非支持 feed 或没有可解析有效条目。 |
| UK Department for Science, Innovation and Technology | [候选 URL](https://www.gov.uk/government/organisations/department-for-science-innovation-technology.atom) | HTTP 404 |
| Intel Newsroom | [候选 URL](https://newsroom.intel.com/feed) | HTTP 403 |
| Princeton Engineering | [候选 URL](https://engineering.princeton.edu/news/rss.xml) | HTTP 404 |

## 复验

运行项目已有 `scripts/verify-live-feeds.command` 可依次请求当前全部来源并使用生产解析和筛选输出结果；任一来源无有效文章或全局无入选文章会返回失败。该脚本是线上健康检查，不把外部网络状态与离线单元测试混为一谈。

本次临时并发验证器、109 候选 HTTP 结果及生产结果位于 `.build/feed-audit/`（不作为应用资源或提交产物）；本清单保留可审核的最终 URL、分组、时间、数量和真实原文样本。
