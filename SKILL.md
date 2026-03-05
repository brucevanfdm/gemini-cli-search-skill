---
name: gemini-cli-search
description: "Use Google Gemini CLI as an extended AI brain with real-time web search and 1M token context. Trigger when: (1) user needs deep research with source citations — tech trends, security analysis, competitive comparisons; (2) analyzing large codebases or documents that exceed normal context limits; (3) user explicitly says 'ask Gemini', 'use Gemini', or 'search with Gemini'; (4) fact-checking or getting up-to-date information where training data may be stale; (5) multi-step research tasks that combine code analysis with web-grounded context. Prefer this over WebSearch when the task needs structured analysis, not just a quick lookup."
---

# Gemini CLI Search Skill

将 Google Gemini CLI 作为扩展大脑，具备以下核心能力：
- **Google Search Grounding** — 带引用的实时搜索（通过 `--search` 参数触发）
- **1M Token 上下文** — 超大窗口处理大量文档和代码
- **代码分析** — 深度代码审查和架构建议
- **跨平台** — 同时支持 Bash（macOS/Linux/Git Bash）和 PowerShell（Windows 原生）

## 何时不用

以下情况优先用其他工具（更快）：
- 简单事实查询 → WebSearch
- 只需抓取某个具体页面的内容 → WebFetch
- 任务已有明确的目标 URL → 浏览器工具

## 前置条件

首次使用前需登录 Gemini CLI：
```bash
gemini auth login
```
登录后凭证会持久保存，后续无需重复操作。

## 使用方法

根据操作系统选择对应脚本（从 skill 根目录执行）：

| 平台 | 脚本 |
|------|------|
| macOS / Linux / Git Bash | `scripts/gemini-cli-search.sh` |
| Windows PowerShell | `scripts/gemini-cli-search.ps1` |

### 命令行参数

```
gemini-brain "<查询内容>" [选项]

选项:
  -s, --search          启用 Google Search Grounding
  -f, --files <路径>    附加文件内容（多个文件用空格分隔，带空格的路径用引号包裹）
  -j, --json            输出 JSON 格式（包含 token 统计）
  -m, --model <模型>    指定模型 (pro/flash/flash-lite)
  -h, --help            显示帮助信息
```

### 典型用法

**1. 深度研究（启用搜索）**
```bash
scripts/gemini-cli-search.sh "分析2026年AI Agent发展趋势，提供关键技术和公司" --search
```

**2. 代码分析**
```bash
scripts/gemini-cli-search.sh "分析这段代码的架构问题和优化建议" --files "src/main.py" "src/utils.py"
```

**3. 文件 + 搜索混合**
```bash
scripts/gemini-cli-search.sh "基于这些代码，搜索最新的安全最佳实践" --files "app.js" --search
```

**4. JSON 输出（用于自动化）**
```bash
scripts/gemini-cli-search.sh "研究主题" --search --json
```

输出格式：
```json
{
  "response": "分析结果...",
  "stats": {
    "input_tokens": 1234,
    "output_tokens": 567,
    "total_tokens": 1801
  }
}
```

## 搜索功能说明

Gemini CLI 的搜索由**模型自主决策**，`--search` 只是在 prompt 前插入搜索指令来提高触发概率，不能强制。以下情况更容易触发搜索：

- 使用了 `--search` 参数
- 查询中包含时间线索（"最新""2026年"等）

普通问题通常依赖训练数据，不触发搜索。

## 输出特点

- **带引用标记**：`[1]`, `[2]` 等对应搜索来源（文本格式，非可点击链接）
- **结构化分析**：自动分段、列表、表格
- **代码块**：带语法高亮的代码建议

## 成本与配额

- 默认使用 Gemini 2.5 Pro（可通过 `-m` 切换）
- 免费额度（截至 2026 年初）：60 请求/分钟，1000 请求/天（个人 Google 账户）
- 搜索 grounding 会增加 token 消耗
- 遇到 `You have exhausted your capacity` 时，等待配额重置（通常每天）

## 示例场景

**技术选型研究**
```bash
scripts/gemini-cli-search.sh "对比 PostgreSQL vs MySQL vs TiDB 在10亿级数据场景下的优劣" --search
```

**代码审查**
```bash
scripts/gemini-cli-search.sh "分析这个微服务架构的耦合问题，给出重构建议" --files "service-a/main.go" "service-b/main.go"
```

**安全审计**
```bash
scripts/gemini-cli-search.sh "检查这段代码的安全漏洞，并搜索最新防御方案" --files "routes.py" --search
```

## 高级用法

当单轮 Gemini 结果深度不足（如需要具体 CVE 编号、版本数据、官方原文），或需要交叉验证关键结论时，可采用**多轮递进式检索策略**，结合 Gemini 搜索和 web_fetch 精准获取。详见 [references/advanced-strategies.md](references/advanced-strategies.md)。

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| 没有搜索引用 `[1]` `[2]` | 确认使用了 `--search`；检查查询是否包含搜索意图 |
| `gemini: command not found` | 安装 Gemini CLI：`npm install -g @google/gemini-cli` |
| 未登录 / 401 认证错误 | 执行 `gemini auth login` 完成登录 |
| 配额耗尽 429 错误 | 等待配额重置或升级付费计划 |
| Windows 上 bash 脚本不工作 | 使用 PowerShell 版本 `scripts/gemini-cli-search.ps1` |

## 已知限制

1. **搜索触发非强制** — 即使使用 `--search`，模型仍可能决定不调用搜索
2. **引用格式** — 引用标记是纯文本 `[1]`，不是可点击链接
3. **来源验证** — 建议对关键信息用其他工具交叉验证
