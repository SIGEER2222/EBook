param(
  [string]$Root = "..\末世异闻录\正文",
  [string[]]$Include = @("*.md"),
  [string[]]$Exclude = @(".git", ".vscode", "skills"),
  [switch]$Details
)

function Should-ExcludePath {
  param([string]$Path, [string[]]$ExcludeList)
  foreach ($ex in $ExcludeList) {
    if ($Path -like "*\$ex\*" -or $Path -like "*\$ex") { return $true }
  }
  return $false
}

# 数字格式化函数：自动转 k / w
function Format-Number {
  param([int]$Number)
  if ($Number -ge 10000) {
    return "{0:N2}w" -f ($Number / 10000)
  }
  elseif ($Number -ge 1000) {
    return "{0:N2}k" -f ($Number / 1000)
  }
  else {
    return $Number.ToString()
  }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootInput = $Root
if (-not [System.IO.Path]::IsPathRooted($rootInput)) {
  $rootInput = Join-Path $scriptDir $rootInput
}
$rootPath = Resolve-Path -LiteralPath $rootInput
$files = Get-ChildItem -LiteralPath $rootPath -Recurse -File -Include $Include |
  Where-Object { -not (Should-ExcludePath $_.FullName $Exclude) }

$totalNonWs = 0
$totalCjk = 0
$rows = @()

foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw
  $nonWs = ($text -replace "\s", "").Length
  $cjk = ([regex]::Matches($text, "[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]").Count)
  $totalNonWs += $nonWs
  $totalCjk += $cjk
  
  if ($Details) {
    $rows += [pscustomobject]@{
      File = $f.FullName
      NonWhitespaceChars = $nonWs
      CJKChars = $cjk
      # 格式化显示列
      '字数(非空白)' = Format-Number $nonWs
      '汉字(CJK)' = Format-Number $cjk
    }
  }
}

# 输出结果（自动格式化）
"Root: $rootPath"
"文件总数：$($files.Count)"
"总字数（不含空白）：$totalNonWs  ($(Format-Number $totalNonWs))"
"总汉字数（CJK）：$totalCjk  ($(Format-Number $totalCjk))"

if ($Details -and $rows.Count -gt 0) {
  ""
  "--- 单文件详情 ---"
  $rows | Sort-Object NonWhitespaceChars -Descending | 
    Select-Object File, '字数(非空白)', '汉字(CJK)' | 
    Format-Table -AutoSize
}