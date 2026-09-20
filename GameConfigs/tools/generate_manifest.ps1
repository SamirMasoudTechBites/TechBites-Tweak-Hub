# TechBites Tweak Hub - GameConfigs manifest generator
# - Keeps existing curated preset games, enriches them with SteamGridDB art
# - Adds Mistfall Hunter
# - Appends top 200 Steam games (SteamSpy) as library stubs with cover art
# Usage: powershell -File generate_manifest.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root 'games_manifest.json'
$sgdbKey = 'fe00dd9258ebf362e09acf3ea03742fa'
$sgdbHeaders = @{ Authorization = "Bearer $sgdbKey" }

Write-Host '== Loading existing manifest =='
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$games = @($manifest.games)
Write-Host "Existing games: $($games.Count)"

function Get-SteamGridArt([string]$appId) {
    $cover = $null
    $banner = $null
    try {
        $game = Invoke-RestMethod -Headers $sgdbHeaders -Uri "https://www.steamgriddb.com/api/v2/games/steam/$appId" -TimeoutSec 15
        if ($game.success) {
            $gid = $game.data.id
            Start-Sleep -Milliseconds 300
            try {
                $grids = Invoke-RestMethod -Headers $sgdbHeaders -Uri "https://www.steamgriddb.com/api/v2/grids/game/$gid" -TimeoutSec 15
                if ($grids.success -and $grids.data.Count -gt 0) { $cover = $grids.data[0].url }
            } catch {}
            Start-Sleep -Milliseconds 300
            try {
                $heroes = Invoke-RestMethod -Headers $sgdbHeaders -Uri "https://www.steamgriddb.com/api/v2/heroes/game/$gid" -TimeoutSec 15
                if ($heroes.success -and $heroes.data.Count -gt 0) { $banner = $heroes.data[0].url }
            } catch {}
        }
    } catch {
        Write-Host "  SGDB lookup failed for $appId : $($_.Exception.Message)"
    }
    if (-not $cover)  { $cover  = "https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/header.jpg" }
    if (-not $banner) { $banner = "https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/library_hero.jpg" }
    return [pscustomobject]@{ Cover = $cover; Banner = $banner }
}

# --- 1. Enrich curated games with SteamGridDB art ---
Write-Host '== Fetching SteamGridDB art for curated games =='
foreach ($g in $games) {
    if ([string]::IsNullOrEmpty($g.steamAppId)) { continue }
    Write-Host "  [$($g.id)] appid $($g.steamAppId)..."
    $art = Get-SteamGridArt $g.steamAppId
    if ($g.PSObject.Properties['coverUrl']) { $g.coverUrl = $art.Cover } else { $g | Add-Member -NotePropertyName coverUrl -NotePropertyValue $art.Cover }
    if ($g.PSObject.Properties['bannerUrl']) { $g.bannerUrl = $art.Banner } else { $g | Add-Member -NotePropertyName bannerUrl -NotePropertyValue $art.Banner }
}

# --- 2. Mistfall Hunter (curated, UE5 best-effort config path) ---
Write-Host '== Adding Mistfall Hunter =='
$mistfallArt = Get-SteamGridArt '3282300'
$mistfall = [pscustomobject]@{
    id = 'mistfall_hunter'
    name = 'Mistfall Hunter'
    developer = 'Bellring Games'
    category = 'Extraction ARPG'
    engine = 'Unreal Engine 5'
    iconGlyph = [char]0xE7FC
    bannerGradient = '#2B1D3A,#0F172A'
    coverUrl = $mistfallArt.Cover
    bannerUrl = $mistfallArt.Banner
    configType = 'ini'
    configFileName = 'GameUserSettings.ini'
    genericConfigPaths = @(
        '%LOCALAPPDATA%\Mistfall\Saved\Config\Windows\GameUserSettings.ini',
        '%LOCALAPPDATA%\MistfallHunter\Saved\Config\Windows\GameUserSettings.ini'
    )
    steamAppId = '3282300'
    epicAppName = $null
    riotGameFolder = $null
    preserveKeys = @()
    presets = @(
        [pscustomobject]@{ id='max_fps'; name='Max FPS'; description='All scalability groups to 0 and resolution scale trimmed. Tames UE5 visuals for maximum frames in the mist.'; tier='MaxFPS'; badgeText='MAX FPS'; fileName='max_fps.ini'; downloadUrl=''; size=0; isRecommended=$true },
        [pscustomobject]@{ id='balanced'; name='Balanced'; description='Medium groups with high stable FPS for extraction runs.'; tier='Competitive'; badgeText='BALANCED'; fileName='balanced.ini'; downloadUrl=''; size=0; isRecommended=$false },
        [pscustomobject]@{ id='ultra_quality'; name='High Quality'; description='Epic visuals with GI/reflections tuned for performance.'; tier='UltraQuality'; badgeText='HIGH QUALITY'; fileName='ultra_quality.ini'; downloadUrl=''; size=0; isRecommended=$false }
    )
    tweakableSettings = @(
        [pscustomobject]@{ key='sg.ResolutionQuality'; name='3D Resolution Scale'; description='Internal render resolution percentage.'; category='Display'; type='Slider'; section='ScalabilityGroups'; defaultValue='100'; currentValue=''; minValue=50; maxValue=120; step=5; options=@() },
        [pscustomobject]@{ key='sg.ShadowQuality'; name='Shadows'; description='0=Off 3=Epic'; category='Quality'; type='Select'; section='ScalabilityGroups'; defaultValue='0'; currentValue=''; minValue=0; maxValue=3; step=1; options=@(
            [pscustomobject]@{ label='Off'; value='0'; description=$null },
            [pscustomobject]@{ label='Medium'; value='1'; description=$null },
            [pscustomobject]@{ label='High'; value='2'; description=$null },
            [pscustomobject]@{ label='Epic'; value='3'; description=$null }
        ) },
        [pscustomobject]@{ key='sg.GlobalIlluminationQuality'; name='Global Illumination'; description='Lumen - heavy on FPS'; category='Quality'; type='Select'; section='ScalabilityGroups'; defaultValue='0'; currentValue=''; minValue=0; maxValue=3; step=1; options=@(
            [pscustomobject]@{ label='Off'; value='0'; description=$null },
            [pscustomobject]@{ label='Medium'; value='1'; description=$null },
            [pscustomobject]@{ label='High'; value='2'; description=$null },
            [pscustomobject]@{ label='Epic'; value='3'; description=$null }
        ) }
    )
}
if (-not ($games | Where-Object { $_.id -eq 'mistfall_hunter' })) {
    $games = @($games) + @($mistfall)
}

