# 课程内容与来源说明（1.2.1）

本次课程分为入门、基础、进阶，按学习深度选择，三个级别各200节，共600个学习单元、1800段讲解、720个明确的案例块、1980道习题。课程单元和讲解段数量均为1.1.0的10倍。保留原有60节综合课程，新增540节独立主题短课，每节用“概念、实际应用、使用边界”说明一个主题，配完整例子与三题测验；原有课程仍为六题。新增中英讲解分别原创编写，不使用机器翻译充当课程中文稿。

习题通过知识段ID及完整双语情境关联到具体例子。默认英语，可切换简体中文，课程与题库全部随应用离线提供。完整600节目录见 [CURRICULUM_CATALOG-1.2.1.md](deliverables/CURRICULUM_CATALOG-1.2.1.md)。以下保留原有60节综合课目录，新增主题、双语讲解及参考索引可在该总目录与课程源文件中核对。

讲解、生活场景、数字算例、题目与选项均为原创教学编写。教材章节和论文用来核对原理和提供延伸阅读；不把教学例子标成论文实验数据，也不复制书籍的正文、图表或习题。应用的示意图由 SwiftUI 在本地绘制。阅读某些教材原文需要网络。

核心参考包括 Poole / Mackworth《Artificial Intelligence: Foundations of Computational Agents》第三版、Zhang 等《Dive into Deep Learning》、James 等《An Introduction to Statistical Learning with Applications in Python》、Goodfellow 等《Deep Learning》及 Russell / Norvig《Artificial Intelligence: A Modern Approach》第四版的主题目录。论文包括 Attention Is All You Need、word2vec、RAG、DDPM、Model Cards 和 Datasheets for Datasets。AIMA 的链接仅作为延伸阅读目录，不声明取用了其未提供的全文。

新增参考包括 AIMA 的因果网络、机器人、约束传播与伦理章节目录，以及 LoRA、知识蒸馏、整数推理量化、间接提示注入、指令微调和人类反馈论文。共60个参考条目，含5部教材的章节索引、12篇论文和2项 Apple 官方文档。具体对应关系随每节课程展示；不把文档或目录链接声称为已取得的教材全文。

## 课程目录

### 入门 / Beginner

| 课程 | 三个知识点 | 习题 |
|---|---|---:|
| 1. 什么是人工智能？ / What Is AI? | 任务，不是魔法；从例子学习；能力各不相同 | 6 |
| 2. 规则与学习 / Rules and Learning | 明确的规则；学习出的模式；组合方法 | 6 |
| 3. 输入、传感器与输出 / Inputs, Sensors, and Outputs | 传感器提供观测；处理连接输入和结果；行动影响环境 | 6 |
| 4. 模式与预测 / Patterns and Predictions | 模式概括重复现象；相关观测；预测错误揭示局限 | 6 |
| 5. 阅读数据表 / Reading Data Tables | 行描述样本；列描述属性；缺失不等于零 | 6 |
| 6. 特征与标签 / Features and Labels | 特征是线索；标签是目标答案；特征与目标不同 | 6 |
| 7. 把事物分类 / Sorting into Categories | 类别回答属于哪一种；决策边界；未知样本 | 6 |
| 8. 预测一个数值 / Predicting a Number | 数值与类别；简单数值规则；残差误差 | 6 |
| 9. 错误与反馈 / Mistakes and Feedback | 反馈需要比较；纠正不等于立刻学习；测量多个样本 | 6 |
| 10. 学习与新样本 / Learning and New Examples | 训练样本；留出样本；泛化 | 6 |
| 11. 图片也是数字 / Pictures Are Numbers | 像素；颜色通道；识别需要语境 | 6 |
| 12. 从声音到文字 / From Sound to Words | 声音信号；语音识别；噪声与声音差异 | 6 |
| 13. 词语需要语境 / Words Need Context | 一个词有多个意思；顺序改变意义；语言预测有局限 | 6 |
| 14. 寻找路线 / Finding a Route | 地点作为节点；路径连接起点和目标；步数最少不一定最快 | 6 |
| 15. 为什么应用会推荐 / Why Apps Recommend Things | 偏好作为证据；相似用户与物品；反馈循环 | 6 |
| 16. 机器人、目标与行动 / Robots, Goals, and Actions | 智能体会行动；目标定义成功；再次观测 | 6 |
| 17. 生成故事与图片 / Generating Stories and Pictures | 生成产生候选内容；请求引导内容；人来修改与选择 | 6 |
| 18. AI 编造时怎么办 / When AI Makes Things Up | 流畅不等于真实；核对可识别来源；检查强度匹配后果 | 6 |
| 19. 隐私与安全分享 / Privacy and Safe Sharing | 个人信息；只分享必要信息；同意与控制 | 6 |
| 20. 公平与可访问性 / Fairness and Accessibility | 样本里有哪些人；可访问性减少障碍；公平检查比较结果 | 6 |

