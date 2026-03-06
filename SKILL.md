---
name: gemini-cli-search
description: "调用 Google Gemini CLI 作为扩展 AI 大脑，获取带引用来源的实时网络搜索结果，并提供 1M token 超长上下文分析能力。遇到以下情况应主动使用本 skill：(1) 需要最新信息或带引用的深度研究——科技趋势、安全漏洞、竞品对比、近几个月内的事件，任何 Claude 训练数据可能过时的领域；(2) 分析超出当前上下文容量的大型代码库、日志或文档；(3) 用户说"用 Gemini 搜"、"让 Gemini 看"、"ask Gemini"、"Gemini 搜索"；(4) 需要综合多来源信息并生成结构化分析报告；(5) 要交叉验证某个技术说法是否仍然准确。在 WebSearch 和本 skill 都适用的场景，凡是涉及结构化分析、多来源综合、文件辅助推理，一律优先本 skill。即使用户没有明确提到 Gemini，只要任务需要实时搜索 + 深度分析组合，都应考虑本 skill。"
---

# Gemini CLI Search Skill

将 Google Gemini CLI 作为扩展大脑，核心能力：

- **Google Search Grounding** — 带引用的实时搜索
- **1M Token 上下文** — 超大窗口，可处理大型代码库或文档
- **跨环境** — 适用于 Claude Code、openClaw 等所有带 Bash 工具的 CLI 环境

## 运行环境适配

本 skill 通过调用系统全局安装的 `gemini` 命令工作，**不依赖 skill 目录路径**，因此在 Claude Code 和 openClaw 中行为完全一致。

| 环境 | 是否支持 | 说明 |
|------|---------|------|
| Claude Code | ✓ | 用 `Bash` 工具直接调用 `gemini` |
| openClaw | ✓ | 用 `Bash` 工具直接调用 `gemini` |
| Claude.ai / 无 Shell 环境 | ✗ | 降级为 `WebSearch` + `WebFetch` |

> `scripts/` 目录下的 `.sh` / `.ps1` 脚本是供用户**在终端手动运行**的便捷封装。Claude 执行时直接构建命令，不依赖这些脚本。

## 执行步骤

### 第一步：判断参数

| 用户意图 | 参数选择 |
|---------|---------|
| 需要最新信息、带引用来源 | 搜索模式（在 prompt 中加入搜索指令） |
| 有文件要分析 | 读取文件内容后注入 prompt |
| 深度分析、质量优先 | `--model gemini-2.5-pro` |
| 快速查询，时效要求低 | 无额外参数（默认 flash） |

### 第二步：构建并执行命令

用 `Bash` 工具直接调用全局 `gemini` 命令，根据意图构建 prompt：

**纯查询（无搜索需求）**
```bash
gemini -p "你的查询内容"
```

**搜索模式** — 在 prompt 前插入搜索指令，引导模型调用 Google Search Grounding：
```bash
gemini -p "Search for current information about the following. Include source citations as [1], [2], etc. Focus on specific facts, dates, versions from authoritative sources.

Query: 你的实际查询内容"
```

**文件分析** — 用 `Read` 工具读取文件内容后拼入 prompt（避免路径依赖问题）：
```bash
gemini -p "你的分析请求

---
Reference Files:
### File: path/to/file
\`\`\`
[用 Read 工具读取的文件内容]
\`\`\`" --model gemini-2.5-pro
```

**文件 + 搜索混合**：将上述两种 prompt 结构合并即可。

**指定模型**：在命令末尾追加 `--model gemini-2.5-pro`（深度分析）或省略（默认 flash）。

### 第三步：处理并整合输出

运行后**不要原样粘贴全部输出**，应当：

1. 提取核心结论和关键数据点，用自己的话整合给用户
2. 保留引用标记 `[1]` `[2]` 及对应来源
3. 对代码分析结果，直接呈现建议和问题，不重复冗余上下文

## 搜索技巧

`--search` 不能强制触发网络搜索，以下写法能显著提高实际搜索概率：

- **加入时间线索**：`"2026年最新"` `"近三个月"` `"当前稳定版"`
- **询问当前状态**：`"最新版本是什么"` `"现在推荐的做法是"`
- **要求来源**：在 prompt 中写明 `"cite your sources"` 或 `"附上参考链接"`
- **具体化查询**：`"Python 3.13 新特性"` 比 `"Python 新特性"` 更容易触发搜索

## 模型选择

| 场景 | 推荐 | 原因 |
|------|------|------|
| 快速问答、简单查询 | 默认（flash） | 速度快，配额消耗少 |
| 深度技术分析、架构设计 | `gemini-2.5-pro` | 推理更强，适合复杂任务 |
| 超大文件（>500K token） | 默认（flash） | Pro 处理超长上下文可能更慢 |
| 安全审计、代码审查 | `gemini-2.5-pro` | 准确性优先 |

## 何时不用本 skill

以下情况用其他工具更快：

- 简单事实查询 → `WebSearch`
- 抓取某个具体页面 → `WebFetch`
- 任务已有明确目标 URL → 直接 `WebFetch`
- 只需要 Claude 自身知识回答 → 直接回答
- 无 Bash 工具的环境 → `WebSearch` + `WebFetch` 组合

## 前置条件

首次使用前需登录（只需一次）：

```bash
gemini auth login
```

确认 gemini CLI 已安装：

```bash
gemini --version
# 若未安装：npm install -g @google/gemini-cli
```

## 多轮递进检索

当单轮结果不够深入（缺少具体 CVE 编号、官方原文、精确版本数据），说明需要多轮策略。此时**必须**阅读 [references/advanced-strategies.md](references/advanced-strategies.md)，其中包含 Gemini + WebFetch 的分层递进检索流程。

## 成本与配额

- 默认模型：Gemini CLI 内置默认（通常为 2.5 Flash）
- 免费额度（截至 2026 年初）：60 请求/分钟，1000 请求/天
- 搜索模式会增加 token 消耗
- 遇到 `You have exhausted your capacity` 时等待配额重置

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| 没有搜索引用 `[1]` `[2]` | 在 prompt 中加入时间线索，明确要求引用 |
| `gemini: command not found` | `npm install -g @google/gemini-cli` |
| 未登录 / 401 错误 | `gemini auth login` |
| 配额耗尽 429 | 等待重置或省略 `--model` 参数改用 flash |
| Windows 下 bash 调用异常 | 检查 Git Bash 是否正确安装；PowerShell 用户可手动运行 `scripts/gemini-cli-search.ps1` |

## 已知限制

1. **搜索非强制** — 即使加了搜索指令，模型仍可能不调用网络搜索
2. **引用格式** — `[1]` 是纯文本标记，不是可点击链接
3. **来源验证** — 关键信息建议用 `WebFetch` 交叉验证
