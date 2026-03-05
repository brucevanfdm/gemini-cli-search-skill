#!/bin/bash
# Gemini Brain Skill - 调用 Gemini CLI 进行深度研究
# 支持 Google Search Grounding 获取带引用的实时搜索结果
# 兼容 macOS / Linux / Windows (Git Bash)

set -euo pipefail

# 默认配置
OUTPUT_FORMAT="text"
MODEL=""
SEARCH_MODE=false
QUERY=""
FILES=()

# 显示帮助信息
show_help() {
  cat << 'EOF'
用法: gemini-brain.sh "<查询内容>" [选项]

选项:
  -s, --search          启用 Google Search Grounding（在查询中添加搜索指令）
  -f, --files <路径>    附加文件内容（可多次使用，或空格分隔多个文件）
  -j, --json            输出 JSON 格式（包含 token 统计）
  -m, --model <模型>    指定模型 (pro/flash/flash-lite)
  -h, --help            显示帮助信息

示例:
  # 深度研究并启用搜索
  gemini-brain.sh "分析2026年AI安全趋势" --search

  # 分析代码文件
  gemini-brain.sh "分析这段代码的漏洞" --files src/main.py src/utils.py

  # 搜索+文件混合分析
  gemini-brain.sh "基于代码搜索最新安全实践" --files app.js --search

  # JSON 输出（用于自动化）
  gemini-brain.sh "研究主题" --search --json
EOF
}

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--search)
      SEARCH_MODE=true
      shift
      ;;
    -f|--files)
      shift
      # 收集 --files 后面的所有非选项参数作为文件路径
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        FILES+=("$1")
        shift
      done
      ;;
    -j|--json)
      OUTPUT_FORMAT="json"
      shift
      ;;
    -m|--model)
      MODEL="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [[ -z "$QUERY" ]]; then
        QUERY="$1"
      fi
      shift
      ;;
  esac
done

# 检查 gemini CLI 是否可用
if ! command -v gemini &>/dev/null; then
  echo "错误: 未找到 gemini CLI。请先安装：npm install -g @google/gemini-cli" >&2
  exit 1
fi

# 检查查询内容
if [[ -z "$QUERY" ]]; then
  echo "错误: 请提供查询内容" >&2
  echo "" >&2
  show_help
  exit 1
fi

# 构建完整 prompt
FULL_PROMPT=""

if [[ "$SEARCH_MODE" == true ]]; then
  FULL_PROMPT="Search for current information about: $QUERY

Please search the web and provide:
1. Comprehensive analysis with current, factual information
2. Specific examples, dates, and case studies if available
3. Include source citations using [1], [2], etc. format
4. Focus on verifiable information from authoritative sources

Query: $QUERY"
else
  FULL_PROMPT="$QUERY"
fi

# 添加文件内容
if [[ ${#FILES[@]} -gt 0 ]]; then
  FULL_PROMPT="$FULL_PROMPT

---
Reference Files:
"
  for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
      FULL_PROMPT="$FULL_PROMPT
### File: $file
\`\`\`
$(cat "$file")
\`\`\`
"
    else
      echo "警告: 文件不存在: $file" >&2
    fi
  done
fi

# 构建 Gemini CLI 参数
GEMINI_ARGS=()

if [[ -n "$MODEL" ]]; then
  GEMINI_ARGS+=("--model" "$MODEL")
fi

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  GEMINI_ARGS+=("--output-format" "json")
fi

# 执行 Gemini CLI（非交互式模式）
gemini -p "$FULL_PROMPT" "${GEMINI_ARGS[@]}" 2>&1
