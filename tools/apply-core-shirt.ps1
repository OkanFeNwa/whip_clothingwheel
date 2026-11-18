<#
    apply-core-shirt.ps1 - adds the `shirt` glyph to the two WHIP glyph atlases and to the
    WhipGlyph editor alias. Run it after updating whip_core, because a core update can replace
    those files.

    MANUAL ONLY: it is not declared in fxmanifest.lua, is not served to NUI and is not loaded by
    the server. Nothing happens until you pass -Manual, which only apply-core-shirt.cmd does.
#>

[CmdletBinding()]
param(
    [switch]$Manual
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Manual) {
    Write-Host 'No changes made.'
    Write-Host 'This script only runs by hand: double-click tools/apply-core-shirt.cmd'
    exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$resources = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', '..'))
$backupDir = [System.IO.Path]::Combine($PSScriptRoot, 'backups')

function Find-ResourceDir {
    param([string]$Name)
    foreach ($candidate in @(
        [System.IO.Path]::Combine($resources, '[core]', $Name),
        [System.IO.Path]::Combine($resources, $Name)
    )) {
        if ([System.IO.Directory]::Exists($candidate)) { return $candidate }
    }
    return $null
}

function Get-Eol {
    param([string]$Text)
    if ($Text.Contains("`r`n")) { return "`r`n" }
    return "`n"
}

function Save-WithBackup {
    param(
        [string]$File,
        [string]$NewText
    )
    if (-not [System.IO.Directory]::Exists($backupDir)) {
        [void][System.IO.Directory]::CreateDirectory($backupDir)
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = [System.IO.Path]::Combine($backupDir, [System.IO.Path]::GetFileName($File) + '.bak.' + $stamp)
    $original = [System.IO.File]::ReadAllText($File)
    [System.IO.File]::WriteAllText($backup, $original, $utf8)
    [System.IO.File]::WriteAllText($File, $NewText, $utf8)
    Write-Host ('  backup: ' + $backup)
}

function New-ShirtBlock {
    param([string]$Indent)
    # Parenthesise every element: in PowerShell the comma binds tighter than `+`,
    # so `$Indent + 'a', $Indent + 'b'` would become one concatenated string.
    return @(
        ($Indent + '// A SHIRT: the clothing wheel''s own glyph. Added by whip_clothingwheel.'),
        ($Indent + '// The silhouette is the Material Design Icons `tshirt-crew` shape, drawn as an outline'),
        ($Indent + '// at the atlas''s 2.1 weight, next to `bag` and `phone` on the F1 wheel.'),
        ($Indent + 'shirt: ''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1"'''),
        ($Indent + '    + '' stroke-linecap="round" stroke-linejoin="round">'''),
        ($Indent + '    + ''<path d="M16 21H8a1 1 0 0 1-1-1v-7.93l-1.3 1a.996.996 0 0 1-1.41 0'''),
        ($Indent + '    +     ''l-2.83-2.78a.996.996 0 0 1 0-1.41L7.34 3H9c0 1.1 1.34 2 3 2s3-.9 3-2'''),
        ($Indent + '    +     ''h1.66l5.88 5.88c.39.39.39 1.02 0 1.41l-2.83 2.83'''),
        ($Indent + '    +     ''c-.39.38-1.02.38-1.41 0l-1.3-1V20a1 1 0 0 1-1 1"/></svg>'','),
        ''
    )
}

function Plan-JsAtlas {
    param(
        [string]$File,
        [string]$Label
    )

    if (-not [System.IO.File]::Exists($File)) {
        return @{ Status = 'skip'; Label = $Label; Message = ('file not found: ' + $File) }
    }

    $text = [System.IO.File]::ReadAllText($File)
    if ($text -match '(?m)\bshirt\s*:') {
        return @{ Status = 'ok'; Label = $Label }
    }

    $lines = [regex]::Split($text, "\r\n|\n|\r")
    $anchor = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*emote\s*:') { $anchor = $i; break }
    }
    if ($anchor -lt 0) {
        throw ('Cannot find the emote: anchor in ' + $File + '. whip_core layout changed: patch by hand.')
    }

    $indent = [regex]::Match($lines[$anchor], '^([ \t]*)').Groups[1].Value

    # Insert before the comment that documents `emote`, not between that comment and the entry.
    $insert = $anchor
    while ($insert -gt 0 -and $lines[$insert - 1].TrimStart().StartsWith('//')) { $insert-- }

    $block = New-ShirtBlock $indent
    $out = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -eq $insert) {
            foreach ($line in $block) { [void]$out.Add($line) }
        }
        [void]$out.Add($lines[$i])
    }

    $newText = [string]::Join((Get-Eol $text), $out)
    return @{ Status = 'patch'; Label = $Label; File = $File; NewText = $newText }
}