### 基础 / Fundamentals

| 课程 | 三个知识点 | 习题 |
|---|---|---:|
| 1. 搜索与算法 / Search and Algorithms | 状态与行动；广度优先搜索；启发式 | 6 |
| 2. 逻辑与约束 / Logic and Constraints | 真与假；蕴含；约束满足 | 6 |
| 3. 概率与不确定性 / Probability and Uncertainty | 频率与概率；条件概率；置信度不等于确定性 | 6 |
| 4. 向量与相似性 / Vectors and Similarity | 坐标；距离；点积 | 6 |
| 5. 训练、验证与测试数据 / Training, Validation, and Test Data | 三种角色；信息泄漏；时间与分组 | 6 |
| 6. 准确率、精确率与召回率 / Accuracy, Precision, and Recall | 混淆计数；精确率与召回率；不平衡数据 | 6 |
| 7. 线性预测 / Linear Prediction | 斜率与截距；残差；直线的局限 | 6 |
| 8. 从邻居中学习 / Learning from Neighbors | 最近邻；选择k；单位与尺度 | 6 |
| 9. 决策树 / Decision Trees | 分支问题；有效划分；深度与过拟合 | 6 |
| 10. 无标签寻找分组 / Finding Groups without Labels | 无监督分组；k均值；检查分组 | 6 |
| 11. 清理与表示数据 / Cleaning and Representing Data | 缺失不等于零；类别需编码；记录数据来源 | 6 |
| 12. 损失与梯度下降 / Loss and Gradient Descent | 可测量目标；梯度方向；学习率 | 6 |
| 13. 泛化与过拟合 / Generalization and Overfitting | 记忆与泛化；正则化；提前停止 | 6 |
| 14. 神经网络 / Neural Networks | 加权组合；非线性；学习许多权重 | 6 |
| 15. 机器如何看图 / How Machines See Images | 图像数组；共享滤波器；条件变化 | 6 |
| 16. 序列、词元与语言 / Sequences, Tokens, and Language | 顺序承载含义；分词与词元化；下一词元预测 | 6 |
| 17. 提示与上下文 / Prompts and Context | 明确任务；上下文有上限；不可信指令 | 6 |
| 18. 嵌入与检索 / Embeddings and Retrieval | 学习到的表示；相似度检索；检索结合生成 | 6 |
| 19. 通过奖励学习 / Learning through Rewards | 智能体与环境；延迟奖励；探索与利用 | 6 |
| 20. 偏差、隐私与来源质量 / Bias, Privacy, and Source Quality | 代表性与伤害；数据最小化；证据与主张 | 6 |

### 进阶 / Advanced

