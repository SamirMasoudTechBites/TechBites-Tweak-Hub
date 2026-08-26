# TechBites Tweak Hub - Engine-based preset generator
# Classifies top-200 Steam stub games by engine via PCGamingWiki wikitext,
# then generates real Max FPS / Balanced / High Quality presets for every
# Unreal Engine 4/5 game (shared GameUserSettings.ini format).
# Usage: powershell -File generate_engine_presets.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root 'games_manifest.json'
$ua = @{ 'User-Agent' = 'TechBitesTweakHub/2.1 (config generator)' }

Write-Host '== Loading manifest =='
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$games = @($manifest.games)
$stubs = @($games | Where-Object { $_.id -like 'steam_*' -and $_.presets.Count -eq 0 })
Write-Host "Stub games to classify: $($stubs.Count)"

function Get-Engine([string]$name) {
    $title = [uri]::EscapeDataString($name)
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            $r = Invoke-RestMethod -Headers $ua -Uri "https://www.pcgamingwiki.com/w/api.php?action=parse&page=$title&prop=wikitext&format=json&redirects=1" -TimeoutSec 20
            $t = if ($r.parse.wikitext -is [string]) { $r.parse.wikitext } else { [string]$r.parse.wikitext.'*' }
            if ($t -match '\{\{Infobox game/row/engine\|([^|}]+)') {
                return $Matches[1].Trim()
            }
            return $null
        } catch {
            if ($_.Exception.Message -like '*429*' -or $_.Exception.Message -like '*503*') {
                Start-Sleep -Seconds 5
            } else {
                return $null
            }
        }
    }
    return $null
}

function Get-ProjectVariants([string]$name) {
    $variants = New-Object System.Collections.ArrayList
    function Add-V([System.Collections.ArrayList]$list, [string]$v) {
        if (-not [string]::IsNullOrWhiteSpace($v) -and -not $list.Contains($v)) { [void]$list.Add($v) }
    }
    $alnum = ($name -replace '[^A-Za-z0-9]', '')
    Add-V $variants $alnum
    $words = ($name -replace '[^A-Za-z0-9 ]', ' ') -split '\s+' | Where-Object { $_ }
    if ($words.Count -ge 1) { Add-V $variants $words[0] }
    if ($words.Count -ge 2) { Add-V $variants ($words[0] + $words[1]) }
    $colon = ($name -split ':')[0] -replace '[^A-Za-z0-9]', ''
    Add-V $variants $colon
    return $variants
}

function New-PresetObject([string]$id, [string]$name, [string]$desc, [string]$tier, [string]$badge, [string]$file, [bool]$rec) {
    [pscustomobject]@{ id=$id; name=$name; description=$desc; tier=$tier; badgeText=$badge; fileName=$file; downloadUrl=''; size=0; isRecommended=$rec }
}

