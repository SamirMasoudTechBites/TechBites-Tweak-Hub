# TechBites Tweak Hub - Launch options + hand-curated batch generator
# 1. Classifies remaining stubs by engine via PCGamingWiki (stored in manifest)
# 2. Adds engine-aware launchOptionPresets to EVERY game with a Steam AppID
# 3. Upgrades 10 hand-curated stubs (TF2, GMod, L4D2, HL2, Factorio, PoE,
#    Warframe, Skyrim SE, Fallout 4, Fallout NV) with real config paths/presets
# Usage: powershell -File generate_launch_options.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root 'games_manifest.json'
$ua = @{ 'User-Agent' = 'TechBitesTweakHub/2.3 (config generator)' }

Write-Host '== Loading manifest =='
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$games = @($manifest.games)

function Get-Engine([string]$name) {
    $title = [uri]::EscapeDataString($name)
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            $r = Invoke-RestMethod -Headers $ua -Uri "https://www.pcgamingwiki.com/w/api.php?action=parse&page=$title&prop=wikitext&format=json&redirects=1" -TimeoutSec 20
            $t = if ($r.parse.wikitext -is [string]) { $r.parse.wikitext } else { [string]$r.parse.wikitext.'*' }
            if ($t -match '\{\{Infobox game/row/engine\|([^|}]+)') { return $Matches[1].Trim() }
            return $null
        } catch {
            if ($_.Exception.Message -like '*429*' -or $_.Exception.Message -like '*503*') { Start-Sleep -Seconds 5 } else { return $null }
        }
    }
    return $null
}

function Set-EngineProp($obj, [string]$value) {
    if ($obj.PSObject.Properties['engine']) { $obj.engine = $value } else { $obj | Add-Member -NotePropertyName engine -NotePropertyValue $value }
}

function Set-LaunchPresets($obj, [string]$engine) {
    $presets = New-Object System.Collections.ArrayList
    $clear = [pscustomobject]@{ id='lo_clear'; name='Reset / Clear'; description='Removes all Steam launch options for this game (back to vanilla).'; badgeText='RESET'; options=''; isRecommended=$false }
    if ($engine -match 'Source|GoldSrc') {
        [void]$presets.Add([pscustomobject]@{ id='lo_max_fps'; name='Max FPS'; description='Skips intro video, disables joystick polling, high CPU priority, uncapped FPS. Native Source engine flags.'; badgeText='MAX FPS'; options='-novid -nojoy -high +fps_max 0'; isRecommended=$true })
        [void]$presets.Add([pscustomobject]@{ id='lo_balanced'; name='Balanced'; description='Skips intro video with high CPU priority.'; badgeText='BALANCED'; options='-novid -high'; isRecommended=$false })
    } elseif ($engine -match 'Unity') {
        [void]$presets.Add([pscustomobject]@{ id='lo_max_fps'; name='Max FPS'; description='Forces exclusive fullscreen and the DX11 renderer for stable frame pacing. Native Unity flags.'; badgeText='MAX FPS'; options='-screen-fullscreen 1 -force-d3d11'; isRecommended=$true })
        [void]$presets.Add([pscustomobject]@{ id='lo_balanced'; name='Balanced'; description='Forces exclusive fullscreen.'; badgeText='BALANCED'; options='-screen-fullscreen 1'; isRecommended=$false })
    } else {
        [void]$presets.Add([pscustomobject]@{ id='lo_max_fps'; name='Competitive Base'; description='Generic flags: skip intro video, high CPU priority. Engines that don''t support them ignore them silently.'; badgeText='MAX FPS'; options='-novid -high'; isRecommended=$true })
    }
    [void]$presets.Add($clear)
    if ($obj.PSObject.Properties['launchOptionPresets']) { $obj.launchOptionPresets = @($presets) } else { $obj | Add-Member -NotePropertyName launchOptionPresets -NotePropertyValue @($presets) }
}

function Set-StringProp($obj, [string]$name, [string]$value) {
    if ($obj.PSObject.Properties[$name]) { $obj.$name = $value } else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
}

function New-FilePreset([string]$id, [string]$name, [string]$desc, [string]$tier, [string]$badge, [string]$file, [bool]$rec) {
    [pscustomobject]@{ id=$id; name=$name; description=$desc; tier=$tier; badgeText=$badge; fileName=$file; downloadUrl=''; size=0; isRecommended=$rec }
}