| 课程 | 三个知识点 | 习题 |
|---|---|---:|
| 1. 问题定义与基线 / Problem Formulation and Baselines | 定义目标；简单基线；代价与部署 | 6 |
| 2. 模型中的线性代数 / Linear Algebra for Models | 形状与乘法；线性组合；范数与几何 | 6 |
| 3. 贝叶斯与朴素贝叶斯 / Bayes and Naive Bayes | 贝叶斯公式；条件独立；平滑 | 6 |
| 4. 多变量回归 / Multivariable Regression | 设计矩阵；平方误差拟合；系数与共线性 | 6 |
| 5. 逻辑分类与交叉熵 / Logistic Classification and Cross-Entropy | Sigmoid概率；交叉熵；多类Softmax | 6 |
| 6. 小批量优化 / Optimization with Mini-Batches | 经验风险；小批量梯度；数值规范 | 6 |
| 7. 正则化与交叉验证 / Regularization and Cross-Validation | 带惩罚目标；k折评估；选择与评估 | 6 |
| 8. 支持向量机 / Support Vector Machines | 边界与间隔；惩罚参数C；核相似性 | 6 |
| 9. 树、森林与提升 / Trees, Forests, and Boosting | 装袋法；随机森林；提升法 | 6 |
| 10. 主成分与聚类 / Principal Components and Clustering | 方差方向；压缩与缩放；聚类几何 | 6 |
| 11. 反向传播与计算图 / Backpropagation and Computation Graphs | 计算图；链式法则；梯度检查 | 6 |
| 12. 卷积网络详解 / Convolutional Networks in Detail | 互相关；输出维度；感受野 | 6 |
| 13. 循环网络与记忆 / Recurrent Networks and Memory | 隐藏状态；长距离依赖；门控记忆 | 6 |
| 14. 注意力与Transformer / Attention and Transformers | 查询、键与值；位置与掩码；多头与计算代价 | 6 |
| 15. 词向量与语义几何 / Word Vectors and Semantic Geometry | 基于语境的目标；余弦与类比局限；静态与语境化 | 6 |
| 16. 预训练与适配 / Pretraining and Adaptation | 自监督目标；微调与适配器；按目标用途评估 | 6 |
| 17. 构建与评估RAG / Building and Evaluating RAG | 索引与检索；区分错误来源；时效与访问控制 | 6 |
| 18. 扩散模型 / Diffusion Models | 前向加噪；学习去噪；采样与条件化 | 6 |
| 19. MDP与Q学习 / MDPs and Q-Learning | 马尔可夫决策过程；贝尔曼目标；更新与安全探索 | 6 |
| 20. 文档、监测与部署 / Documentation, Monitoring, and Deployment | 模型与数据文档；监测与漂移；人工控制与回滚 | 6 |

## 参考条目

应用内每节课程只展示相关的参考条目，并注明作者、年份、章节或论文名称。