function Plan-GlyphType {
    param(
        [string]$File,
        [string]$Label
    )

    if (-not [System.IO.File]::Exists($File)) {
        return @{ Status = 'skip'; Label = $Label; Message = ('file not found: ' + $File) }
    }

    $text = [System.IO.File]::ReadAllText($File)
    $aliasStart = $text.IndexOf('---@alias WhipGlyph', [System.StringComparison]::Ordinal)
    if ($aliasStart -lt 0) {
        throw ('Cannot find the WhipGlyph alias in ' + $File + '. whip_core layout changed: patch by hand.')
    }
    $stringLine = $text.IndexOf('---| string', $aliasStart, [System.StringComparison]::Ordinal)
    if ($stringLine -lt 0) {
        throw ('Cannot find the WhipGlyph string line in ' + $File + '. whip_core layout changed: patch by hand.')
    }

    $aliasBlock = $text.Substring($aliasStart, $stringLine - $aliasStart)
    if ($aliasBlock.Contains("'shirt'")) {
        return @{ Status = 'ok'; Label = $Label }
    }

    $lastPipe = $aliasBlock.LastIndexOf('---|', [System.StringComparison]::Ordinal)
    if ($lastPipe -lt 0) {
        throw ('Cannot find a WhipGlyph alias line in ' + $File + '. whip_core layout changed: patch by hand.')
    }

    $tail = $aliasBlock.Substring($lastPipe)
    $eolMatch = [regex]::Match($tail, "\r\n|\n|\r")
    $lineEnd = if ($eolMatch.Success) { $lastPipe + $eolMatch.Index } else { $aliasBlock.Length }
    $insertAt = $aliasStart + $lineEnd
    $newText = $text.Insert($insertAt, " | 'shirt'")

    return @{ Status = 'patch'; Label = $Label; File = $File; NewText = $newText }
}

function Apply-Plan {
    param($Plan)
    switch ($Plan.Status) {
        'patch' {
            Save-WithBackup $Plan.File $Plan.NewText
            Write-Host ('  [PATCH] ' + $Plan.Label + ': ' + $Plan.File)
        }
        'ok' { Write-Host ('  [OK] ' + $Plan.Label + ': already patched') }
        'skip' { Write-Host ('  [SKIP] ' + $Plan.Label + ': ' + $Plan.Message) }
    }
}

$coreDir = Find-ResourceDir 'whip_core'
if (-not $coreDir) { throw ('whip_core not found under ' + $resources) }
$loadingDir = Find-ResourceDir 'whip_loadingscreen'

$plans = @(
    (Plan-JsAtlas ([System.IO.Path]::Combine($coreDir, 'html', 'js', 'glyphs.js')) 'whip_core / F1 atlas')
)

if ($loadingDir) {
    $plans += (Plan-JsAtlas ([System.IO.Path]::Combine($loadingDir, 'html', 'js', 'icons.js')) 'whip_loadingscreen / atlas')
} else {
    $plans += @{ Status = 'skip'; Label = 'whip_loadingscreen / atlas'; Message = 'resource not installed' }
}

$plans += (Plan-GlyphType ([System.IO.Path]::Combine($coreDir, 'types', 'client.lua')) 'whip_core / WhipGlyph type')

Write-Host ('[apply-core-shirt] resources: ' + $resources)
foreach ($plan in $plans) { Apply-Plan $plan }

$changed = @($plans | Where-Object { $_.Status -eq 'patch' }).Count
if ($changed -gt 0) {
    Write-Host ('[apply-core-shirt] ' + $changed + ' file patched. Backups are in tools/backups.')
    Write-Host '[apply-core-shirt] Server console: refresh, then restart whip_core and whip_clothingwheel.'
} else {
    Write-Host '[apply-core-shirt] Nothing to do: the shirt glyph is already present.'
}