# --- 1. Classify stubs still marked as 'PC' and store engine ---
Write-Host '== Classifying engines via PCGamingWiki =='
foreach ($g in @($games | Where-Object { $_.id -like 'steam_*' -and $_.engine -eq 'PC' })) {
    $e = Get-Engine $g.name
    Start-Sleep -Milliseconds 350
    if (-not [string]::IsNullOrEmpty($e)) { Set-EngineProp $g $e }
}

# --- 2. Launch option presets for every Steam game ---
Write-Host '== Adding launch option presets =='
$loCount = 0
foreach ($g in $games) {
    if ([string]::IsNullOrEmpty($g.steamAppId)) { continue }
    Set-LaunchPresets $g ([string]$g.engine)
    $loCount++
}
Write-Host "Launch presets added to $loCount games"

# --- 3. Hand-curated upgrades ---
Write-Host '== Upgrading hand-curated games =='

function Upgrade-Game([string]$appId, [string]$name, [string]$dev, [string]$cat, [string]$engine, [string]$configType, [string]$configFileName, [string[]]$paths, $presets, $tweaks) {
    $g = $games | Where-Object { ([string]$_.steamAppId) -eq $appId } | Select-Object -First 1
    if ($null -eq $g) { Write-Host "  SKIP (no stub): $name"; return }
    Set-StringProp $g 'name' $name
    Set-StringProp $g 'developer' $dev
    Set-StringProp $g 'category' $cat
    Set-EngineProp $g $engine
    Set-StringProp $g 'configType' $configType
    Set-StringProp $g 'configFileName' $configFileName
    if ($g.PSObject.Properties['genericConfigPaths']) { $g.genericConfigPaths = @($paths) } else { $g | Add-Member -NotePropertyName genericConfigPaths -NotePropertyValue @($paths) }
    if ($g.PSObject.Properties['presets']) { $g.presets = @($presets) } else { $g | Add-Member -NotePropertyName presets -NotePropertyValue @($presets) }
    if ($g.PSObject.Properties['tweakableSettings']) { $g.tweakableSettings = @($tweaks) } else { $g | Add-Member -NotePropertyName tweakableSettings -NotePropertyValue @($tweaks) }
    Write-Host "  OK: $name ($($g.id))"
}

$srcTweaks = @(
    [pscustomobject]@{ key='setting.defaultres'; name='Resolution Width'; description=''; category='Display'; type='Slider'; section='VideoConfig'; defaultValue='1920'; currentValue=''; minValue=1280; maxValue=3840; step=10; options=@() },
    [pscustomobject]@{ key='setting.mat_vsync'; name='VSync'; description='Adds input lag'; category='Esports'; type='Toggle'; section='VideoConfig'; defaultValue='0'; currentValue=''; minValue=0; maxValue=1; step=1; options=@([pscustomobject]@{ label='Off'; value='0'; description=$null },[pscustomobject]@{ label='On'; value='1'; description=$null }) }
)
$srcPresets = @(
    (New-FilePreset 'max_fps' 'Max FPS' 'No AA, no aniso, VSync off, motion blur off. Lowest-latency Source video config.' 'MaxFPS' 'MAX FPS' 'max_fps.txt' $true),
    (New-FilePreset 'balanced' 'Balanced' '2x MSAA and 4x anisotropic for clean visuals with high FPS.' 'Competitive' 'BALANCED' 'balanced.txt' $false),
    (New-FilePreset 'ultra_quality' 'High Quality' '8x MSAA and 16x anisotropic filtering at higher resolution.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.txt' $false)
)

Upgrade-Game '440' 'Team Fortress 2' 'Valve' 'Hero Shooter' 'Source' 'txt' 'video.txt' @() $srcPresets $srcTweaks
Upgrade-Game '4000' "Garry's Mod" 'Facepunch' 'Sandbox' 'Source' 'txt' 'video.txt' @() $srcPresets $srcTweaks
Upgrade-Game '550' 'Left 4 Dead 2' 'Valve' 'Co-op Shooter' 'Source' 'txt' 'video.txt' @() $srcPresets $srcTweaks
Upgrade-Game '220' 'Half-Life 2' 'Valve' 'FPS Classic' 'Source' 'txt' 'video.txt' @() $srcPresets $srcTweaks