$uePresetFiles = @{
    'max_fps' = @"
[/Script/Engine.GameUserSettings]
bUseVSync=False
bUseDynamicResolution=False

[ScalabilityGroups]
sg.ResolutionQuality=90.000000
sg.ViewDistanceQuality=0
sg.AntiAliasingQuality=0
sg.ShadowQuality=0
sg.PostProcessQuality=0
sg.TextureQuality=0
sg.EffectsQuality=0
sg.FoliageQuality=0
sg.ShadingQuality=0
sg.GlobalIlluminationQuality=0
sg.ReflectionQuality=0
sg.TranslucencyQuality=0
"@
    'balanced' = @"
[/Script/Engine.GameUserSettings]
bUseVSync=False
bUseDynamicResolution=False

[ScalabilityGroups]
sg.ResolutionQuality=100.000000
sg.ViewDistanceQuality=2
sg.AntiAliasingQuality=1
sg.ShadowQuality=1
sg.PostProcessQuality=1
sg.TextureQuality=2
sg.EffectsQuality=1
sg.FoliageQuality=1
sg.ShadingQuality=1
sg.GlobalIlluminationQuality=1
sg.ReflectionQuality=1
sg.TranslucencyQuality=1
"@
    'ultra_quality' = @"
[/Script/Engine.GameUserSettings]
bUseVSync=False
bUseDynamicResolution=False

[ScalabilityGroups]
sg.ResolutionQuality=100.000000
sg.ViewDistanceQuality=3
sg.AntiAliasingQuality=2
sg.ShadowQuality=3
sg.PostProcessQuality=2
sg.TextureQuality=3
sg.EffectsQuality=3
sg.FoliageQuality=2
sg.ShadingQuality=3
sg.GlobalIlluminationQuality=2
sg.ReflectionQuality=2
sg.TranslucencyQuality=2
"@
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$ueCount = 0
$otherEngines = @{}

foreach ($g in $stubs) {
    $appid = [string]$g.steamAppId
    $engine = Get-Engine $g.name
    Start-Sleep -Milliseconds 350

    if ([string]::IsNullOrEmpty($engine)) { continue }
    $engineKey = ($engine -replace '\s*\d+(\.\d+)*$', '').Trim()
    if (-not $otherEngines.ContainsKey($engineKey)) { $otherEngines[$engineKey] = 0 }
    $otherEngines[$engineKey]++

    if ($engine -notmatch 'Unreal Engine') { continue }
    if ($engine -match 'Unreal Engine [123]') { continue }

    Write-Host "  [UE] $($g.name) -> $engine"
    $isUE5 = $engine -match 'Unreal Engine 5'
    $subFolders = if ($isUE5) { @('Windows', 'WindowsNoEditor') } else { @('WindowsNoEditor', 'Windows') }

    $paths = New-Object System.Collections.ArrayList
    foreach ($v in (Get-ProjectVariants $g.name)) {
        foreach ($sf in $subFolders) {
            [void]$paths.Add("%LOCALAPPDATA%\$v\Saved\Config\$sf\GameUserSettings.ini")
        }
    }

    $g.configType = 'ini'
    $g.configFileName = 'GameUserSettings.ini'
    $g.genericConfigPaths = @($paths)

    $dir = Join-Path $root $g.id
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    foreach ($key in $uePresetFiles.Keys) {
        [System.IO.File]::WriteAllText((Join-Path $dir "$key.ini"), ($uePresetFiles[$key] + "`r`n"), $utf8)
    }

    $g.presets = @(
        (New-PresetObject 'max_fps' 'Max FPS' "All scalability groups to 0 and render scale trimmed. Engine-verified Unreal preset for maximum FPS." 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true),
        (New-PresetObject 'balanced' 'Balanced' "Medium groups with high stable FPS. Good visuals without killing frame rates." 'Competitive' 'BALANCED' 'balanced.ini' $false),
        (New-PresetObject 'ultra_quality' 'High Quality' "Epic groups with GI/reflections tuned for performance. Best-looking while still FPS-smart." 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false)
    )

    $opt3 = @(
        [pscustomobject]@{ label='Off'; value='0'; description=$null },
        [pscustomobject]@{ label='Medium'; value='1'; description=$null },
        [pscustomobject]@{ label='High'; value='2'; description=$null },
        [pscustomobject]@{ label='Epic'; value='3'; description=$null }
    )
    $g.tweakableSettings = @(
        [pscustomobject]@{ key='sg.ResolutionQuality'; name='3D Resolution Scale'; description='Internal render resolution percentage. Biggest FPS lever.'; category='Display'; type='Slider'; section='ScalabilityGroups'; defaultValue='100'; currentValue=''; minValue=50; maxValue=120; step=5; options=@() },
        [pscustomobject]@{ key='sg.ViewDistanceQuality'; name='View Distance'; description='0=Low 3=Epic'; category='Quality'; type='Select'; section='ScalabilityGroups'; defaultValue='0'; currentValue=''; minValue=0; maxValue=3; step=1; options=$opt3 },
        [pscustomobject]@{ key='sg.ShadowQuality'; name='Shadows'; description='0=Off 3=Epic'; category='Quality'; type='Select'; section='ScalabilityGroups'; defaultValue='0'; currentValue=''; minValue=0; maxValue=3; step=1; options=$opt3 },
        [pscustomobject]@{ key='sg.TextureQuality'; name='Textures'; description='VRAM usage'; category='Quality'; type='Select'; section='ScalabilityGroups'; defaultValue='0'; currentValue=''; minValue=0; maxValue=3; step=1; options=$opt3 },
        [pscustomobject]@{ key='sg.GlobalIlluminationQuality'; name='Global Illumination'; description='Lumen - heavy on FPS'; category='Quality'; type='Select'; section='ScalabilityGroups'; defaultValue='0'; currentValue=''; minValue=0; maxValue=3; step=1; options=$opt3 }
    )

    $ueCount++
}

Write-Host "== UE games with presets generated: $ueCount =="
Write-Host 'Engine distribution:'
$otherEngines.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object { "  $($_.Key): $($_.Value)" }

$out = [pscustomobject]@{
    version = '2.2'
    lastUpdated = (Get-Date -Format 'yyyy-MM-dd')
    games = $games
}
$json = $out | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($manifestPath, $json, $utf8)
Write-Host "== Manifest saved: $($games.Count) games =="
