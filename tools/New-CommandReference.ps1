<#
.SYNOPSIS
Generate the script reference under docs/commands from the script's own help.

.DESCRIPTION
The reference is generated, never hand-edited: the comment-based help at the top of
AppLifecycleAnalyzer.ps1 is the single source, so the documentation cannot drift from the script.
Run it after changing the help or the parameters, and commit the result.

This tool is one file, so there is one page. Get-Help on a .ps1 returns the same shape as for a
function, which is why this reads like the generator in the module-shaped tools.

.PARAMETER Check
Generate into memory and compare against docs/commands. Exits non-zero on a difference instead of
writing anything.

.PARAMETER SiteContentPath
Also write the same content as a page for simonvedder.com/tools, into <path>/app-lifecycle-analyzer/.
Same source, different wrapper: the site template supplies the heading and the navigation.

.EXAMPLE
./tools/New-CommandReference.ps1

.EXAMPLE
./tools/New-CommandReference.ps1 -Check

.EXAMPLE
# Regenerate, and publish the same content to the tools site.
./tools/New-CommandReference.ps1 -SiteContentPath ../simonvedder-tools/src/content/commands
#>
[CmdletBinding()]
param(
  [Parameter()]
  [switch]$Check,

  # Point it at the tools site's src/content/commands folder.
  [Parameter()]
  [string]$SiteContentPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path $repoRoot 'AppLifecycleAnalyzer.ps1'
if (-not (Test-Path -Path $scriptPath)) { throw "No script at $scriptPath." }

$common = @(
  'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction',
  'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer',
  'PipelineVariable', 'WhatIf', 'Confirm'
)

function Format-HelpText {
  # Help text arrives as an array of objects with a Text property, or as plain strings.
  param([Parameter()][AllowNull()]$Text)
  $parts = @($Text | ForEach-Object { if ($null -eq $_) { '' } elseif ($_ -is [string]) { $_ } else { [string]$_.Text } })
  $joined = ($parts -join "`n").Trim()
  return ($joined -replace "`r`n", "`n")
}

function Format-Cell {
  # One table cell: no line breaks, no unescaped pipes.
  param([Parameter()][AllowNull()][string]$Text)
  if (-not $Text) { return '' }
  return (($Text -replace '\s*\n\s*', ' ') -replace '\|', '\|').Trim()
}

$item = Get-Item -Path $scriptPath
$name = $item.Name
$help = Get-Help -Name $item.FullName -Full
$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add("# $name")
$lines.Add('')
$synopsis = Format-HelpText $help.Synopsis
if ($synopsis) { $lines.Add("> $synopsis"); $lines.Add('') }

$description = Format-HelpText $help.Description
if ($description) { $lines.Add($description); $lines.Add('') }

$lines.Add('## Syntax')
$lines.Add('')
$lines.Add('```powershell')
# Get-Command -Syntax renders the parameter sets as text; the help object does not. A script's
# syntax carries the absolute path it was read from, and an alias line. Neither means anything to
# a reader, so both are reduced to how the file is actually called.
foreach ($set in @((Get-Command -Name $item.FullName -Syntax) -split "`r?`n")) {
  $text = $set.Trim()
  if ($text -match '\(alias\)') { continue }
  $text = $text.Replace($item.FullName, "./$name")
  if ($text) { $lines.Add($text); $lines.Add('') }
}
while ($lines.Count -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
$lines.Add('```')
$lines.Add('')

$notes = Format-HelpText $help.alertSet.alert
if ($notes) {
  $lines.Add('## Requirements and notes')
  $lines.Add('')
  $lines.Add($notes)
  $lines.Add('')
}

$parameters = @($help.parameters.parameter | Where-Object { $_.name -notin $common })
$lines.Add('## Parameters')
$lines.Add('')
if ($parameters.Count) {
  $lines.Add('| Name | Type | Required | Pipeline | Default | Description |')
  $lines.Add('|---|---|---|---|---|---|')
  foreach ($parameter in $parameters) {
    $type = [string]$parameter.type.name
    $required = if ("$($parameter.required)" -eq 'true') { 'yes' } else { 'no' }
    $pipeline = if ("$($parameter.pipelineInput)" -like '*true*') { 'yes' } else { 'no' }
    $default = Format-Cell ([string]$parameter.defaultValue)
    if ($default -in '', 'None', 'False') { $default = '' }
    $text = Format-Cell (Format-HelpText $parameter.description)
    $lines.Add("| ``-$($parameter.name)`` | $type | $required | $pipeline | $default | $text |")
  }
}
else {
  $lines.Add('This script takes no parameters of its own.')
}
$lines.Add('')

$examples = @($help.examples.example)
if ($examples.Count) {
  $lines.Add('## Examples')
  $lines.Add('')
  $index = 0
  foreach ($example in $examples) {
    $index++
    $code = ((Format-HelpText $example.code) -replace '^PS>\s*', '').Trim()
    $remark = Format-HelpText $example.remarks
    $lines.Add("### Example $index")
    $lines.Add('')
    $lines.Add('```powershell')
    $lines.Add($code)
    $lines.Add('```')
    if ($remark) { $lines.Add(''); $lines.Add($remark) }
    $lines.Add('')
  }
}

$lines.Add('---')
$lines.Add('')
$lines.Add('[README](../../README.md) | [Tool page](https://simonvedder.com/tools/app-lifecycle-analyzer/)')
$lines.Add('')
$lines.Add('*Generated from the comment-based help by `tools/New-CommandReference.ps1`. Edit the help in the script, not this file.*')

$page = ($lines -join "`n").TrimEnd() + "`n"

# The site template supplies the heading and the navigation, so its page is the same content from
# '## Syntax' down, with the synopsis moved into frontmatter.
$body = [System.Collections.Generic.List[string]]::new()
if ($description) { $body.Add($description); $body.Add('') }
$started = $false
foreach ($line in $lines) {
  if ($line -eq '## Syntax') { $started = $true }
  if (-not $started) { continue }
  if ($line -eq '---') { break }
  $body.Add(($line -replace '^## Requirements and notes$', '## Requirements'))
}

$fileName = "$($item.BaseName).md"
$target = Join-Path $repoRoot 'docs' 'commands'
$targetFile = Join-Path $target $fileName

if ($Check) {
  if (-not (Test-Path -Path $targetFile)) {
    throw "Missing docs/commands/$fileName. Run ./tools/New-CommandReference.ps1 and commit the result."
  }
  $current = (Get-Content -Path $targetFile -Raw) -replace "`r`n", "`n"
  if ($current -ne $page) {
    throw "docs/commands/$fileName is out of date. Run ./tools/New-CommandReference.ps1 and commit the result."
  }
  "The script reference matches the help of $name."
  return
}

if ($SiteContentPath) {
  $repoName = Split-Path -Path $repoRoot -Leaf
  $siteTarget = Join-Path $SiteContentPath $repoName
  $null = New-Item -ItemType Directory -Path $siteTarget -Force
  foreach ($file in @(Get-ChildItem -Path $siteTarget -Filter '*.md' -ErrorAction SilentlyContinue)) { Remove-Item -Path $file.FullName -Force }
  $front = @(
    '---'
    "tool: $repoName"
    "command: $name"
    # Folded onto one line: a synopsis that wraps in the help would otherwise become a
    # multi-line YAML scalar, which parses but reads like a mistake in the file.
    "synopsis: `"$((Format-Cell $synopsis) -replace '"', '\"')`""
    'order: 1'
    '---'
    ''
  ) -join "`n"
  $siteFile = Join-Path $siteTarget ($item.BaseName.ToLowerInvariant() + '.md')
  Set-Content -Path $siteFile -Value ($front + (($body -join "`n").TrimEnd() + "`n")) -Encoding utf8 -NoNewline
  "Wrote $siteFile"
}

$null = New-Item -ItemType Directory -Path $target -Force
Set-Content -Path $targetFile -Value $page -Encoding utf8 -NoNewline
"Wrote docs/commands/$fileName from the help of $name."