Upgrade-Game '427520' 'Factorio' 'Wube Software' 'Simulation' 'Custom (Wube)' 'ini' 'config.ini' @('%APPDATA%\Factorio\config\config.ini') @(
    (New-FilePreset 'max_fps' 'Max FPS' 'VSync off, FPS counter on, fullscreen locked. Uncapped game speed rendering.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true),
    (New-FilePreset 'balanced' 'Balanced' 'VSync off with clean HUD.' 'Competitive' 'BALANCED' 'balanced.ini' $false),
    (New-FilePreset 'ultra_quality' 'High Quality' 'Same FPS-first base with fullscreen.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false)
) @(
    [pscustomobject]@{ key='v-sync'; name='VSync'; description='Adds input lag'; category='Esports'; type='Toggle'; section='graphics'; defaultValue='false'; currentValue=''; minValue=0; maxValue=1; step=1; options=@([pscustomobject]@{ label='Off'; value='false'; description=$null },[pscustomobject]@{ label='On'; value='true'; description=$null }) }
)

Upgrade-Game '238960' 'Path of Exile' 'Grinding Gear Games' 'Action RPG' 'Custom (GGG)' 'ini' 'production_Config.ini' @('%USERPROFILE%\Documents\My Games\Path of Exile\production_Config.ini') @(
    (New-FilePreset 'max_fps' 'Max FPS' 'Fullscreen, VSync off for lowest latency in maps and deep delves.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true),
    (New-FilePreset 'balanced' 'Balanced' 'Fullscreen, VSync off.' 'Competitive' 'BALANCED' 'balanced.ini' $false),
    (New-FilePreset 'ultra_quality' 'High Quality' 'Fullscreen, VSync off.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false)
) @()

Upgrade-Game '230410' 'Warframe' 'Digital Extremes' 'Looter Shooter' 'Evolution Engine' 'ini' 'EE.cfg' @('%LOCALAPPDATA%\Warframe\EE.cfg') @(
    (New-FilePreset 'max_fps' 'Max FPS' 'Fullscreen, VSync off in the Evolution Engine config.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true),
    (New-FilePreset 'balanced' 'Balanced' 'Fullscreen, VSync off.' 'Competitive' 'BALANCED' 'balanced.ini' $false),
    (New-FilePreset 'ultra_quality' 'High Quality' 'Fullscreen, VSync off.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false)
) @()

$bethTweaks = @(
    [pscustomobject]@{ key='iVSyncPresentInterval'; name='VSync'; description='0 = off (lower latency, possible tearing)'; category='Esports'; type='Toggle'; section='Display'; defaultValue='0'; currentValue=''; minValue=0; maxValue=1; step=1; options=@([pscustomobject]@{ label='Off'; value='0'; description=$null },[pscustomobject]@{ label='On'; value='1'; description=$null }) }
)
$bethPresets = @(
    (New-FilePreset 'max_fps' 'Max FPS' 'Fullscreen forced, VSync off - removes the 60fps input lag cap Bethesda games ship with.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true),
    (New-FilePreset 'balanced' 'Balanced' 'Fullscreen forced, VSync off at 1080p.' 'Competitive' 'BALANCED' 'balanced.ini' $false),
    (New-FilePreset 'ultra_quality' 'High Quality' 'Fullscreen forced, VSync off at 1440p.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false)
)

Upgrade-Game '489830' 'Skyrim Special Edition' 'Bethesda' 'Open World RPG' 'Creation Engine' 'ini' 'SkyrimPrefs.ini' @('%USERPROFILE%\Documents\My Games\Skyrim Special Edition\SkyrimPrefs.ini') $bethPresets $bethTweaks
Upgrade-Game '377160' 'Fallout 4' 'Bethesda' 'Open World RPG' 'Creation Engine' 'ini' 'Fallout4Prefs.ini' @('%USERPROFILE%\Documents\My Games\Fallout4\Fallout4Prefs.ini') $bethPresets $bethTweaks
Upgrade-Game '22380' 'Fallout: New Vegas' 'Obsidian' 'Open World RPG' 'Gamebryo' 'ini' 'FalloutPrefs.ini' @('%USERPROFILE%\Documents\My Games\FalloutNV\FalloutPrefs.ini') $bethPresets $bethTweaks

# --- 4. Save ---
$out = [pscustomobject]@{
    version = '2.3'
    lastUpdated = (Get-Date -Format 'yyyy-MM-dd')
    games = $games
}
$json = $out | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))
$withPresets = (@($games | Where-Object { $_.presets.Count -gt 0 })).Count
$withLo = (@($games | Where-Object { $_.launchOptionPresets.Count -gt 0 })).Count
Write-Host "== Saved v2.3: $($games.Count) games | $withPresets with file presets | $withLo with launch option presets =="
