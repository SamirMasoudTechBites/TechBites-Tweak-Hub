# TechBites Tweak Hub - Universal Missing Game Configs Generator
$ErrorActionPreference = 'Stop'
$root = "C:\Users\Samir Masoud\Documents\GitHub\TechBites-Tweak-Hub\GameConfigs"
$manifestPath = Join-Path $root 'games_manifest.json'
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "== Loading games manifest from $manifestPath =="
$manifest = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$games = @($manifest.games)

# 1. Clean up corrupted game titles
foreach ($g in $games) {
    if ($g.id -eq 'steam_242050') { $g.name = "Assassin's Creed IV Black Flag" }
    elseif ($g.id -eq 'steam_289070') { $g.name = "Sid Meier's Civilization VI" }
    elseif ($g.id -eq 'steam_365590') { $g.name = "Tom Clancy's The Division" }
    elseif ($g.id -eq 'steam_8930')   { $g.name = "Sid Meier's Civilization V" }
    elseif ($g.id -eq 'steam_72850')  { $g.name = "The Elder Scrolls V: Skyrim" }
    elseif ($g.id -eq 'steam_306130') { $g.name = "The Elder Scrolls Online" }
    else {
        if ($g.name -match "Civilization VI") { $g.name = "Sid Meier's Civilization VI" }
        elseif ($g.name -match "Civilization V") { $g.name = "Sid Meier's Civilization V" }
        elseif ($g.name -match "The Division") { $g.name = "Tom Clancy's The Division" }
        elseif ($g.name -match "Creed IV") { $g.name = "Assassin's Creed IV Black Flag" }
    }
}

function New-PresetObject([string]$id, [string]$name, [string]$desc, [string]$tier, [string]$badge, [string]$file, [bool]$rec) {
    [pscustomobject]@{
        id = $id
        name = $name
        description = $desc
        tier = $tier
        badgeText = $badge
        fileName = $file
        downloadUrl = ""
        size = 0
        isRecommended = $rec
    }
}

function New-TweakOption([string]$label, [string]$val, [string]$desc = $null) {
    [pscustomobject]@{ label = $label; value = $val; description = $desc }
}

function New-TweakSetting([string]$key, [string]$name, [string]$desc, [string]$cat, [string]$type, [string]$sec, [string]$def, [double]$min=0, [double]$max=100, [double]$step=1, $options=@()) {
    [pscustomobject]@{
        key = $key
        name = $name
        description = $desc
        category = $cat
        type = $type
        section = $sec
        defaultValue = $def
        currentValue = ""
        minValue = $min
        maxValue = $max
        step = $step
        options = @($options)
    }
}

function New-LaunchPreset([string]$id, [string]$name, [string]$desc, [string]$badge, [string]$options, [bool]$rec) {
    [pscustomobject]@{
        id = $id
        name = $name
        description = $desc
        badgeText = $badge
        options = $options
        isRecommended = $rec
    }
}

# --- TEMPLATES DEFINITION ---

# 1. Unreal Engine 4 / 5 (GameUserSettings.ini)
$uePresets = @{
    'max_fps.ini' = "[/Script/Engine.GameUserSettings]`r`nbUseVSync=False`r`nbUseDynamicResolution=False`r`nFrameRateLimit=0.000000`r`n`r`n[ScalabilityGroups]`r`nsg.ResolutionQuality=90.000000`r`nsg.ViewDistanceQuality=0`r`nsg.AntiAliasingQuality=0`r`nsg.ShadowQuality=0`r`nsg.PostProcessQuality=0`r`nsg.TextureQuality=0`r`nsg.EffectsQuality=0`r`nsg.FoliageQuality=0`r`nsg.ShadingQuality=0`r`nsg.GlobalIlluminationQuality=0`r`nsg.ReflectionQuality=0`r`nsg.TranslucencyQuality=0`r`n"
    'balanced.ini' = "[/Script/Engine.GameUserSettings]`r`nbUseVSync=False`r`nbUseDynamicResolution=False`r`nFrameRateLimit=0.000000`r`n`r`n[ScalabilityGroups]`r`nsg.ResolutionQuality=100.000000`r`nsg.ViewDistanceQuality=2`r`nsg.AntiAliasingQuality=1`r`nsg.ShadowQuality=1`r`nsg.PostProcessQuality=1`r`nsg.TextureQuality=2`r`nsg.EffectsQuality=1`r`nsg.FoliageQuality=1`r`nsg.ShadingQuality=1`r`nsg.GlobalIlluminationQuality=1`r`nsg.ReflectionQuality=1`r`nsg.TranslucencyQuality=1`r`n"
    'ultra_quality.ini' = "[/Script/Engine.GameUserSettings]`r`nbUseVSync=False`r`nbUseDynamicResolution=False`r`nFrameRateLimit=0.000000`r`n`r`n[ScalabilityGroups]`r`nsg.ResolutionQuality=100.000000`r`nsg.ViewDistanceQuality=3`r`nsg.AntiAliasingQuality=2`r`nsg.ShadowQuality=3`r`nsg.PostProcessQuality=2`r`nsg.TextureQuality=3`r`nsg.EffectsQuality=3`r`nsg.FoliageQuality=2`r`nsg.ShadingQuality=3`r`nsg.GlobalIlluminationQuality=2`r`nsg.ReflectionQuality=2`r`nsg.TranslucencyQuality=2`r`n"
}

# 2. Unreal Engine 3 (Engine.ini / SystemSettings.ini)
$ue3Presets = @{
    'max_fps.ini' = "[SystemSettings]`r`nbUseVSync=False`r`nbSmoothFrameRate=False`r`nMinSmoothedFrameRate=0`r`nMaxSmoothedFrameRate=0`r`nDynamicLights=False`r`nDynamicShadows=False`r`nLightEnvironmentShadows=False`r`nCompositeDynamicLights=False`r`nDirectionalLightmaps=False`r`nMotionBlur=False`r`nDepthOfField=False`r`nAmbientOcclusion=False`r`nBloom=False`r`nUseHighQualityBloom=False`r`nDistortion=False`r`nFilteredDistortion=False`r`nDropParticleDistortion=False`r`nSpeedTreeLeaves=False`r`nSpeedTreeFronds=False`r`nOnlyStreamInTextures=False`r`nLensFlares=False`r`nFogVolumes=False`r`nFloatingPointRenderTargets=False`r`nTEXTUREGROUP_World=(MinLODSize=1,MaxLODSize=256,LODBias=1)`r`nTEXTUREGROUP_WorldNormalMap=(MinLODSize=1,MaxLODSize=256,LODBias=1)`r`nTEXTUREGROUP_Character=(MinLODSize=1,MaxLODSize=512,LODBias=1)`r`n"
    'balanced.ini' = "[SystemSettings]`r`nbUseVSync=False`r`nbSmoothFrameRate=False`r`nMinSmoothedFrameRate=0`r`nMaxSmoothedFrameRate=0`r`nDynamicLights=True`r`nDynamicShadows=True`r`nLightEnvironmentShadows=True`r`nCompositeDynamicLights=True`r`nDirectionalLightmaps=True`r`nMotionBlur=False`r`nDepthOfField=False`r`nAmbientOcclusion=False`r`nBloom=True`r`nUseHighQualityBloom=False`r`nDistortion=True`r`nSpeedTreeLeaves=True`r`nSpeedTreeFronds=True`r`nLensFlares=True`r`nFogVolumes=True`r`nTEXTUREGROUP_World=(MinLODSize=1,MaxLODSize=1024,LODBias=0)`r`nTEXTUREGROUP_WorldNormalMap=(MinLODSize=1,MaxLODSize=1024,LODBias=0)`r`nTEXTUREGROUP_Character=(MinLODSize=1,MaxLODSize=1024,LODBias=0)`r`n"
    'ultra_quality.ini' = "[SystemSettings]`r`nbUseVSync=False`r`nbSmoothFrameRate=False`r`nMinSmoothedFrameRate=0`r`nMaxSmoothedFrameRate=0`r`nDynamicLights=True`r`nDynamicShadows=True`r`nLightEnvironmentShadows=True`r`nCompositeDynamicLights=True`r`nDirectionalLightmaps=True`r`nMotionBlur=False`r`nDepthOfField=True`r`nAmbientOcclusion=True`r`nBloom=True`r`nUseHighQualityBloom=True`r`nDistortion=True`r`nSpeedTreeLeaves=True`r`nSpeedTreeFronds=True`r`nLensFlares=True`r`nFogVolumes=True`r`nTEXTUREGROUP_World=(MinLODSize=1,MaxLODSize=4096,LODBias=0)`r`nTEXTUREGROUP_WorldNormalMap=(MinLODSize=1,MaxLODSize=4096,LODBias=0)`r`nTEXTUREGROUP_Character=(MinLODSize=1,MaxLODSize=4096,LODBias=0)`r`n"
}

