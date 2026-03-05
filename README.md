# gemini-cli-search

一个 openClaw skill，让 AI 能够调用 Google Gemini CLI 进行深度研究和实时网络搜索，获得带引用的分析结果。

## 能做什么

- **实时网络搜索**：通过 Google Search Grounding 获取带 `[1]` `[2]` 引用标记的最新信息
- **超大上下文**：利用 Gemini 的 1M Token 窗口处理大型代码库或文档
- **代码深度分析**：将本地文件喂给 Gemini 进行架构分析、安全审计等
- **跨平台**：同时支持 macOS / Linux / Git Bash 和 Windows PowerShell

## 前置条件

1. 安装 Gemini CLI：
   ```bash
   npm install -g @google/gemini-cli
   ```
2. 登录 Gemini（仅首次需要，凭证会持久保存）：
   ```bash
   gemini auth login
   ```
   > 建议使用专用 Google 账号，而非个人主账号。

## 安装 Skill

将此仓库链接发给 openClaw，让它自动完成安装：

> 帮我安装这个 skill：`https://github.com/brucevanfdm/gemini-cli-search-skill`

## 使用方式

安装后，直接在对话中自然表达需求即可，AI 会自动判断何时调用该 skill：

- "帮我搜索 2026 年 AI Agent 的最新发展趋势"
- "分析这个项目的代码架构，并搜索相关最佳实践"
- "用 Gemini 帮我做一个竞品对比研究"
- "检查这段代码的安全漏洞，并搜索最新防御方案"

也可以直接指示："用 Gemini 搜索..."、"问一下 Gemini..."

## 工作原理

此 skill 本质上是对 `gemini -p "<prompt>"` 命令的封装。使用 `--search` 时，会在 prompt 前注入搜索指令以提高 Google Search Grounding 的触发概率（注意：模型仍会自主决策是否调用搜索）。文件内容通过 prompt 拼接传入，充分利用 Gemini 的超大上下文窗口。

## 配额说明

- 免费额度（个人 Google 账户）：60 请求/分钟，1000 请求/天
- 遇到 429 配额耗尽错误时，等待每日配额重置即可

## 常见问题

| 问题                          | 解决方法                                                            |
| ----------------------------- | ------------------------------------------------------------------- |
| `gemini: command not found` | 执行 `npm install -g @google/gemini-cli`                          |
| 401 认证错误                  | 执行 `gemini auth login` 重新登录                                 |
| 没有搜索引用 `[1]` `[2]`  | 确认使用了 `--search`，并在查询中加入时间线索（"最新""2026年"等） |
| 429 配额耗尽                  | 等待配额重置，或升级到付费计划                                      |
| Windows 上 bash 脚本报错      | 改用 PowerShell 版本 `scripts/gemini-cli-search.ps1`              |

## License

MIT