- **agents** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 1.1 What Is AI?. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch1.S1.html)
- **situated** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 1.3 Agents Situated in Environments. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch1.S3.html)
- **search** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 3.5 Uninformed Search. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch3.S5.html)
- **heuristics** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 3.6 Heuristic Search. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch3.S6.html)
- **constraints** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 4.1 Constraint Satisfaction Problems. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch4.S1.html)
- **logic** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 5.1 Propositions. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch5.S1.html)
- **learning** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 7.1 Learning Issues. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch7.S1.html)
- **probability** — David L. Poole; Alan K. Mackworth (2023). *Artificial Intelligence: Foundations of Computational Agents, 3rd ed.*. 9.1 Probability. [原始来源](https://artint.info/3e/html/ArtInt3e.Ch9.S1.html)
- **algebra** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 2.3 Linear Algebra. [原始来源](https://d2l.ai/chapter_preliminaries/linear-algebra.html)
- **stats** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 2.6 Probability and Statistics. [原始来源](https://d2l.ai/chapter_preliminaries/probability.html)
- **preprocessing** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 2.2 Data Preprocessing. [原始来源](https://d2l.ai/chapter_preliminaries/pandas.html)
- **regression** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 3.1 Linear Regression. [原始来源](https://d2l.ai/chapter_linear-regression/linear-regression.html)
- **softmax** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 4.1 Softmax Regression. [原始来源](https://d2l.ai/chapter_linear-classification/softmax-regression.html)
- **generalization** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 3.6 Generalization. [原始来源](https://d2l.ai/chapter_linear-regression/generalization.html)
- **mlp** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 5.1 Multilayer Perceptrons. [原始来源](https://d2l.ai/chapter_multilayer-perceptrons/mlp.html)
- **backprop** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 5.3 Backpropagation. [原始来源](https://d2l.ai/chapter_multilayer-perceptrons/backprop.html)
- **regularization** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 3.7 Weight Decay. [原始来源](https://d2l.ai/chapter_linear-regression/weight-decay.html)
- **dropout** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 5.6 Dropout. [原始来源](https://d2l.ai/chapter_multilayer-perceptrons/dropout.html)
- **convolution** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 7.2 Convolutions for Images. [原始来源](https://d2l.ai/chapter_convolutional-neural-networks/conv-layer.html)
- **sequences** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 9.1 Working with Sequences. [原始来源](https://d2l.ai/chapter_recurrent-neural-networks/sequence.html)
- **language** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 9.3 Language Models. [原始来源](https://d2l.ai/chapter_recurrent-neural-networks/language-model.html)
- **rnn** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 9.4 Recurrent Neural Networks. [原始来源](https://d2l.ai/chapter_recurrent-neural-networks/rnn.html)
- **attention** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 11.7 Transformer. [原始来源](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html)
- **pretraining** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 11.9 Large-Scale Pretraining. [原始来源](https://d2l.ai/chapter_attention-mechanisms-and-transformers/large-pretraining-transformers.html)
- **optimization** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 12.3 Gradient Descent. [原始来源](https://d2l.ai/chapter_optimization/gd.html)
- **embeddings** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 15.1 Word Embedding (word2vec). [原始来源](https://d2l.ai/chapter_natural-language-processing-pretraining/word2vec.html)
- **recommendation** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 21.3 Matrix Factorization. [原始来源](https://d2l.ai/chapter_recommender-systems/mf.html)
- **qlearning** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 17.3 Q-Learning. [原始来源](https://d2l.ai/chapter_reinforcement-learning/qlearning.html)
- **linear-regression** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 3: Linear Regression (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch03-linreg-lab.html)
- **knn** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 4: Classification (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch04-classification-lab.html)
- **crossval** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 5: Resampling (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch05-resample-lab.html)
- **trees** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 8: Tree-Based Methods (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch08-baggboost-lab.html)
- **svm** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 9: Support Vector Machines (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch09-svm-lab.html)
- **clustering** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 12: Unsupervised Learning (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch12-unsup-lab.html)
- **pca** — Gareth James; Daniela Witten; Trevor Hastie; Robert Tibshirani; Jonathan Taylor (2023). *An Introduction to Statistical Learning with Applications in Python*. Chapter 12: Principal Components (official companion). [原始来源](https://intro-stat-learning.github.io/ISLP/labs/Ch12-unsup-lab.html)
- **aima** — Stuart Russell; Peter Norvig (2020). *Artificial Intelligence: A Modern Approach, 4th ed.*. Table of contents: perception, learning, language. [原始来源](https://aima.cs.berkeley.edu/contents.html)
- **bayes** — Ian Goodfellow; Yoshua Bengio; Aaron Courville (2016). *Deep Learning*. Chapter 3: Probability and Information Theory. [原始来源](https://www.deeplearningbook.org/contents/prob.html)
- **transformer** — Ashish Vaswani et al. (2017). *Attention Is All You Need*. Research paper · arXiv author version. [原始来源](https://arxiv.org/abs/1706.03762)
- **word2vec** — Tomas Mikolov et al. (2013). *Efficient Estimation of Word Representations in Vector Space*. Research paper · arXiv author version. [原始来源](https://arxiv.org/abs/1301.3781)
- **rag** — Patrick Lewis et al. (2020). *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks*. Research paper · arXiv author version. [原始来源](https://arxiv.org/abs/2005.11401)
- **diffusion** — Jonathan Ho; Ajay Jain; Pieter Abbeel (2020). *Denoising Diffusion Probabilistic Models*. Research paper · arXiv author version. [原始来源](https://arxiv.org/abs/2006.11239)
- **modelcards** — Margaret Mitchell et al. (2019). *Model Cards for Model Reporting*. Research paper · arXiv author version. [原始来源](https://arxiv.org/abs/1810.03993)
- **datasheets** — Timnit Gebru et al. (2021). *Datasheets for Datasets*. Research paper · arXiv author version. [原始来源](https://arxiv.org/abs/1803.09010)
- **lstm** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 10.1 Long Short-Term Memory. [原始来源](https://d2l.ai/chapter_recurrent-modern/lstm.html)
- **minibatch** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 12.5 Minibatch Stochastic Gradient Descent. [原始来源](https://d2l.ai/chapter_optimization/minibatch-sgd.html)
- **padding** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 7.3 Padding and Stride. [原始来源](https://d2l.ai/chapter_convolutional-neural-networks/padding-and-strides.html)
- **pooling** — Aston Zhang; Zachary C. Lipton; Mu Li; Alexander J. Smola (2023). *Dive into Deep Learning*. 7.5 Pooling. [原始来源](https://d2l.ai/chapter_convolutional-neural-networks/pooling.html)

## 更新与进度

新课程采用独立编号。旧三题课程的成绩不会混算为新六题课程的成绩；旧数据和收藏不因删除硕博级别而被整体丢弃。旧的硕博偏好会迁移为进阶偏好，沿用原 university 存储值。

后续课程扩充应继续在 Curriculum.json 中维护双语正文、可选例子、独立题目及 referenceIDs，再运行课程完整性和应用回归测试。不能仅修改付费页的数量文案。