# 3. Source Engine (video.txt)
$sourcePresets = @{
    'max_fps.txt' = "`"VideoConfig`"`r`n{`r`n`t`"setting.cpu_level`"`t`t`"0`"`r`n`t`"setting.gpu_level`"`t`t`"0`"`r`n`t`"setting.mat_antialias`"`t`t`"0`"`r`n`t`"setting.mat_aaquality`"`t`t`"0`"`r`n`t`"setting.mat_forceaniso`"`t`t`"0`"`r`n`t`"setting.mat_vsync`"`t`t`"0`"`r`n`t`"setting.mat_triplebuffered`"`t`t`"0`"`r`n`t`"setting.mat_grain_scale_override`"`t`t`"1`"`r`n`t`"setting.gpu_mem_level`"`t`t`"0`"`r`n`t`"setting.mem_level`"`t`t`"0`"`r`n`t`"setting.mat_queue_mode`"`t`t`"2`"`r`n`t`"setting.csm_quality_level`"`t`t`"0`"`r`n`t`"setting.mat_motion_blur_enabled`"`t`t`"0`"`r`n`t`"setting.fullscreen`"`t`t`"1`"`r`n`t`"setting.nowindowborder`"`t`t`"0`"`r`n`t`"setting.aspectratiomode`"`t`t`"1`"`r`n`t`"setting.shadow_depth_texture`"`t`t`"0`"`r`n}`r`n"
    'balanced.txt' = "`"VideoConfig`"`r`n{`r`n`t`"setting.cpu_level`"`t`t`"1`"`r`n`t`"setting.gpu_level`"`t`t`"1`"`r`n`t`"setting.mat_antialias`"`t`t`"2`"`r`n`t`"setting.mat_aaquality`"`t`t`"0`"`r`n`t`"setting.mat_forceaniso`"`t`t`"4`"`r`n`t`"setting.mat_vsync`"`t`t`"0`"`r`n`t`"setting.mat_triplebuffered`"`t`t`"0`"`r`n`t`"setting.mat_grain_scale_override`"`t`t`"1`"`r`n`t`"setting.gpu_mem_level`"`t`t`"1`"`r`n`t`"setting.mem_level`"`t`t`"2`"`r`n`t`"setting.mat_queue_mode`"`t`t`"2`"`r`n`t`"setting.csm_quality_level`"`t`t`"1`"`r`n`t`"setting.mat_motion_blur_enabled`"`t`t`"0`"`r`n`t`"setting.fullscreen`"`t`t`"1`"`r`n`t`"setting.nowindowborder`"`t`t`"0`"`r`n`t`"setting.aspectratiomode`"`t`t`"1`"`r`n`t`"setting.shadow_depth_texture`"`t`t`"1`"`r`n}`r`n"
    'ultra_quality.txt' = "`"VideoConfig`"`r`n{`r`n`t`"setting.cpu_level`"`t`t`"2`"`r`n`t`"setting.gpu_level`"`t`t`"3`"`r`n`t`"setting.mat_antialias`"`t`t`"8`"`r`n`t`"setting.mat_aaquality`"`t`t`"0`"`r`n`t`"setting.mat_forceaniso`"`t`t`"16`"`r`n`t`"setting.mat_vsync`"`t`t`"0`"`r`n`t`"setting.mat_triplebuffered`"`t`t`"0`"`r`n`t`"setting.mat_grain_scale_override`"`t`t`"1`"`r`n`t`"setting.gpu_mem_level`"`t`t`"2`"`r`n`t`"setting.mem_level`"`t`t`"2`"`r`n`t`"setting.mat_queue_mode`"`t`t`"2`"`r`n`t`"setting.csm_quality_level`"`t`t`"3`"`r`n`t`"setting.mat_motion_blur_enabled`"`t`t`"0`"`r`n`t`"setting.fullscreen`"`t`t`"1`"`r`n`t`"setting.nowindowborder`"`t`t`"0`"`r`n`t`"setting.aspectratiomode`"`t`t`"1`"`r`n`t`"setting.shadow_depth_texture`"`t`t`"1`"`r`n}`r`n"
}

# 4. GoldSrc Engine (autoexec.cfg)
$goldSrcPresets = @{
    'max_fps.cfg' = "// TechBites Tweak Hub - GoldSrc Max FPS Configuration`r`nfps_max `"144.0`"`r`nfps_override `"1`"`r`ngl_vsync `"0`"`r`ngl_ansio `"0`"`r`nr_shadows `"0`"`r`nr_dynamic `"0`"`r`nr_novis `"0`"`r`nr_wateralpha `"0`"`r`ncl_updaterate `"101`"`r`ncl_cmdrate `"101`"`r`nrate `"100000`"`r`ncl_crosshair_color `"0 255 0`"`r`nhud_fastswitch `"1`"`r`nm_rawinput `"1`"`r`nm_customaccel `"0`"`r`n"
    'balanced.cfg' = "// TechBites Tweak Hub - GoldSrc Balanced Configuration`r`nfps_max `"144.0`"`r`nfps_override `"1`"`r`ngl_vsync `"0`"`r`ngl_ansio `"4`"`r`nr_shadows `"1`"`r`nr_dynamic `"1`"`r`ncl_updaterate `"101`"`r`ncl_cmdrate `"101`"`r`nrate `"100000`"`r`nhud_fastswitch `"1`"`r`nm_rawinput `"1`"`r`n"
    'ultra_quality.cfg' = "// TechBites Tweak Hub - GoldSrc High Quality Configuration`r`nfps_max `"240.0`"`r`nfps_override `"1`"`r`ngl_vsync `"0`"`r`ngl_ansio `"16`"`r`nr_shadows `"1`"`r`nr_dynamic `"1`"`r`ncl_updaterate `"101`"`r`ncl_cmdrate `"101`"`r`nrate `"100000`"`r`nhud_fastswitch `"1`"`r`nm_rawinput `"1`"`r`n"
}

# 5. Unity Engine (boot.config)
$unityPresets = @{
    'max_fps.ini' = "gfx-enable-gfx-jobs=1`r`ngfx-enable-native-gfx-jobs=1`r`nwait-for-native-debugger=0`r`nplayer-connection-debug=0`r`nhdr-display-enabled=0`r`ngc-max-time-slice=3`r`njob-worker-count=0`r`nvr-enabled=0`r`nsingle-instance=1`r`n"
    'balanced.ini' = "gfx-enable-gfx-jobs=1`r`ngfx-enable-native-gfx-jobs=1`r`nwait-for-native-debugger=0`r`nplayer-connection-debug=0`r`nhdr-display-enabled=0`r`ngc-max-time-slice=3`r`njob-worker-count=0`r`nvr-enabled=0`r`n"
    'ultra_quality.ini' = "gfx-enable-gfx-jobs=1`r`ngfx-enable-native-gfx-jobs=1`r`nwait-for-native-debugger=0`r`nplayer-connection-debug=0`r`nhdr-display-enabled=1`r`ngc-max-time-slice=5`r`njob-worker-count=0`r`n"
}

# 6. RE Engine / Capcom (config.ini / option.ini)
$reEnginePresets = @{
    'max_fps.ini' = "[DISPLAY]`r`nResolution=1920x1080`r`nFullScreen=ON`r`nVSync=OFF`r`nRefreshRate=144.00Hz`r`nFrameRate=0`r`n`r`n[GRAPHICS]`r`nRenderingMode=DirectX12`r`nImageQuality=100`r`nAntiAliasing=FXAA`r`nTextureQuality=LOW`r`nShadowQuality=LOW`r`nShadowCache=ON`r`nContactShadows=OFF`r`nAmbientOcclusion=OFF`r`nBloom=OFF`r`nVolumetricLighting=LOW`r`nMotionBlur=OFF`r`nDepthOfField=OFF`r`nLensFlares=OFF`r`nSubsurfaceScattering=OFF`r`nScreenSpaceReflections=OFF`r`n"
    'balanced.ini' = "[DISPLAY]`r`nResolution=1920x1080`r`nFullScreen=ON`r`nVSync=OFF`r`nRefreshRate=144.00Hz`r`nFrameRate=0`r`n`r`n[GRAPHICS]`r`nRenderingMode=DirectX12`r`nImageQuality=100`r`nAntiAliasing=TAA`r`nTextureQuality=MEDIUM`r`nShadowQuality=MEDIUM`r`nShadowCache=ON`r`nContactShadows=ON`r`nAmbientOcclusion=SSAO`r`nBloom=ON`r`nVolumetricLighting=MEDIUM`r`nMotionBlur=OFF`r`nDepthOfField=OFF`r`nLensFlares=ON`r`nSubsurfaceScattering=ON`r`nScreenSpaceReflections=ON`r`n"
    'ultra_quality.ini' = "[DISPLAY]`r`nResolution=1920x1080`r`nFullScreen=ON`r`nVSync=OFF`r`nRefreshRate=144.00Hz`r`nFrameRate=0`r`n`r`n[GRAPHICS]`r`nRenderingMode=DirectX12`r`nImageQuality=100`r`nAntiAliasing=TAA+FXAA`r`nTextureQuality=HIGH`r`nShadowQuality=HIGH`r`nShadowCache=ON`r`nContactShadows=ON`r`nAmbientOcclusion=HBAO+`r`nBloom=ON`r`nVolumetricLighting=HIGH`r`nMotionBlur=OFF`r`nDepthOfField=ON`r`nLensFlares=ON`r`nSubsurfaceScattering=ON`r`nScreenSpaceReflections=ON`r`n"
}

# 7. REDengine (Cyberpunk 2077 / Witcher 3)
$cyberpunkPresets = @{
    'max_fps.json' = "{`r`n  `"Settings`": {`r`n    `"Graphics`": {`r`n      `"Basic`": {`r`n        `"MotionBlur`": `"Off`",`r`n        `"FilmGrain`": `"Off`",`r`n        `"ChromaticAberration`": `"Off`",`r`n        `"DepthOfField`": `"Off`",`r`n        `"LensFlares`": `"Off`"`r`n      },`r`n      `"Advanced`": {`r`n        `"ContactShadows`": `"Off`",`r`n        `"FacialLightingGeometry`": `"Off`",`r`n        `"Anisotropy`": `"4`",`r`n        `"LocalShadowMeshQuality`": `"Low`",`r`n        `"LocalShadowsQuality`": `"Low`",`r`n        `"CascadedShadowsResolution`": `"Low`",`r`n        `"DistantShadowsResolution`": `"Low`",`r`n        `"VolumetricFogResolution`": `"Low`",`r`n        `"VolumetricCloudsQuality`": `"Low`",`r`n        `"DecalsQuality`": `"Low`",`r`n        `"SubsurfaceScatteringQuality`": `"Low`",`r`n        `"AmbientOcclusion`": `"Low`",`r`n        `"ColorPrecision`": `"Medium`",`r`n        `"RayTracing`": `"Off`"`r`n      },`r`n      `"DynamicResolutionScaling`": {`r`n        `"DynamicResolutionScaling`": `"Off`"`r`n      },`r`n      `"Resolution`": {`r`n        `"WindowMode`": `"Fullscreen`",`r`n        `"VSync`": `"Off`",`r`n        `"MaximumFramesPerSecond`": `"Off`"`r`n      }`r`n    }`r`n  }`r`n}"
    'balanced.json' = "{`r`n  `"Settings`": {`r`n    `"Graphics`": {`r`n      `"Basic`": {`r`n        `"MotionBlur`": `"Off`",`r`n        `"FilmGrain`": `"Off`",`r`n        `"ChromaticAberration`": `"Off`",`r`n        `"DepthOfField`": `"Off`",`r`n        `"LensFlares`": `"On`"`r`n      },`r`n      `"Advanced`": {`r`n        `"ContactShadows`": `"On`",`r`n        `"FacialLightingGeometry`": `"On`",`r`n        `"Anisotropy`": `"8`",`r`n        `"LocalShadowMeshQuality`": `"Medium`",`r`n        `"LocalShadowsQuality`": `"Medium`",`r`n        `"CascadedShadowsResolution`": `"Medium`",`r`n        `"DistantShadowsResolution`": `"High`",`r`n        `"VolumetricFogResolution`": `"Medium`",`r`n        `"VolumetricCloudsQuality`": `"Medium`",`r`n        `"DecalsQuality`": `"Medium`",`r`n        `"SubsurfaceScatteringQuality`": `"Medium`",`r`n        `"AmbientOcclusion`": `"Low`",`r`n        `"ColorPrecision`": `"High`",`r`n        `"RayTracing`": `"Off`"`r`n      },`r`n      `"DynamicResolutionScaling`": {`r`n        `"DynamicResolutionScaling`": `"Off`"`r`n      },`r`n      `"Resolution`": {`r`n        `"WindowMode`": `"Fullscreen`",`r`n        `"VSync`": `"Off`",`r`n        `"MaximumFramesPerSecond`": `"Off`"`r`n      }`r`n    }`r`n  }`r`n}"
    'ultra_quality.json' = "{`r`n  `"Settings`": {`r`n    `"Graphics`": {`r`n      `"Basic`": {`r`n        `"MotionBlur`": `"Off`",`r`n        `"FilmGrain`": `"Off`",`r`n        `"ChromaticAberration`": `"On`",`r`n        `"DepthOfField`": `"On`",`r`n        `"LensFlares`": `"On`"`r`n      },`r`n      `"Advanced`": {`r`n        `"ContactShadows`": `"On`",`r`n        `"FacialLightingGeometry`": `"On`",`r`n        `"Anisotropy`": `"16`",`r`n        `"LocalShadowMeshQuality`": `"High`",`r`n        `"LocalShadowsQuality`": `"High`",`r`n        `"CascadedShadowsResolution`": `"High`",`r`n        `"DistantShadowsResolution`": `"High`",`r`n        `"VolumetricFogResolution`": `"High`",`r`n        `"VolumetricCloudsQuality`": `"High`",`r`n        `"DecalsQuality`": `"High`",`r`n        `"SubsurfaceScatteringQuality`": `"High`",`r`n        `"AmbientOcclusion`": `"High`",`r`n        `"ColorPrecision`": `"High`",`r`n        `"RayTracing`": `"Off`"`r`n      },`r`n      `"DynamicResolutionScaling`": {`r`n        `"DynamicResolutionScaling`": `"Off`"`r`n      },`r`n      `"Resolution`": {`r`n        `"WindowMode`": `"Fullscreen`",`r`n        `"VSync`": `"Off`",`r`n        `"MaximumFramesPerSecond`": `"Off`"`r`n      }`r`n    }`r`n  }`r`n}"
}

$witcher3Presets = @{
    'max_fps.ini' = "[Rendering]`r`nVSync=false`r`nMotionBlur=false`r`nBlur=false`r`nHairWorks=0`r`nShadowQualityValue=0`r`nTerrainQualityValue=0`r`nWaterQualityValue=0`r`nFoliageDistanceValue=0`r`nGrassDensity=0`r`nTextureQualityValue=0`r`nDecalsQualityValue=0`r`nCascadeShadowFadeTreshold=1`r`nCascadeShadowDistanceScale0=1`r`nCascadeShadowDistanceScale1=1`r`nCascadeShadowDistanceScale2=1`r`nMaxTextureSize=1024`r`n`r`n[Visuals]`r`nMovieFramerate=60`r`n`r`n[PostProcess]`r`nMotionBlur=false`r`nMotionBlurPosition=0`r`nBloom=false`r`nColorCorrection=true`r`nDepthOfField=false`r`nVignette=false`r`nChromaticAberration=false`r`n"
    'balanced.ini' = "[Rendering]`r`nVSync=false`r`nMotionBlur=false`r`nBlur=false`r`nHairWorks=0`r`nShadowQualityValue=1`r`nTerrainQualityValue=2`r`nWaterQualityValue=2`r`nFoliageDistanceValue=1`r`nGrassDensity=2000`r`nTextureQualityValue=2`r`nDecalsQualityValue=2`r`n`r`n[Visuals]`r`nMovieFramerate=60`r`n`r`n[PostProcess]`r`nMotionBlur=false`r`nBloom=true`r`nColorCorrection=true`r`nDepthOfField=false`r`nVignette=false`r`nChromaticAberration=false`r`n"
    'ultra_quality.ini' = "[Rendering]`r`nVSync=false`r`nMotionBlur=false`r`nBlur=false`r`nHairWorks=0`r`nShadowQualityValue=3`r`nTerrainQualityValue=3`r`nWaterQualityValue=3`r`nFoliageDistanceValue=3`r`nGrassDensity=4000`r`nTextureQualityValue=3`r`nDecalsQualityValue=3`r`n`r`n[Visuals]`r`nMovieFramerate=60`r`n`r`n[PostProcess]`r`nMotionBlur=false`r`nBloom=true`r`nColorCorrection=true`r`nDepthOfField=true`r`nVignette=true`r`nChromaticAberration=false`r`n"
}

# 8. RAGE Engine (GTA IV / RDR2)
$rdr2Presets = @{
    'max_fps.xml' = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`r`n<graphics>`r`n  <tAALevel value=`"2`" />`r`n  <anisotropicFiltering value=`"4`" />`r`n  <shadowQuality value=`"0`" />`r`n  <farShadowQuality value=`"0`" />`r`n  <ssao value=`"0`" />`r`n  <reflectionQuality value=`"0`" />`r`n  <waterQuality value=`"0`" />`r`n  <volumetricsQuality value=`"0`" />`r`n  <particleQuality value=`"0`" />`r`n  <decalQuality value=`"1`" />`r`n  <grassQuality value=`"0`" />`r`n  <treeQuality value=`"0`" />`r`n  <motionBlur value=`"false`" />`r`n  <vSync value=`"0`" />`r`n  <tripleBuffered value=`"false`" />`r`n  <windowed value=`"0`" />`r`n</graphics>`r`n"
    'balanced.xml' = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`r`n<graphics>`r`n  <tAALevel value=`"2`" />`r`n  <anisotropicFiltering value=`"8`" />`r`n  <shadowQuality value=`"1`" />`r`n  <farShadowQuality value=`"1`" />`r`n  <ssao value=`"1`" />`r`n  <reflectionQuality value=`"1`" />`r`n  <waterQuality value=`"1`" />`r`n  <volumetricsQuality value=`"1`" />`r`n  <particleQuality value=`"1`" />`r`n  <decalQuality value=`"2`" />`r`n  <grassQuality value=`"1`" />`r`n  <treeQuality value=`"1`" />`r`n  <motionBlur value=`"false`" />`r`n  <vSync value=`"0`" />`r`n  <tripleBuffered value=`"false`" />`r`n  <windowed value=`"0`" />`r`n</graphics>`r`n"
    'ultra_quality.xml' = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`r`n<graphics>`r`n  <tAALevel value=`"2`" />`r`n  <anisotropicFiltering value=`"16`" />`r`n  <shadowQuality value=`"2`" />`r`n  <farShadowQuality value=`"2`" />`r`n  <ssao value=`"2`" />`r`n  <reflectionQuality value=`"2`" />`r`n  <waterQuality value=`"2`" />`r`n  <volumetricsQuality value=`"2`" />`r`n  <particleQuality value=`"2`" />`r`n  <decalQuality value=`"2`" />`r`n  <grassQuality value=`"2`" />`r`n  <treeQuality value=`"2`" />`r`n  <motionBlur value=`"false`" />`r`n  <vSync value=`"0`" />`r`n  <tripleBuffered value=`"false`" />`r`n  <windowed value=`"0`" />`r`n</graphics>`r`n"
}

$gta4Presets = @{
    'max_fps.cfg' = "-norestrictions`r`n-nomemrestrict`r`n-novblank`r`n-availablevidmem 4096`r`n-frameLimit 0`r`n-height 1080`r`n-width 1920`r`n-fullscreen`r`n-shadowdensity 0`r`n-viewdistance 20`r`n-detailquality 20`r`n-texturequality 0`r`n-renderquality 0`r`n"
    'balanced.cfg' = "-norestrictions`r`n-nomemrestrict`r`n-novblank`r`n-availablevidmem 4096`r`n-frameLimit 0`r`n-height 1080`r`n-width 1920`r`n-fullscreen`r`n-shadowdensity 4`r`n-viewdistance 40`r`n-detailquality 40`r`n-texturequality 1`r`n-renderquality 1`r`n"
    'ultra_quality.cfg' = "-norestrictions`r`n-nomemrestrict`r`n-novblank`r`n-availablevidmem 4096`r`n-frameLimit 0`r`n-height 1080`r`n-width 1920`r`n-fullscreen`r`n-shadowdensity 16`r`n-viewdistance 70`r`n-detailquality 70`r`n-texturequality 2`r`n-renderquality 2`r`n"
}

# 9. FromSoftware (ELDEN RING / Dark Souls 3 / Sekiro / Armored Core 6)
$fromSoftPresets = @{
    'max_fps.xml' = "<?xml version=`"1.0`" encoding=`"UTF-16`"?>`r`n<GraphicsConfig>`r`n  <ScreenMode>FULLSCREEN</ScreenMode>`r`n  <Resolution-FullScreenX>1920</Resolution-FullScreenX>`r`n  <Resolution-FullScreenY>1080</Resolution-FullScreenY>`r`n  <Quality>CUSTOM</Quality>`r`n  <TextureQuality>LOW</TextureQuality>`r`n  <AntialiasingQuality>LOW</AntialiasingQuality>`r`n  <SSAO>DISABLE</SSAO>`r`n  <DepthOfField>DISABLE</DepthOfField>`r`n  <MotionBlur>DISABLE</MotionBlur>`r`n  <ShadowQuality>LOW</ShadowQuality>`r`n  <LightingQuality>LOW</LightingQuality>`r`n  <EffectsQuality>LOW</EffectsQuality>`r`n  <ReflectionQuality>LOW</ReflectionQuality>`r`n  <WaterSurfaceQuality>LOW</WaterSurfaceQuality>`r`n  <ShadingQuality>LOW</ShadingQuality>`r`n  <VolumetricEffectQuality>LOW</VolumetricEffectQuality>`r`n  <RaytracingQuality>DISABLE</RaytracingQuality>`r`n</GraphicsConfig>`r`n"
    'balanced.xml' = "<?xml version=`"1.0`" encoding=`"UTF-16`"?>`r`n<GraphicsConfig>`r`n  <ScreenMode>FULLSCREEN</ScreenMode>`r`n  <Resolution-FullScreenX>1920</Resolution-FullScreenX>`r`n  <Resolution-FullScreenY>1080</Resolution-FullScreenY>`r`n  <Quality>CUSTOM</Quality>`r`n  <TextureQuality>MEDIUM</TextureQuality>`r`n  <AntialiasingQuality>MEDIUM</AntialiasingQuality>`r`n  <SSAO>LOW</SSAO>`r`n  <DepthOfField>DISABLE</DepthOfField>`r`n  <MotionBlur>DISABLE</MotionBlur>`r`n  <ShadowQuality>MEDIUM</ShadowQuality>`r`n  <LightingQuality>MEDIUM</LightingQuality>`r`n  <EffectsQuality>MEDIUM</EffectsQuality>`r`n  <ReflectionQuality>MEDIUM</ReflectionQuality>`r`n  <WaterSurfaceQuality>MEDIUM</WaterSurfaceQuality>`r`n  <ShadingQuality>MEDIUM</ShadingQuality>`r`n  <VolumetricEffectQuality>MEDIUM</VolumetricEffectQuality>`r`n  <RaytracingQuality>DISABLE</RaytracingQuality>`r`n</GraphicsConfig>`r`n"
    'ultra_quality.xml' = "<?xml version=`"1.0`" encoding=`"UTF-16`"?>`r`n<GraphicsConfig>`r`n  <ScreenMode>FULLSCREEN</ScreenMode>`r`n  <Resolution-FullScreenX>1920</Resolution-FullScreenX>`r`n  <Resolution-FullScreenY>1080</Resolution-FullScreenY>`r`n  <Quality>HIGH</Quality>`r`n  <TextureQuality>HIGH</TextureQuality>`r`n  <AntialiasingQuality>HIGH</AntialiasingQuality>`r`n  <SSAO>HIGH</SSAO>`r`n  <DepthOfField>HIGH</DepthOfField>`r`n  <MotionBlur>DISABLE</MotionBlur>`r`n  <ShadowQuality>HIGH</ShadowQuality>`r`n  <LightingQuality>HIGH</LightingQuality>`r`n  <EffectsQuality>HIGH</EffectsQuality>`r`n  <ReflectionQuality>HIGH</ReflectionQuality>`r`n  <WaterSurfaceQuality>HIGH</WaterSurfaceQuality>`r`n  <ShadingQuality>HIGH</ShadingQuality>`r`n  <VolumetricEffectQuality>HIGH</VolumetricEffectQuality>`r`n  <RaytracingQuality>DISABLE</RaytracingQuality>`r`n</GraphicsConfig>`r`n"
}

# 10. Dagor Engine (War Thunder)
$dagorPresets = @{
    'max_fps.blk' = "graphics{`r`n  advancedShore:b=no`r`n  anisotropy:i=2`r`n  backgroundScale:r=1`r`n  clipmapScale:r=0.5`r`n  cloudsQuality:i=0`r`n  contactShadowsQuality:i=0`r`n  dirtFx:b=no`r`n  displacementQuality:i=0`r`n  effectsFrameRate:i=1`r`n  enableSuspensionAnimation:b=no`r`n  foamQuality:t=`"low`"`r`n  fxDensityMul:r=0.2`r`n  fxTarget:t=`"low`"`r`n  giQuality:t=`"low`"`r`n  grassRadiusMul:r=0.1`r`n  landquality:i=0`r`n  lastClipSize:i=1024`r`n  lenseFlares:b=no`r`n  motionBlur:b=no`r`n  panoramaResolution:i=1024`r`n  physicsQuality:i=0`r`n  rendinstDistMul:r=0.5`r`n  riGpuObjects:b=no`r`n  shadowQuality:t=`"ultralow`"`r`n  skyQuality:i=0`r`n  texquality:t=`"low`"`r`n  tireTracksQuality:i=0`r`n  waterEffectsQuality:t=`"low`"`r`n  waterQuality:t=`"low`"`r`n}`r`nvideo{`r`n  vsync:b=no`r`n  adaptive_vsync:b=no`r`n  resolution:t=`"1920 x 1080`"`r`n  mode:t=`"fullscreen`"`r`n}`r`n"
    'balanced.blk' = "graphics{`r`n  anisotropy:i=4`r`n  backgroundScale:r=1`r`n  cloudsQuality:i=1`r`n  contactShadowsQuality:i=1`r`n  dirtFx:b=yes`r`n  fxDensityMul:r=0.7`r`n  fxTarget:t=`"medium`"`r`n  giQuality:t=`"medium`"`r`n  grassRadiusMul:r=0.7`r`n  landquality:i=2`r`n  motionBlur:b=no`r`n  shadowQuality:t=`"low`"`r`n  texquality:t=`"medium`"`r`n  waterQuality:t=`"medium`"`r`n}`r`nvideo{`r`n  vsync:b=no`r`n  resolution:t=`"1920 x 1080`"`r`n  mode:t=`"fullscreen`"`r`n}`r`n"
    'ultra_quality.blk' = "graphics{`r`n  anisotropy:i=16`r`n  backgroundScale:r=1`r`n  cloudsQuality:i=2`r`n  contactShadowsQuality:i=2`r`n  dirtFx:b=yes`r`n  fxDensityMul:r=1`r`n  fxTarget:t=`"high`"`r`n  giQuality:t=`"high`"`r`n  grassRadiusMul:r=1`r`n  landquality:i=3`r`n  motionBlur:b=no`r`n  shadowQuality:t=`"high`"`r`n  texquality:t=`"high`"`r`n  waterQuality:t=`"high`"`r`n}`r`nvideo{`r`n  vsync:b=no`r`n  resolution:t=`"1920 x 1080`"`r`n  mode:t=`"fullscreen`"`r`n}`r`n"
}

# 11. Frostbite Engine (Battlefield V / EA SPORTS FC)
$frostbitePresets = @{
    'max_fps.cfg' = "GstRender.ResolutionScale 1.000000`r`nGstRender.VSyncMode 0`r`nGstRender.MotionBlurEnabled 0`r`nGstRender.MotionBlurWorld 0.000000`r`nGstRender.ShadowQuality 0`r`nGstRender.PostProcessQuality 0`r`nGstRender.TextureQuality 0`r`nGstRender.TextureFiltering 0`r`nGstRender.EffectsQuality 0`r`nGstRender.UndergrowthQuality 0`r`nGstRender.MeshQuality 0`r`nGstRender.TerrainQuality 0`r`nGstRender.LightingQuality 0`r`nGstRender.AntiAliasingPost 0`r`nGstRender.AmbientOcclusion 0`r`nGstRender.HighDynamicRange 0`r`nGstRender.Dx12Enabled 1`r`nGstRender.FutureFrameRendering 1`r`n"
    'balanced.cfg' = "GstRender.ResolutionScale 1.000000`r`nGstRender.VSyncMode 0`r`nGstRender.MotionBlurEnabled 0`r`nGstRender.MotionBlurWorld 0.000000`r`nGstRender.ShadowQuality 1`r`nGstRender.PostProcessQuality 1`r`nGstRender.TextureQuality 1`r`nGstRender.TextureFiltering 1`r`nGstRender.EffectsQuality 1`r`nGstRender.UndergrowthQuality 1`r`nGstRender.MeshQuality 1`r`nGstRender.TerrainQuality 1`r`nGstRender.LightingQuality 1`r`nGstRender.AntiAliasingPost 1`r`nGstRender.AmbientOcclusion 1`r`nGstRender.HighDynamicRange 0`r`nGstRender.Dx12Enabled 1`r`nGstRender.FutureFrameRendering 1`r`n"
    'ultra_quality.cfg' = "GstRender.ResolutionScale 1.000000`r`nGstRender.VSyncMode 0`r`nGstRender.MotionBlurEnabled 0`r`nGstRender.MotionBlurWorld 0.000000`r`nGstRender.ShadowQuality 2`r`nGstRender.PostProcessQuality 2`r`nGstRender.TextureQuality 2`r`nGstRender.TextureFiltering 2`r`nGstRender.EffectsQuality 2`r`nGstRender.UndergrowthQuality 2`r`nGstRender.MeshQuality 2`r`nGstRender.TerrainQuality 2`r`nGstRender.LightingQuality 2`r`nGstRender.AntiAliasingPost 2`r`nGstRender.AmbientOcclusion 2`r`nGstRender.HighDynamicRange 0`r`nGstRender.Dx12Enabled 1`r`nGstRender.FutureFrameRendering 1`r`n"
}

# 12. Generic PC / Action / Simulation INI
$genericIniPresets = @{
    'max_fps.ini' = "[Graphics]`r`nResolutionWidth=1920`r`nResolutionHeight=1080`r`nFullScreen=1`r`nVSync=0`r`nMaxFPS=0`r`nShadowQuality=0`r`nTextureQuality=0`r`nEffectsQuality=0`r`nPostProcessing=0`r`nAntiAliasing=0`r`nAmbientOcclusion=0`r`nMotionBlur=0`r`nDepthOfField=0`r`nRenderScale=90`r`n"
    'balanced.ini' = "[Graphics]`r`nResolutionWidth=1920`r`nResolutionHeight=1080`r`nFullScreen=1`r`nVSync=0`r`nMaxFPS=0`r`nShadowQuality=1`r`nTextureQuality=1`r`nEffectsQuality=1`r`nPostProcessing=1`r`nAntiAliasing=1`r`nAmbientOcclusion=1`r`nMotionBlur=0`r`nDepthOfField=0`r`nRenderScale=100`r`n"
    'ultra_quality.ini' = "[Graphics]`r`nResolutionWidth=1920`r`nResolutionHeight=1080`r`nFullScreen=1`r`nVSync=0`r`nMaxFPS=0`r`nShadowQuality=2`r`nTextureQuality=2`r`nEffectsQuality=2`r`nPostProcessing=2`r`nAntiAliasing=2`r`nAmbientOcclusion=2`r`nMotionBlur=0`r`nDepthOfField=1`r`nRenderScale=100`r`n"
}

$opt0to3 = @(
    (New-TweakOption 'Low / Off' '0'),
    (New-TweakOption 'Medium' '1'),
    (New-TweakOption 'High' '2'),
    (New-TweakOption 'Ultra' '3')
)

$optToggle = @(
    (New-TweakOption 'Off' '0'),
    (New-TweakOption 'On' '1')
)

$optToggleBool = @(
    (New-TweakOption 'Off' 'false'),
    (New-TweakOption 'On' 'true')
)

# --- PROCESS MISSING GAMES ---
Write-Host "== Generating missing game configurations =="
$createdCount = 0

foreach ($g in $games) {
    if ($g.presets -and $g.presets.Count -ge 3) {
        # Already has curated presets
        continue
    }

    $id = $g.id
    $engine = [string]$g.engine
    $name = [string]$g.name
    $appId = [string]$g.steamAppId
    $dir = Join-Path $root $id

    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    $presetDefinitions = New-Object System.Collections.ArrayList
    $tweakSettings = New-Object System.Collections.ArrayList
    $genericPaths = New-Object System.Collections.ArrayList
    $configType = "ini"
    $configFileName = "config.ini"

    # Match Game Profile by Engine / Name / AppID
    if ($engine -match 'Unreal Engine [45]') {
        $configType = "ini"
        $configFileName = "GameUserSettings.ini"
        $subFolder = if ($engine -match '5') { 'Windows' } else { 'WindowsNoEditor' }

        $alnum = ($name -replace '[^A-Za-z0-9]', '')
        [void]$genericPaths.Add("%LOCALAPPDATA%\$alnum\Saved\Config\$subFolder\GameUserSettings.ini")
        [void]$genericPaths.Add("%LOCALAPPDATA%\$alnum\Saved\Config\Windows\GameUserSettings.ini")
        [void]$genericPaths.Add("%LOCALAPPDATA%\$alnum\Saved\Config\WindowsNoEditor\GameUserSettings.ini")

        foreach ($k in $uePresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($uePresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'All scalability groups to 0 and render scale tuned for lowest input latency and maximum frame rate.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Balanced medium scalability with native 100% 3D resolution for competitive clarity.' 'Competitive' 'BALANCED' 'balanced.ini' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High and Epic scalability groups with VSync off for maximum fidelity.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'sg.ResolutionQuality' '3D Resolution Scale' 'Internal render resolution percentage.' 'Display' 'Slider' 'ScalabilityGroups' '100' 50 120 5))
        [void]$tweakSettings.Add((New-TweakSetting 'sg.ViewDistanceQuality' 'View Distance' 'Geometry draw distance' 'Quality' 'Select' 'ScalabilityGroups' '0' 0 3 1 $opt0to3))
        [void]$tweakSettings.Add((New-TweakSetting 'sg.ShadowQuality' 'Shadows' 'Dynamic shadow resolution' 'Quality' 'Select' 'ScalabilityGroups' '0' 0 3 1 $opt0to3))
        [void]$tweakSettings.Add((New-TweakSetting 'sg.TextureQuality' 'Textures' 'Texture detail and VRAM allocation' 'Quality' 'Select' 'ScalabilityGroups' '0' 0 3 1 $opt0to3))
        [void]$tweakSettings.Add((New-TweakSetting 'sg.PostProcessQuality' 'Post Processing' 'Bloom, lens, motion blur' 'Quality' 'Select' 'ScalabilityGroups' '0' 0 3 1 $opt0to3))
    }
    elseif ($engine -match 'Unreal Engine 3') {
        $configType = "ini"
        $configFileName = "Engine.ini"
        $alnum = ($name -replace '[^A-Za-z0-9]', '')
        [void]$genericPaths.Add("%USERPROFILE%\Documents\My Games\$alnum\$alnum`Game\Config\$alnum`Engine.ini")
        [void]$genericPaths.Add("%USERPROFILE%\Documents\My Games\$name\Config\Engine.ini")

        foreach ($k in $ue3Presets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($ue3Presets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Dynamic lights and shadows disabled, texture bias optimized for extreme Unreal 3 responsiveness.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium textures and dynamic lighting with smooth frame pacing.' 'Competitive' 'BALANCED' 'balanced.ini' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'Maximum texture detail and ambient occlusion enabled.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'bUseVSync' 'VSync' 'Adds input latency when enabled' 'Esports' 'Toggle' 'SystemSettings' 'False' 0 1 1 $optToggleBool))
        [void]$tweakSettings.Add((New-TweakSetting 'DynamicShadows' 'Dynamic Shadows' 'Shadow rendering' 'Quality' 'Toggle' 'SystemSettings' 'False' 0 1 1 $optToggleBool))
        [void]$tweakSettings.Add((New-TweakSetting 'MotionBlur' 'Motion Blur' 'Camera blur' 'Quality' 'Toggle' 'SystemSettings' 'False' 0 1 1 $optToggleBool))
    }
    elseif ($engine -match 'Source' -or $id -eq 'steam_340' -or $id -eq 'steam_380' -or $id -eq 'steam_360' -or $id -eq 'steam_420' -or $id -eq 'steam_620' -or $id -eq 'steam_500' -or $id -eq 'steam_224260' -or $id -eq 'steam_1237970') {
        $configType = "txt"
        $configFileName = "video.txt"

        foreach ($k in $sourcePresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($sourcePresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'No anti-aliasing, no anisotropic filtering, VSync off, lowest shadow cascades for classic Source latency.' 'MaxFPS' 'MAX FPS' 'max_fps.txt' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' '2x MSAA and 4x anisotropic filtering for clear visuals and solid frametimes.' 'Competitive' 'BALANCED' 'balanced.txt' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' '8x MSAA and 16x anisotropic filtering with maximum model details.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.txt' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'setting.mat_vsync' 'VSync' 'Vertical Synchronization' 'Esports' 'Toggle' 'VideoConfig' '0' 0 1 1 $optToggle))
        [void]$tweakSettings.Add((New-TweakSetting 'setting.mat_antialias' 'Anti-Aliasing' 'MSAA quality' 'Quality' 'Select' 'VideoConfig' '0' 0 8 2 @((New-TweakOption 'Off' '0'), (New-TweakOption '2x MSAA' '2'), (New-TweakOption '4x MSAA' '4'), (New-TweakOption '8x MSAA' '8'))))
        [void]$tweakSettings.Add((New-TweakSetting 'setting.mat_motion_blur_enabled' 'Motion Blur' 'Camera motion blur' 'Quality' 'Toggle' 'VideoConfig' '0' 0 1 1 $optToggle))
    }
    elseif ($engine -match 'GoldSrc' -or $id -eq 'steam_70' -or $id -eq 'steam_80' -or $id -eq 'steam_40' -or $id -eq 'steam_30' -or $id -eq 'steam_223710' -or $id -eq 'steam_273110') {
        $configType = "cfg"
        $configFileName = "autoexec.cfg"

        foreach ($k in $goldSrcPresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($goldSrcPresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Optimized GoldSrc rates, raw mouse input enabled, VSync disabled, uncapped FPS.' 'MaxFPS' 'MAX FPS' 'max_fps.cfg' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Balanced GoldSrc 144Hz configuration with texture smoothing.' 'Competitive' 'BALANCED' 'balanced.cfg' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'Maximum anisotropic filtering and dynamic lighting in GoldSrc.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.cfg' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'gl_vsync' 'VSync' 'Disable for minimum latency' 'Esports' 'Toggle' '' '0' 0 1 1 $optToggle))
        [void]$tweakSettings.Add((New-TweakSetting 'fps_max' 'Max FPS' 'Frame rate ceiling' 'Esports' 'Slider' '' '144' 60 500 10))
        [void]$tweakSettings.Add((New-TweakSetting 'm_rawinput' 'Raw Input' 'Direct hardware mouse polling' 'Esports' 'Toggle' '' '1' 0 1 1 $optToggle))
    }
    elseif ($id -eq 'steam_1091500') { # Cyberpunk 2077
        $configType = "json"
        $configFileName = "UserSettings.json"
        [void]$genericPaths.Add("%LOCALAPPDATA%\CD Projekt Red\Cyberpunk 2077\UserSettings.json")

        foreach ($k in $cyberpunkPresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($cyberpunkPresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Optimized cascaded shadows, volumetric fog trimmed, ray tracing off for high FPS in Night City.' 'MaxFPS' 'MAX FPS' 'max_fps.json' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium volumetric lighting, high texture detail, smooth frame pacing.' 'Competitive' 'BALANCED' 'balanced.json' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High ambient occlusion and sharp distant shadows.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.json' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'RayTracing' 'Ray Tracing' 'Enable DXR ray tracing' 'Quality' 'Select' 'Advanced' 'Off' 0 1 1 @((New-TweakOption 'Off' 'Off'), (New-TweakOption 'On' 'On'))))
        [void]$tweakSettings.Add((New-TweakSetting 'VolumetricFogResolution' 'Volumetric Fog' 'Fog quality' 'Quality' 'Select' 'Advanced' 'Low' 0 2 1 @((New-TweakOption 'Low' 'Low'), (New-TweakOption 'Medium' 'Medium'), (New-TweakOption 'High' 'High'))))
    }
    elseif ($id -eq 'steam_292030') { # Witcher 3
        $configType = "ini"
        $configFileName = "user.settings"
        [void]$genericPaths.Add("%USERPROFILE%\Documents\The Witcher 3\user.settings")

        foreach ($k in $witcher3Presets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($witcher3Presets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'HairWorks disabled, foliage distance optimized, VSync disabled for smooth monster hunting.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'High terrain detail with medium foliage for balanced visual quality.' 'Competitive' 'BALANCED' 'balanced.ini' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'Ultra textures, ambient occlusion and high foliage draw distance.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'HairWorks' 'NVIDIA HairWorks' 'Heavy GPU hair simulation' 'Quality' 'Select' 'Rendering' '0' 0 2 1 @((New-TweakOption 'Off' '0'), (New-TweakOption 'Geralt Only' '1'), (New-TweakOption 'All' '2'))))
        [void]$tweakSettings.Add((New-TweakSetting 'VSync' 'VSync' 'Vertical Synchronization' 'Esports' 'Toggle' 'Rendering' 'false' 0 1 1 $optToggleBool))
    }
    elseif ($id -eq 'steam_1174180') { # Red Dead Redemption 2
        $configType = "xml"
        $configFileName = "system.xml"
        [void]$genericPaths.Add("%USERPROFILE%\Documents\Rockstar Games\Red Dead Redemption 2\Settings\system.xml")

        foreach ($k in $rdr2Presets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($rdr2Presets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Volumetrics low, far shadows trimmed, TAA sharpened for competitive FPS in RDR2.' 'MaxFPS' 'MAX FPS' 'max_fps.xml' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium volumetrics and high texture quality for cinematic clarity.' 'Competitive' 'BALANCED' 'balanced.xml' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'Ultra textures and high water/tree detail with VSync off.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.xml' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'volumetricsQuality' 'Volumetrics Quality' 'Fog and volumetric clouds' 'Quality' 'Select' 'graphics' '0' 0 2 1 $opt0to3))
        [void]$tweakSettings.Add((New-TweakSetting 'shadowQuality' 'Shadow Quality' 'Shadow resolution' 'Quality' 'Select' 'graphics' '0' 0 2 1 $opt0to3))
    }
    elseif ($id -eq 'steam_901583') { # GTA IV
        $configType = "cfg"
        $configFileName = "commandline.txt"
        [void]$genericPaths.Add("%LOCALAPPDATA%\Rockstar Games\GTA IV\Settings\settings.cfg")

        foreach ($k in $gta4Presets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($gta4Presets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Memory restrictions unlocked, VBlank disabled, optimized view distance for GTA IV.' 'MaxFPS' 'MAX FPS' 'max_fps.cfg' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Balanced 40% view distance and high resolution textures.' 'Competitive' 'BALANCED' 'balanced.cfg' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' '70% draw distance and maximum render detail.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.cfg' $false))

        [void]$tweakSettings.Add((New-TweakSetting '-viewdistance' 'View Distance' 'Render distance (0-100)' 'Display' 'Slider' '' '30' 10 100 5))
    }
    elseif ($id -eq 'steam_1245620' -or $id -eq 'steam_374320' -or $id -eq 'steam_814380') { # Elden Ring / Dark Souls / Sekiro
        $configType = "xml"
        $configFileName = "GraphicsConfig.xml"
        [void]$genericPaths.Add("%APPDATA%\EldenRing\GraphicsConfig.xml")
        [void]$genericPaths.Add("%APPDATA%\DarkSoulsIII\GraphicsConfig.xml")
        [void]$genericPaths.Add("%APPDATA%\Sekiro\GraphicsConfig.xml")

        foreach ($k in $fromSoftPresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($fromSoftPresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'SSAO disabled, shadows low, motion blur disabled for stable frame pacing and combat responsiveness.' 'MaxFPS' 'MAX FPS' 'max_fps.xml' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium textures and lighting for crisp visuals in the Lands Between.' 'Competitive' 'BALANCED' 'balanced.xml' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High SSAO and maximum model detail.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.xml' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'ShadowQuality' 'Shadow Quality' 'Shadow cascades' 'Quality' 'Select' 'GraphicsConfig' 'LOW' 0 2 1 @((New-TweakOption 'Low' 'LOW'), (New-TweakOption 'Medium' 'MEDIUM'), (New-TweakOption 'High' 'HIGH'))))
        [void]$tweakSettings.Add((New-TweakSetting 'MotionBlur' 'Motion Blur' 'Camera rotation blur' 'Quality' 'Select' 'GraphicsConfig' 'DISABLE' 0 1 1 @((New-TweakOption 'Disable' 'DISABLE'), (New-TweakOption 'High' 'HIGH'))))
    }
    elseif ($id -eq 'steam_236390') { # War Thunder
        $configType = "blk"
        $configFileName = "config.blk"
        [void]$genericPaths.Add("%LOCALAPPDATA%\WarThunder\config.blk")

        foreach ($k in $dagorPresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($dagorPresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Ultra-low shadows, particle effects trimmed, VSync off for maximum spotting distance in battle.' 'MaxFPS' 'MAX FPS' 'max_fps.blk' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium water and terrain quality with low shadow footprint.' 'Competitive' 'BALANCED' 'balanced.blk' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High clouds and 16x anisotropic filtering with VSync off.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.blk' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'shadowQuality' 'Shadow Quality' 'Shadow rendering level' 'Quality' 'Select' 'graphics' 'ultralow' 0 3 1 @((New-TweakOption 'Ultra Low' 'ultralow'), (New-TweakOption 'Low' 'low'), (New-TweakOption 'Medium' 'medium'), (New-TweakOption 'High' 'high'))))
        [void]$tweakSettings.Add((New-TweakSetting 'vsync' 'VSync' 'Vertical Synchronization' 'Esports' 'Toggle' 'video' 'no' 0 1 1 @((New-TweakOption 'Off' 'no'), (New-TweakOption 'On' 'yes'))))
    }
    elseif ($engine -match 'RE Engine' -or $engine -match 'MT Framework' -or $id -eq 'steam_582010' -or $id -eq 'steam_2246340' -or $id -eq 'steam_883710' -or $id -eq 'steam_601150' -or $id -eq 'steam_1446780' -or $id -eq 'steam_2050650') {
        $configType = "ini"
        $configFileName = "config.ini"
        [void]$genericPaths.Add("%LOCALAPPDATA%\CAPCOM\$id\config.ini")

        foreach ($k in $reEnginePresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($reEnginePresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'DirectX 12 mode, VSync disabled, FXAA and low shadow cascades for maximum combat FPS.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'TAA anti-aliasing and medium shadows with high frame rates.' 'Competitive' 'BALANCED' 'balanced.ini' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High texture detail, ambient occlusion, and screen space reflections.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'VSync' 'VSync' 'Vertical Synchronization' 'Esports' 'Toggle' 'DISPLAY' 'OFF' 0 1 1 @((New-TweakOption 'Off' 'OFF'), (New-TweakOption 'On' 'ON'))))
        [void]$tweakSettings.Add((New-TweakSetting 'ShadowQuality' 'Shadow Quality' 'Shadow resolution' 'Quality' 'Select' 'GRAPHICS' 'LOW' 0 2 1 @((New-TweakOption 'Low' 'LOW'), (New-TweakOption 'Medium' 'MEDIUM'), (New-TweakOption 'High' 'HIGH'))))
    }
    elseif ($engine -match 'Frostbite' -or $id -eq 'steam_1238810' -or $id -eq 'steam_2195250' -or $id -eq 'steam_2669320' -or $id -eq 'steam_1811260') {
        $configType = "cfg"
        $configFileName = "user.cfg"
        [void]$genericPaths.Add("%USERPROFILE%\Documents\EA SPORTS FC\PROFSAVE_profile")
        [void]$genericPaths.Add("%USERPROFILE%\Documents\Battlefield V\settings\PROFSAVE_profile")

        foreach ($k in $frostbitePresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($frostbitePresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Future frame rendering on, VSync off, low shadow and post-process overhead for high FPS.' 'MaxFPS' 'MAX FPS' 'max_fps.cfg' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium textures and lighting for competitive clarity and stable frame pacing.' 'Competitive' 'BALANCED' 'balanced.cfg' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High ambient occlusion and high texture filtering with VSync disabled.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.cfg' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'GstRender.VSyncMode' 'VSync' 'Vertical Synchronization' 'Esports' 'Toggle' '' '0' 0 1 1 $optToggle))
        [void]$tweakSettings.Add((New-TweakSetting 'GstRender.ShadowQuality' 'Shadow Quality' 'Dynamic shadow resolution' 'Quality' 'Select' '' '0' 0 2 1 $opt0to3))
    }
    elseif ($engine -match 'Unity' -or $id -eq 'steam_304930' -or $id -eq 'steam_242760' -or $id -eq 'steam_899770' -or $id -eq 'steam_438100' -or $id -eq 'steam_945360' -or $id -eq 'steam_1097150' -or $id -eq 'steam_892970' -or $id -eq 'steam_739630' -or $id -eq 'steam_1966720' -or $id -eq 'steam_1604030' -or $id -eq 'steam_294100' -or $id -eq 'steam_264710' -or $id -eq 'steam_2881650' -or $id -eq 'steam_1782210' -or $id -eq 'steam_2186680' -or $id -eq 'steam_3241660' -or $id -eq 'steam_632360' -or $id -eq 'steam_367520' -or $id -eq 'steam_301520' -or $id -eq 'steam_767560' -or $id -eq 'steam_700330' -or $id -eq 'steam_766570' -or $id -eq 'steam_1118200' -or $id -eq 'steam_1677740') {
        $configType = "ini"
        $configFileName = "boot.config"
        $alnum = ($name -replace '[^A-Za-z0-9]', '')
        [void]$genericPaths.Add("%USERPROFILE%\AppData\LocalLow\$alnum\$alnum\config.json")
        [void]$genericPaths.Add("%USERPROFILE%\AppData\LocalLow\$alnum\config.json")

        foreach ($k in $unityPresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($unityPresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'Native GFX job threading enabled, garbage collection time slice tuned for lowest stutter.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Balanced multi-threaded rendering and stable frame pacing.' 'Competitive' 'BALANCED' 'balanced.ini' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High quality rendering buffer with full thread allocation.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'gfx-enable-gfx-jobs' 'GFX Job Multi-Threading' 'Offload render submissions to worker threads' 'Esports' 'Toggle' '' '1' 0 1 1 $optToggle))
        [void]$tweakSettings.Add((New-TweakSetting 'gc-max-time-slice' 'GC Time Slice (ms)' 'Max frame budget spent in garbage collector' 'Esports' 'Slider' '' '3' 1 10 1))
    }
    else {
        # General PC / Simulation / Action game
        $configType = "ini"
        $configFileName = "settings.ini"
        $alnum = ($name -replace '[^A-Za-z0-9]', '')
        [void]$genericPaths.Add("%LOCALAPPDATA%\$alnum\settings.ini")
        [void]$genericPaths.Add("%APPDATA%\$alnum\config.ini")
        [void]$genericPaths.Add("%USERPROFILE%\Documents\My Games\$name\settings.ini")

        foreach ($k in $genericIniPresets.Keys) {
            [System.IO.File]::WriteAllText((Join-Path $dir $k), ($genericIniPresets[$k]), $utf8)
        }

        [void]$presetDefinitions.Add((New-PresetObject 'max_fps' 'Max FPS' 'VSync disabled, shadow and post-processing overhead minimized for high framerates.' 'MaxFPS' 'MAX FPS' 'max_fps.ini' $true))
        [void]$presetDefinitions.Add((New-PresetObject 'balanced' 'Balanced' 'Medium graphical presets with 100% native render resolution.' 'Competitive' 'BALANCED' 'balanced.ini' $false))
        [void]$presetDefinitions.Add((New-PresetObject 'ultra_quality' 'High Quality' 'High graphical details and texture quality with VSync off.' 'UltraQuality' 'HIGH QUALITY' 'ultra_quality.ini' $false))

        [void]$tweakSettings.Add((New-TweakSetting 'VSync' 'VSync' 'Vertical Synchronization' 'Esports' 'Toggle' 'Graphics' '0' 0 1 1 $optToggle))
        [void]$tweakSettings.Add((New-TweakSetting 'ShadowQuality' 'Shadow Quality' 'Shadow rendering level' 'Quality' 'Select' 'Graphics' '0' 0 2 1 $opt0to3))
        [void]$tweakSettings.Add((New-TweakSetting 'TextureQuality' 'Texture Quality' 'Texture resolution' 'Quality' 'Select' 'Graphics' '0' 0 2 1 $opt0to3))
    }

    # Assign to game manifest object
    $g.configType = $configType
    $g.configFileName = $configFileName
    $g.genericConfigPaths = @($genericPaths)
    $g.presets = @($presetDefinitions)
    $g.tweakableSettings = @($tweakSettings)

    # Launch Option Presets (if not already set)
    if (-not $g.launchOptionPresets -or $g.launchOptionPresets.Count -eq 0) {
        $loPresets = New-Object System.Collections.ArrayList
        [void]$loPresets.Add((New-LaunchPreset 'lo_clear' 'Reset / Clear' 'Removes all custom Steam launch options for this game.' 'RESET' '' $false))
        if ($engine -match 'Source|GoldSrc') {
            [void]$loPresets.Add((New-LaunchPreset 'lo_max_fps' 'Max FPS' 'Native Source flags: -novid -nojoy -high +fps_max 0' 'MAX FPS' '-novid -nojoy -high +fps_max 0' $true))
            [void]$loPresets.Add((New-LaunchPreset 'lo_balanced' 'Balanced' 'Skip intro with high priority: -novid -high' 'BALANCED' '-novid -high' $false))
        } elseif ($engine -match 'Unity') {
            [void]$loPresets.Add((New-LaunchPreset 'lo_max_fps' 'Max FPS' 'Exclusive fullscreen and DX11 renderer: -screen-fullscreen 1 -force-d3d11' 'MAX FPS' '-screen-fullscreen 1 -force-d3d11' $true))
            [void]$loPresets.Add((New-LaunchPreset 'lo_balanced' 'Balanced' 'Forces exclusive fullscreen: -screen-fullscreen 1' 'BALANCED' '-screen-fullscreen 1' $false))
        } else {
            [void]$loPresets.Add((New-LaunchPreset 'lo_max_fps' 'Competitive Base' 'Skip intro videos and boost CPU priority: -novid -high' 'MAX FPS' '-novid -high' $true))
            [void]$loPresets.Add((New-LaunchPreset 'lo_balanced' 'Balanced' 'High priority execution: -high' 'BALANCED' '-high' $false))
        }
        $g.launchOptionPresets = @($loPresets)
    }

    $createdCount++
}

Write-Host "== Configs and presets created for $createdCount games =="

# Save Manifest
$out = [pscustomobject]@{
    version = '3.0'
    lastUpdated = (Get-Date -Format 'yyyy-MM-dd')
    games = $games
}
$json = $out | ConvertTo-Json -Depth 15
[System.IO.File]::WriteAllText($manifestPath, $json, $utf8)

Write-Host "== Manifest successfully saved with $($games.Count) games! =="