# --- 3. Top 200 Steam games (SteamSpy, ranked by owners) ---
Write-Host '== Fetching top 200 Steam games from SteamSpy =='
$curatedAppIds = @{}
foreach ($g in $games) { if (-not [string]::IsNullOrEmpty($g.steamAppId)) { $curatedAppIds[[string]$g.steamAppId] = $true } }

$topGames = New-Object System.Collections.ArrayList
$seen = @{}
foreach ($page in 0, 1) {
    $resp = Invoke-RestMethod -Uri "https://steamspy.com/api.php?request=all&page=$page" -TimeoutSec 30
    foreach ($prop in $resp.PSObject.Properties) {
        $g = $prop.Value
        if ($null -eq $g -or [string]::IsNullOrEmpty($g.name)) { continue }
        $appid = [string]$g.appid
        if ([string]::IsNullOrEmpty($appid) -or $seen.ContainsKey($appid)) { continue }
        $seen[$appid] = $true
        [void]$topGames.Add([pscustomobject]@{ AppId=$appid; Name=$g.name; Developer=$g.developer; Genre=$g.genre })
        if ($topGames.Count -ge 220) { break }
    }
    Start-Sleep -Milliseconds 800
}
Write-Host "Fetched $($topGames.Count) candidates"

$categoryMap = @{
    'Action' = 'Action'; 'Adventure' = 'Adventure'; 'RPG' = 'RPG'; 'Strategy' = 'Strategy'
    'Simulation' = 'Simulation'; 'Sports' = 'Sports'; 'Racing' = 'Racing'; 'Free to Play' = 'Free to Play'
    'Early Access' = 'Early Access'; 'Massively Multiplayer' = 'MMO'
}

$stubGames = New-Object System.Collections.ArrayList
foreach ($t in $topGames) {
    if ($curatedAppIds.ContainsKey($t.AppId)) { continue }
    if ($stubGames.Count -ge 200) { break }
    $category = 'Steam Game'
    if (-not [string]::IsNullOrEmpty($t.Genre)) {
        $first = ($t.Genre -split ',')[0].Trim()
        if ($categoryMap.ContainsKey($first)) { $category = $categoryMap[$first] } else { $category = $first }
    }
    $dev = if ([string]::IsNullOrEmpty($t.Developer)) { 'Unknown' } else { ($t.Developer -split ',')[0].Trim() }
    [void]$stubGames.Add([pscustomobject]@{
        id = "steam_$($t.AppId)"
        name = $t.Name
        developer = $dev
        category = $category
        engine = 'PC'
        iconGlyph = [char]0xE7FC
        bannerGradient = '#1E293B,#0F172A'
        coverUrl = "https://cdn.cloudflare.steamstatic.com/steam/apps/$($t.AppId)/header.jpg"
        bannerUrl = "https://cdn.cloudflare.steamstatic.com/steam/apps/$($t.AppId)/library_hero.jpg"
        configType = 'ini'
        configFileName = ''
        genericConfigPaths = @()
        steamAppId = $t.AppId
        epicAppName = $null
        riotGameFolder = $null
        preserveKeys = @()
        presets = @()
        tweakableSettings = @()
    })
}
Write-Host "Stub entries: $($stubGames.Count)"

# --- 4. Write merged manifest ---
$allGames = @($games) + $stubGames
$out = [pscustomobject]@{
    version = '2.1'
    lastUpdated = (Get-Date -Format 'yyyy-MM-dd')
    games = $allGames
}
$json = $out | ConvertTo-Json -Depth 12
# PS 5.1 writes UTF16 by default - force UTF8 no BOM
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "== Manifest written: $($allGames.Count) games =="
