<#
.SYNOPSIS
    Gemini Brain Skill - Invoke Gemini CLI for deep research
.DESCRIPTION
    Google Search Grounding with citations. Windows PowerShell version.
#>

param(
    [Parameter(Position=0)]
    [string]$Query,

    [Alias('s')]
    [switch]$Search,

    [Alias('f')]
    [string[]]$Files,

    [Alias('j')]
    [switch]$Json,

    [Alias('m')]
    [string]$Model,

    [Alias('h')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Show-Help {
    Write-Host 'Usage: gemini-brain.ps1 "<query>" [options]'
    Write-Host ''
    Write-Host 'Options:'
    Write-Host '  -Search (-s)           Enable Google Search Grounding'
    Write-Host '  -Files (-f) <paths>    Attach file contents (comma-separated)'
    Write-Host '  -Json (-j)             Output JSON format (with token stats)'
    Write-Host '  -Model (-m) <model>    Specify model (pro/flash/flash-lite)'
    Write-Host '  -Help (-h)             Show this help'
    Write-Host ''
    Write-Host 'Examples:'
    Write-Host '  .\gemini-brain.ps1 "Analyze AI Agent trends in 2026" -Search'
    Write-Host '  .\gemini-brain.ps1 "Review code vulnerabilities" -Files src/main.py,src/utils.py'
    Write-Host '  .\gemini-brain.ps1 "Search latest security practices" -Files app.js -Search'
    Write-Host '  .\gemini-brain.ps1 "Research topic" -Search -Json'
}

if ($Help) {
    Show-Help
    exit 0
}

# Check gemini CLI
if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) {
    Write-Error 'gemini CLI not found. Install: npm install -g @google/gemini-cli'
    exit 1
}

# Check query
if ([string]::IsNullOrWhiteSpace($Query)) {
    Write-Error 'Please provide a query'
    Write-Host ''
    Show-Help
    exit 1
}

# Build full prompt
$FullPrompt = ''
$nl = [Environment]::NewLine
$fence = '```'

if ($Search) {
    $FullPrompt = "Search for current information about: $Query" + $nl + $nl
    $FullPrompt += 'Please search the web and provide:' + $nl
    $FullPrompt += '1. Comprehensive analysis with current, factual information' + $nl
    $FullPrompt += '2. Specific examples, dates, and case studies if available' + $nl
    $FullPrompt += '3. Include source citations using [1], [2], etc. format' + $nl
    $FullPrompt += '4. Focus on verifiable information from authoritative sources' + $nl + $nl
    $FullPrompt += "Query: $Query"
} else {
    $FullPrompt = $Query
}

# Attach file contents
if ($Files -and $Files.Count -gt 0) {
    $FullPrompt += $nl + $nl + '---' + $nl + 'Reference Files:' + $nl

    foreach ($file in $Files) {
        if (Test-Path $file) {
            $content = Get-Content -Path $file -Raw -Encoding UTF8
            $FullPrompt += $nl + "### File: $file" + $nl + $fence + $nl + $content + $nl + $fence + $nl
        } else {
            Write-Warning "File not found: $file"
        }
    }
}

# Build Gemini CLI args
$GeminiArgs = @('-p', $FullPrompt)

if (-not [string]::IsNullOrWhiteSpace($Model)) {
    $GeminiArgs += '--model'
    $GeminiArgs += $Model
}

if ($Json) {
    $GeminiArgs += '--output-format'
    $GeminiArgs += 'json'
}

# Execute Gemini CLI
& gemini @GeminiArgs 2>&1
