function V {
    param(
        [double]$X,
        [double]$Y,
        [double]$Z
    )

    return @{
        X = $X
        Y = $Y
        Z = $Z
    }
}

function M {
    param(
        [double]$X,
        [double]$Y,
        [double]$Z
    )

    return @{
        X = $X / 256.0
        Y = $Y / 256.0
        Z = $Z / 256.0
    }
}

function Face {
    param(
        [int[]]$Indices,
        [string]$Material,
        [string]$Fx = '',
        [string]$TextureKey = '',
        [string]$ShadeMode = '',
        [object[]]$UV = @()
    )

    return @{
        Indices = $Indices
        Material = $Material
        Fx = $Fx
        TextureKey = $TextureKey
        ShadeMode = $ShadeMode
        UV = $UV
    }
}

@{
    Materials = @(
        @{ Key = 'panel_dark'; Base = 3; Dither = 4 }
        @{ Key = 'panel_cyan'; Base = 5; Dither = 6 }
        @{ Key = 'panel_white'; Base = 7; Dither = 6 }
        @{ Key = 'panel_amber'; Base = 8; Dither = 7 }
        @{ Key = 'panel_red'; Base = 10; Dither = 9 }
        @{ Key = 'wall_dark'; Base = 11; Dither = 12 }
        @{ Key = 'floor_dark'; Base = 13; Dither = 14 }
        @{ Key = 'gate_glow'; Base = 17; Dither = 7 }
        @{ Key = 'player_core'; Base = 15; Dither = 7 }
        @{ Key = 'player_trim'; Base = 6; Dither = 7 }
        @{ Key = 'warden_core'; Base = 10; Dither = 7 }
        @{ Key = 'warden_trim'; Base = 7; Dither = 10 }
        @{ Key = 'rusher_core'; Base = 10; Dither = 7 }
        @{ Key = 'rusher_trim'; Base = 7; Dither = 9 }
        @{ Key = 'flanker_core'; Base = 8; Dither = 7 }
        @{ Key = 'flanker_trim'; Base = 7; Dither = 8 }
        @{ Key = 'beacon_exit'; Base = 17; Dither = 7 }
        @{ Key = 'beacon_focus'; Base = 7; Dither = 6 }
        @{ Key = 'beacon_spoof'; Base = 6; Dither = 7 }
        @{ Key = 'beacon_threat'; Base = 8; Dither = 10 }
        @{ Key = 'vault_wall'; Base = 11; Dither = 6 }
        @{ Key = 'vault_trim'; Base = 6; Dither = 7 }
        @{ Key = 'furnace_wall'; Base = 10; Dither = 8 }
        @{ Key = 'furnace_trim'; Base = 8; Dither = 7 }
        @{ Key = 'lock_wall'; Base = 3; Dither = 10 }
        @{ Key = 'lock_trim'; Base = 17; Dither = 10 }
        @{ Key = 'console_cyan'; Base = 5; Dither = 7 }
        @{ Key = 'console_amber'; Base = 8; Dither = 7 }
        @{ Key = 'console_red'; Base = 10; Dither = 7 }
        @{ Key = 'metal_dark'; Base = 11; Dither = 3; TextureKey = 'metal-dark'; ShadeMode = 'affine' }
        @{ Key = 'steel_brush'; Base = 7; Dither = 4; TextureKey = 'steel-brush'; ShadeMode = 'affine' }
        @{ Key = 'concrete_noir'; Base = 3; Dither = 11; TextureKey = 'concrete-noir'; ShadeMode = 'affine' }
        @{ Key = 'grate_lane'; Base = 6; Dither = 3; TextureKey = 'grate-cyan'; ShadeMode = 'affine' }
        @{ Key = 'hazard_amber'; Base = 8; Dither = 7; TextureKey = 'hazard-amber'; ShadeMode = 'affine' }
        @{ Key = 'logo_panel'; Base = 7; Dither = 6; TextureKey = 'logo-panel'; ShadeMode = 'affine' }
        @{ Key = 'logo_dark'; Base = 3; Dither = 6; TextureKey = 'logo-panel'; ShadeMode = 'affine' }
        @{ Key = 'emissive_strip'; Base = 5; Dither = 6; TextureKey = 'emissive-strip'; ShadeMode = 'affine' }
        @{ Key = 'concrete_rain'; Base = 11; Dither = 3; TextureKey = 'concrete-rain'; ShadeMode = 'affine' }
        @{ Key = 'concrete_pit'; Base = 3; Dither = 12; TextureKey = 'concrete-pit'; ShadeMode = 'affine' }
        @{ Key = 'metal_plate'; Base = 7; Dither = 11; TextureKey = 'metal-plate'; ShadeMode = 'affine' }
        @{ Key = 'metal_oil'; Base = 3; Dither = 4; TextureKey = 'metal-oil'; ShadeMode = 'affine' }
        @{ Key = 'steel_rib'; Base = 6; Dither = 7; TextureKey = 'steel-rib'; ShadeMode = 'affine' }
        @{ Key = 'grate_deep'; Base = 11; Dither = 6; TextureKey = 'grate-deep'; ShadeMode = 'affine' }
        @{ Key = 'rail_cyan'; Base = 5; Dither = 7; TextureKey = 'rail-cyan'; ShadeMode = 'affine' }
        @{ Key = 'hazard_diag'; Base = 8; Dither = 10; TextureKey = 'hazard-diag'; ShadeMode = 'affine' }
        @{ Key = 'logo_void'; Base = 3; Dither = 11; TextureKey = 'logo-void'; ShadeMode = 'affine' }
        @{ Key = 'logo_shine'; Base = 7; Dither = 8; TextureKey = 'logo-shine'; ShadeMode = 'affine' }
        @{ Key = 'strip_hot'; Base = 8; Dither = 7; TextureKey = 'strip-hot'; ShadeMode = 'affine' }
        @{ Key = 'stone_shadow'; Base = 11; Dither = 4; TextureKey = 'stone-shadow'; ShadeMode = 'affine' }
        @{ Key = 'sky_stone'; Base = 7; Dither = 6; TextureKey = 'soft-stone'; ShadeMode = 'affine' }
        @{ Key = 'sun_warm'; Base = 8; Dither = 7; TextureKey = 'banner-warm'; ShadeMode = 'affine' }
        @{ Key = 'meadow_ground'; Base = 13; Dither = 8; TextureKey = 'grass'; ShadeMode = 'affine' }
        @{ Key = 'tree_canopy'; Base = 5; Dither = 7; TextureKey = 'leaf-canopy'; ShadeMode = 'affine' }
        @{ Key = 'tree_trunk'; Base = 8; Dither = 9; TextureKey = 'tree-bark'; ShadeMode = 'affine' }
        @{ Key = 'stone_soft'; Base = 7; Dither = 4; TextureKey = 'soft-stone'; ShadeMode = 'affine' }
        @{ Key = 'lava_hot'; Base = 9; Dither = 8; TextureKey = 'lava-hot'; ShadeMode = 'affine' }
        @{ Key = 'gem_blue'; Base = 6; Dither = 7; TextureKey = 'gem-blue'; ShadeMode = 'flat' }
        @{ Key = 'concrete_damp'; Base = 11; Dither = 4; TextureKey = 'concrete-damp'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'concrete_rib'; Base = 3; Dither = 11; TextureKey = 'concrete-rib'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'steel_truss'; Base = 7; Dither = 3; TextureKey = 'steel-truss'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'steel_catwalk'; Base = 7; Dither = 10; TextureKey = 'steel-catwalk'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'metal_duct'; Base = 11; Dither = 5; TextureKey = 'metal-duct'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'metal_grime'; Base = 3; Dither = 11; TextureKey = 'metal-grime'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'metal_furnace'; Base = 10; Dither = 4; TextureKey = 'metal-furnace'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'strip_furnace'; Base = 8; Dither = 9; TextureKey = 'strip-furnace-hot'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'vault_panel_cold'; Base = 7; Dither = 12; TextureKey = 'vault-panel-cold'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'seal_panel'; Base = 11; Dither = 7; TextureKey = 'seal-panel-cold'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'emissive_uplink'; Base = 5; Dither = 7; TextureKey = 'emissive-uplink'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'emissive_relay'; Base = 6; Dither = 7; TextureKey = 'emissive-relay'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'hazard_rung'; Base = 8; Dither = 10; TextureKey = 'hazard-rung'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'metal_slot'; Base = 7; Dither = 11; TextureKey = 'metal-slot'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'metal_under'; Base = 11; Dither = 6; TextureKey = 'metal-under'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'grate_slot'; Base = 6; Dither = 3; TextureKey = 'grate-slot'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'rail_cold'; Base = 7; Dither = 6; TextureKey = 'rail-cold'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'concrete_shadow'; Base = 11; Dither = 3; TextureKey = 'concrete-shadow'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'ceiling_rib'; Base = 7; Dither = 4; TextureKey = 'ceiling-rib'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'duct_shadow'; Base = 11; Dither = 4; TextureKey = 'duct-shadow'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'skyline_panel'; Base = 7; Dither = 11; TextureKey = 'skyline-panel'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'trench_plate'; Base = 6; Dither = 3; TextureKey = 'metal-trench-plate'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'catwalk_oil'; Base = 3; Dither = 10; TextureKey = 'catwalk-oil'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'relay_panel'; Base = 6; Dither = 7; TextureKey = 'relay-panel'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'hinge_steel'; Base = 7; Dither = 4; TextureKey = 'hinge-steel'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'trench_hot'; Base = 8; Dither = 9; TextureKey = 'trench-hot'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'vault_rib'; Base = 7; Dither = 12; TextureKey = 'vault-rib-cold'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'seal_rib'; Base = 11; Dither = 7; TextureKey = 'seal-rib-cold'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'occluder_dark'; Base = 3; Dither = 11; TextureKey = 'metal-occluder-dark'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'furnace_soot'; Base = 10; Dither = 4; TextureKey = 'furnace-soot'; TexturePage = 'B'; ShadeMode = 'affine' }
        @{ Key = 'uplink_panel'; Base = 7; Dither = 6; TextureKey = 'uplink-panel-cold'; TexturePage = 'B'; ShadeMode = 'affine' }
    )
    Scenes = @(
        @{
            Key = 'splash'
            TimelineTicks = 96
            Camera = @{
                X = 0.0
                Y = 1.0
                Z = -12.6
                YawDegrees = -2.0
                YawStepDegrees = 0.09
                PitchDegrees = -11.0
                PitchStepDegrees = 0.04
                ProjectScale = 124
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Groups = @(
                @{
                    Key = 'floor_shell'
                    StartTick = 0
                    EndTick = 95
                    MotionTicks = 0
                    Vertices = @(
                        (V -15.0 -1.55 4.2), (V -9.2 -1.55 4.2), (V -8.3 -1.85 12.2), (V -13.9 -1.85 12.2),
                        (V -13.9 -1.85 12.2), (V -8.3 -1.85 12.2), (V -6.1 -2.0 25.8), (V -12.3 -2.0 25.8),
                        (V 9.2 -1.55 4.2), (V 15.0 -1.55 4.2), (V 13.9 -1.85 12.2), (V 8.3 -1.85 12.2),
                        (V 8.3 -1.85 12.2), (V 13.9 -1.85 12.2), (V 12.3 -2.0 25.8), (V 6.1 -2.0 25.8),
                        (V -8.4 -1.75 4.6), (V -4.9 -1.75 4.6), (V -3.6 -2.55 24.8), (V -6.1 -2.0 24.8),
                        (V 4.9 -1.75 4.6), (V 8.4 -1.75 4.6), (V 6.1 -2.0 24.8), (V 3.6 -2.55 24.8),
                        (V -13.2 -0.2 20.8), (V -8.2 -0.2 20.8), (V -7.2 1.3 27.8), (V -12.0 1.3 27.8),
                        (V 8.2 -0.2 20.8), (V 13.2 -0.2 20.8), (V 12.0 1.3 27.8), (V 7.2 1.3 27.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'concrete_noir'),
                        (Face @(4, 5, 6, 7) 'concrete_rain'),
                        (Face @(8, 9, 10, 11) 'concrete_noir'),
                        (Face @(12, 13, 14, 15) 'concrete_rain'),
                        (Face @(16, 17, 18, 19) 'metal_oil'),
                        (Face @(20, 21, 22, 23) 'metal_oil'),
                        (Face @(24, 25, 26, 27) 'stone_shadow'),
                        (Face @(28, 29, 30, 31) 'stone_shadow')
                    )
                }
                @{
                    Key = 'canal_core'
                    StartTick = 0
                    EndTick = 95
                    MotionTicks = 0
                    Vertices = @(
                        (V -4.4 -2.45 5.0), (V 4.4 -2.45 5.0), (V 3.2 -3.2 13.6), (V -3.2 -3.2 13.6),
                        (V -3.2 -3.2 13.6), (V 3.2 -3.2 13.6), (V 2.4 -3.5 25.8), (V -2.4 -3.5 25.8),
                        (V -4.8 -1.7 4.9), (V -3.4 -1.7 4.9), (V -2.5 -3.15 25.8), (V -3.7 -3.15 25.8),
                        (V 3.4 -1.7 4.9), (V 4.8 -1.7 4.9), (V 3.7 -3.15 25.8), (V 2.5 -3.15 25.8),
                        (V -3.0 -3.0 24.9), (V 3.0 -3.0 24.9), (V 2.6 -1.25 28.2), (V -2.6 -1.25 28.2),
                        (V -0.95 -2.28 7.6), (V 0.95 -2.28 7.6), (V 0.55 -3.16 25.0), (V -0.55 -3.16 25.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'grate_deep'),
                        (Face @(4, 5, 6, 7) 'metal_dark'),
                        (Face @(8, 9, 10, 11) 'metal_plate'),
                        (Face @(12, 13, 14, 15) 'metal_plate'),
                        (Face @(16, 17, 18, 19) 'logo_void'),
                        (Face @(20, 21, 22, 23) 'rail_cyan' 'pulse_cyan')
                    )
                }
                @{
                    Key = 'rail_lights'
                    StartTick = 0
                    EndTick = 95
                    MotionTicks = 0
                    Vertices = @(
                        (V -3.45 -2.1 5.4), (V -2.6 -2.1 5.4), (V -1.6 -2.7 25.0), (V -2.3 -2.7 25.0),
                        (V 2.6 -2.1 5.4), (V 3.45 -2.1 5.4), (V 2.3 -2.7 25.0), (V 1.6 -2.7 25.0),
                        (V -0.8 -2.22 8.0), (V 0.8 -2.22 8.0), (V 0.42 -3.02 25.1), (V -0.42 -3.02 25.1),
                        (V -4.45 -1.85 6.2), (V -3.8 -1.85 6.2), (V -2.9 -2.35 25.0), (V -3.45 -2.35 25.0),
                        (V 3.8 -1.85 6.2), (V 4.45 -1.85 6.2), (V 3.45 -2.35 25.0), (V 2.9 -2.35 25.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'rail_cyan' 'pulse_cyan'),
                        (Face @(4, 5, 6, 7) 'rail_cyan' 'pulse_cyan'),
                        (Face @(8, 9, 10, 11) 'strip_hot' 'pulse_amber'),
                        (Face @(12, 13, 14, 15) 'panel_white' 'glint'),
                        (Face @(16, 17, 18, 19) 'panel_white' 'glint')
                    )
                }
                @{
                    Key = 'left_monolith'
                    StartTick = 10
                    EndTick = 95
                    MotionTicks = 12
                    Offset = @{ X = -0.65; Y = -1.0; Z = 0.45 }
                    OffsetStep = @{ X = 0.05; Y = 0.08; Z = -0.03 }
                    YawDegrees = -4.0
                    YawStepDegrees = 0.08
                    Vertices = @(
                        (V -12.0 -1.95 6.8), (V -8.1 -1.95 6.8), (V -7.6 4.9 20.8), (V -10.9 5.1 20.8),
                        (V -11.3 -1.7 8.4), (V -8.8 -1.7 8.4), (V -8.4 3.6 19.0), (V -10.6 3.8 19.0),
                        (V -12.6 5.1 17.8), (V -11.1 6.4 21.8), (V -7.8 6.4 21.8), (V -6.4 5.1 17.8),
                        (V -12.1 -1.2 11.2), (V -10.9 -1.2 11.2), (V -10.0 4.0 18.6), (V -11.2 4.0 18.6),
                        (V -8.7 -0.6 10.8), (V -7.4 -0.6 10.8), (V -6.8 2.8 17.4), (V -8.1 2.8 17.4)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'concrete_pit'),
                        (Face @(4, 5, 6, 7) 'concrete_rain'),
                        (Face @(8, 9, 10, 11) 'metal_plate'),
                        (Face @(12, 13, 14, 15) 'metal_oil'),
                        (Face @(16, 17, 18, 19) 'steel_rib')
                    )
                }
                @{
                    Key = 'right_monolith'
                    StartTick = 12
                    EndTick = 95
                    MotionTicks = 12
                    Offset = @{ X = 0.65; Y = -1.0; Z = 0.45 }
                    OffsetStep = @{ X = -0.05; Y = 0.08; Z = -0.03 }
                    YawDegrees = 4.0
                    YawStepDegrees = -0.08
                    Vertices = @(
                        (V 8.1 -1.95 6.8), (V 12.0 -1.95 6.8), (V 10.9 5.1 20.8), (V 7.6 4.9 20.8),
                        (V 8.8 -1.7 8.4), (V 11.3 -1.7 8.4), (V 10.6 3.8 19.0), (V 8.4 3.6 19.0),
                        (V 6.4 5.1 17.8), (V 7.8 6.4 21.8), (V 11.1 6.4 21.8), (V 12.6 5.1 17.8),
                        (V 10.9 -1.2 11.2), (V 12.1 -1.2 11.2), (V 11.2 4.0 18.6), (V 10.0 4.0 18.6),
                        (V 7.4 -0.6 10.8), (V 8.7 -0.6 10.8), (V 8.1 2.8 17.4), (V 6.8 2.8 17.4)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'concrete_pit'),
                        (Face @(4, 5, 6, 7) 'concrete_rain'),
                        (Face @(8, 9, 10, 11) 'metal_plate'),
                        (Face @(12, 13, 14, 15) 'metal_oil'),
                        (Face @(16, 17, 18, 19) 'steel_rib')
                    )
                }
                @{
                    Key = 'monolith_insets'
                    StartTick = 12
                    EndTick = 95
                    MotionTicks = 10
                    Offset = @{ X = 0.0; Y = -0.7; Z = 0.28 }
                    OffsetStep = @{ X = 0.0; Y = 0.06; Z = -0.02 }
                    Vertices = @(
                        (V -10.3 -0.4 9.9), (V -9.0 -0.4 9.9), (V -8.7 2.8 17.8), (V -9.9 2.8 17.8),
                        (V -10.7 1.2 12.8), (V -9.4 1.2 12.8), (V -9.1 4.2 18.9), (V -10.3 4.2 18.9),
                        (V 9.0 -0.4 9.9), (V 10.3 -0.4 9.9), (V 9.9 2.8 17.8), (V 8.7 2.8 17.8),
                        (V 9.4 1.2 12.8), (V 10.7 1.2 12.8), (V 10.3 4.2 18.9), (V 9.1 4.2 18.9)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'emissive_strip' 'pulse_cyan'),
                        (Face @(4, 5, 6, 7) 'hazard_diag' 'pulse_amber'),
                        (Face @(8, 9, 10, 11) 'emissive_strip' 'pulse_cyan'),
                        (Face @(12, 13, 14, 15) 'hazard_diag' 'pulse_amber')
                    )
                }
                @{
                    Key = 'rear_gate'
                    StartTick = 34
                    EndTick = 95
                    MotionTicks = 16
                    Offset = @{ X = 0.0; Y = -0.5; Z = 0.65 }
                    OffsetStep = @{ X = 0.0; Y = 0.03; Z = -0.03 }
                    Vertices = @(
                        (V -8.9 3.2 16.0), (V 8.9 3.2 16.0), (V 7.4 4.4 21.2), (V -7.4 4.4 21.2),
                        (V -10.1 -0.8 15.2), (V -8.0 -0.8 15.2), (V -7.0 3.1 20.8), (V -8.9 3.1 20.8),
                        (V 8.0 -0.8 15.2), (V 10.1 -0.8 15.2), (V 8.9 3.1 20.8), (V 7.0 3.1 20.8),
                        (V -6.0 0.4 18.0), (V 6.0 0.4 18.0), (V 5.1 1.2 22.4), (V -5.1 1.2 22.4),
                        (V -4.4 0.8 20.2), (V 4.4 0.8 20.2), (V 3.7 2.0 23.4), (V -3.7 2.0 23.4),
                        (V -1.8 1.4 21.4), (V 1.8 1.4 21.4), (V 1.4 2.4 23.8), (V -1.4 2.4 23.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'steel_rib'),
                        (Face @(4, 5, 6, 7) 'metal_oil'),
                        (Face @(8, 9, 10, 11) 'metal_oil'),
                        (Face @(12, 13, 14, 15) 'logo_void'),
                        (Face @(16, 17, 18, 19) 'logo_shine' 'glint'),
                        (Face @(20, 21, 22, 23) 'panel_white' 'glint')
                    )
                }
                @{
                    Key = 'emblem_left'
                    StartTick = 20
                    EndTick = 95
                    MotionTicks = 16
                    Offset = @{ X = -0.15; Y = -1.3; Z = 0.8 }
                    OffsetStep = @{ X = 0.02; Y = 0.08; Z = -0.04 }
                    YawDegrees = -3.0
                    YawStepDegrees = 0.08
                    Vertices = @(
                        (V -5.6 -1.1 10.0), (V -3.2 -1.1 9.0), (V -1.2 2.9 12.9), (V -2.8 3.3 14.8),
                        (V -5.1 -0.2 10.9), (V -3.8 -0.2 10.4), (V -2.0 2.2 13.0), (V -3.2 2.5 14.2),
                        (V -4.7 0.7 11.8), (V -3.6 0.7 11.4), (V -2.4 2.3 13.4), (V -3.5 2.6 14.1),
                        (V -4.1 1.6 12.7), (V -3.1 1.6 12.3), (V -2.1 2.5 13.9), (V -3.0 2.7 14.6),
                        (V -2.9 -0.8 9.8), (V -2.0 -0.8 9.4), (V -1.2 2.3 13.2), (V -1.9 2.5 13.9)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'logo_panel'),
                        (Face @(4, 5, 6, 7) 'logo_dark'),
                        (Face @(8, 9, 10, 11) 'logo_shine' 'glint'),
                        (Face @(12, 13, 14, 15) 'logo_void'),
                        (Face @(16, 17, 18, 19) 'strip_hot' 'pulse_amber')
                    )
                }
                @{
                    Key = 'emblem_right'
                    StartTick = 22
                    EndTick = 95
                    MotionTicks = 16
                    Offset = @{ X = 0.15; Y = -1.3; Z = 0.8 }
                    OffsetStep = @{ X = -0.02; Y = 0.08; Z = -0.04 }
                    YawDegrees = 3.0
                    YawStepDegrees = -0.08
                    Vertices = @(
                        (V 3.2 -1.1 9.0), (V 5.6 -1.1 10.0), (V 2.8 3.3 14.8), (V 1.2 2.9 12.9),
                        (V 3.8 -0.2 10.4), (V 5.1 -0.2 10.9), (V 3.2 2.5 14.2), (V 2.0 2.2 13.0),
                        (V 3.6 0.7 11.4), (V 4.7 0.7 11.8), (V 3.5 2.6 14.1), (V 2.4 2.3 13.4),
                        (V 3.1 1.6 12.3), (V 4.1 1.6 12.7), (V 3.0 2.7 14.6), (V 2.1 2.5 13.9),
                        (V 2.0 -0.8 9.4), (V 2.9 -0.8 9.8), (V 1.9 2.5 13.9), (V 1.2 2.3 13.2)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'logo_panel'),
                        (Face @(4, 5, 6, 7) 'logo_dark'),
                        (Face @(8, 9, 10, 11) 'logo_shine' 'glint'),
                        (Face @(12, 13, 14, 15) 'logo_void'),
                        (Face @(16, 17, 18, 19) 'strip_hot' 'pulse_amber')
                    )
                }
                @{
                    Key = 'emblem_core'
                    StartTick = 26
                    EndTick = 95
                    MotionTicks = 12
                    Offset = @{ X = 0.0; Y = -1.1; Z = 0.6 }
                    OffsetStep = @{ X = 0.0; Y = 0.07; Z = -0.03 }
                    Vertices = @(
                        (V -0.7 -0.8 9.6), (V 0.7 -0.8 9.6), (V 0.4 2.5 13.9), (V -0.4 2.5 13.9),
                        (V -0.35 -0.2 10.6), (V 0.35 -0.2 10.6), (V 0.2 2.1 13.5), (V -0.2 2.1 13.5)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_amber' 'pulse_amber'),
                        (Face @(4, 5, 6, 7) 'logo_shine' 'glint')
                    )
                }
                @{
                    Key = 'halo'
                    StartTick = 38
                    EndTick = 95
                    MotionTicks = 14
                    Offset = @{ X = 0.0; Y = -0.38; Z = 0.42 }
                    OffsetStep = @{ X = 0.0; Y = 0.03; Z = -0.02 }
                    Vertices = @(
                        (V -7.2 4.0 15.8), (V 7.2 4.0 15.8), (V 6.0 4.9 18.8), (V -6.0 4.9 18.8),
                        (V -7.8 -0.8 15.0), (V -6.2 -0.8 15.0), (V -5.3 4.1 18.5), (V -6.8 4.1 18.5),
                        (V 6.2 -0.8 15.0), (V 7.8 -0.8 15.0), (V 6.8 4.1 18.5), (V 5.3 4.1 18.5),
                        (V -5.8 0.2 16.8), (V 5.8 0.2 16.8), (V 5.1 1.0 18.8), (V -5.1 1.0 18.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint'),
                        (Face @(4, 5, 6, 7) 'hazard_amber'),
                        (Face @(8, 9, 10, 11) 'hazard_amber'),
                        (Face @(12, 13, 14, 15) 'rail_cyan' 'pulse_cyan')
                    )
                }
            )
        }
        @{
            Key = 'title'
            TimelineTicks = 64
            LoopTicks = 64
            Camera = @{
                X = 0.0
                Y = 0.95
                Z = -10.6
                YawDegrees = 3.0
                YawStepDegrees = -0.12
                PitchDegrees = -8.5
                PitchStepDegrees = 0.0
                ProjectScale = 114
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Groups = @(
                @{
                    Key = 'floor_shell'
                    StartTick = 0
                    EndTick = 63
                    MotionTicks = 0
                    Vertices = @(
                        (V -14.0 -1.55 4.0), (V -8.0 -1.55 4.0), (V -7.1 -1.82 12.0), (V -12.8 -1.82 12.0),
                        (V -12.8 -1.82 12.0), (V -7.1 -1.82 12.0), (V -5.6 -1.98 22.6), (V -11.4 -1.98 22.6),
                        (V 8.0 -1.55 4.0), (V 14.0 -1.55 4.0), (V 12.8 -1.82 12.0), (V 7.1 -1.82 12.0),
                        (V 7.1 -1.82 12.0), (V 12.8 -1.82 12.0), (V 11.4 -1.98 22.6), (V 5.6 -1.98 22.6),
                        (V -7.2 -1.72 4.4), (V -4.7 -1.72 4.4), (V -3.5 -2.45 22.0), (V -5.7 -1.96 22.0),
                        (V 4.7 -1.72 4.4), (V 7.2 -1.72 4.4), (V 5.7 -1.96 22.0), (V 3.5 -2.45 22.0),
                        (V -11.8 -0.35 18.0), (V -7.5 -0.35 18.0), (V -6.5 1.0 24.8), (V -10.7 1.0 24.8),
                        (V 7.5 -0.35 18.0), (V 11.8 -0.35 18.0), (V 10.7 1.0 24.8), (V 6.5 1.0 24.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'concrete_noir'),
                        (Face @(4, 5, 6, 7) 'concrete_rain'),
                        (Face @(8, 9, 10, 11) 'concrete_noir'),
                        (Face @(12, 13, 14, 15) 'concrete_rain'),
                        (Face @(16, 17, 18, 19) 'metal_oil'),
                        (Face @(20, 21, 22, 23) 'metal_oil'),
                        (Face @(24, 25, 26, 27) 'stone_shadow'),
                        (Face @(28, 29, 30, 31) 'stone_shadow')
                    )
                }
                @{
                    Key = 'canal_core'
                    StartTick = 0
                    EndTick = 63
                    MotionTicks = 0
                    Vertices = @(
                        (V -4.2 -2.3 5.2), (V 4.2 -2.3 5.2), (V 3.2 -3.0 13.8), (V -3.2 -3.0 13.8),
                        (V -3.2 -3.0 13.8), (V 3.2 -3.0 13.8), (V 2.5 -3.3 23.0), (V -2.5 -3.3 23.0),
                        (V -4.5 -1.72 5.0), (V -3.2 -1.72 5.0), (V -2.5 -3.0 23.0), (V -3.6 -3.0 23.0),
                        (V 3.2 -1.72 5.0), (V 4.5 -1.72 5.0), (V 3.6 -3.0 23.0), (V 2.5 -3.0 23.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'grate_deep'),
                        (Face @(4, 5, 6, 7) 'metal_dark'),
                        (Face @(8, 9, 10, 11) 'metal_plate'),
                        (Face @(12, 13, 14, 15) 'metal_plate')
                    )
                }
                @{
                    Key = 'left_mass'
                    StartTick = 0
                    EndTick = 63
                    MotionTicks = 12
                    Offset = @{ X = 0.0; Y = -0.18; Z = 0.16 }
                    OffsetStep = @{ X = 0.0; Y = 0.012; Z = -0.008 }
                    Vertices = @(
                        (V -12.6 -1.35 6.0), (V -9.0 -1.35 6.0), (V -8.2 4.6 17.6), (V -11.2 4.6 17.6),
                        (V -11.1 -0.4 7.9), (V -9.7 -0.4 7.9), (V -9.0 3.2 15.6), (V -10.4 3.2 15.6),
                        (V -10.4 0.5 11.4), (V -8.6 0.5 11.4), (V -7.9 2.2 18.6), (V -9.8 2.2 18.6),
                        (V -8.8 1.8 18.0), (V -6.8 1.8 18.0), (V -6.1 3.0 23.4), (V -8.1 3.0 23.4),
                        (V -10.6 5.0 18.2), (V -8.2 5.0 18.2), (V -7.2 6.2 21.8), (V -9.6 6.2 21.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'concrete_pit'),
                        (Face @(4, 5, 6, 7) 'concrete_rain'),
                        (Face @(8, 9, 10, 11) 'steel_rib'),
                        (Face @(12, 13, 14, 15) 'metal_plate'),
                        (Face @(16, 17, 18, 19) 'stone_shadow')
                    )
                }
                @{
                    Key = 'right_mass'
                    StartTick = 12
                    EndTick = 63
                    MotionTicks = 8
                    Offset = @{ X = 0.0; Y = -0.15; Z = 0.25 }
                    OffsetStep = @{ X = 0.0; Y = 0.018; Z = -0.012 }
                    Vertices = @(
                        (V 9.0 -1.35 6.0), (V 12.6 -1.35 6.0), (V 11.2 4.6 17.6), (V 8.2 4.6 17.6),
                        (V 9.7 -0.4 7.9), (V 11.1 -0.4 7.9), (V 10.4 3.2 15.6), (V 9.0 3.2 15.6),
                        (V 8.6 0.5 11.4), (V 10.4 0.5 11.4), (V 9.8 2.2 18.6), (V 7.9 2.2 18.6),
                        (V 6.8 1.8 18.0), (V 8.8 1.8 18.0), (V 8.1 3.0 23.4), (V 6.1 3.0 23.4),
                        (V 8.2 5.0 18.2), (V 10.6 5.0 18.2), (V 9.6 6.2 21.8), (V 7.2 6.2 21.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'concrete_pit'),
                        (Face @(4, 5, 6, 7) 'concrete_rain'),
                        (Face @(8, 9, 10, 11) 'steel_rib'),
                        (Face @(12, 13, 14, 15) 'metal_plate'),
                        (Face @(16, 17, 18, 19) 'stone_shadow')
                    )
                }
                @{
                    Key = 'gate_frame'
                    StartTick = 8
                    EndTick = 63
                    MotionTicks = 12
                    Offset = @{ X = 0.0; Y = -0.2; Z = 0.28 }
                    OffsetStep = @{ X = 0.0; Y = 0.016; Z = -0.012 }
                    Vertices = @(
                        (V -8.8 3.2 16.0), (V 8.8 3.2 16.0), (V 7.2 4.4 21.0), (V -7.2 4.4 21.0),
                        (V -9.8 -0.8 15.0), (V -7.8 -0.8 15.0), (V -6.8 3.2 20.5), (V -8.6 3.2 20.5),
                        (V 7.8 -0.8 15.0), (V 9.8 -0.8 15.0), (V 8.6 3.2 20.5), (V 6.8 3.2 20.5),
                        (V -5.8 0.4 18.0), (V 5.8 0.4 18.0), (V 5.0 1.2 22.2), (V -5.0 1.2 22.2),
                        (V -4.2 1.0 20.2), (V 4.2 1.0 20.2), (V 3.4 2.2 23.2), (V -3.4 2.2 23.2),
                        (V -7.0 -0.1 21.4), (V -4.9 -0.1 21.4), (V -4.1 2.4 24.2), (V -6.2 2.4 24.2)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint'),
                        (Face @(4, 5, 6, 7) 'hazard_diag' 'pulse_amber'),
                        (Face @(8, 9, 10, 11) 'hazard_diag' 'pulse_amber'),
                        (Face @(12, 13, 14, 15) 'steel_rib'),
                        (Face @(16, 17, 18, 19) 'logo_void'),
                        (Face @(20, 21, 22, 23) 'logo_shine' 'glint')
                    )
                }
                @{
                    Key = 'rear_ribs'
                    StartTick = 10
                    EndTick = 63
                    MotionTicks = 8
                    Offset = @{ X = 0.0; Y = -0.1; Z = 0.18 }
                    OffsetStep = @{ X = 0.0; Y = 0.012; Z = -0.008 }
                    Vertices = @(
                        (V -9.1 0.8 18.6), (V -6.5 0.8 18.6), (V -5.2 3.4 24.6), (V -7.9 3.4 24.6),
                        (V 6.5 0.8 18.6), (V 9.1 0.8 18.6), (V 7.9 3.4 24.6), (V 5.2 3.4 24.6),
                        (V -4.9 1.0 17.8), (V 4.9 1.0 17.8), (V 4.0 2.6 24.2), (V -4.0 2.6 24.2),
                        (V -2.6 2.5 19.4), (V 2.6 2.5 19.4), (V 2.1 3.2 23.6), (V -2.1 3.2 23.6)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'metal_oil'),
                        (Face @(4, 5, 6, 7) 'metal_oil'),
                        (Face @(8, 9, 10, 11) 'steel_brush'),
                        (Face @(12, 13, 14, 15) 'panel_white' 'glint')
                    )
                }
                @{
                    Key = 'scan_bridge'
                    StartTick = 14
                    EndTick = 63
                    MotionTicks = 8
                    Offset = @{ X = 0.0; Y = -0.1; Z = 0.16 }
                    OffsetStep = @{ X = 0.0; Y = 0.01; Z = -0.006 }
                    Vertices = @(
                        (V -5.8 1.1 9.0), (V 5.8 1.1 9.0), (V 4.4 2.0 15.4), (V -4.4 2.0 15.4),
                        (V -3.3 0.4 10.8), (V 3.3 0.4 10.8), (V 2.6 1.1 13.8), (V -2.6 1.1 13.8),
                        (V -1.9 2.6 16.9), (V 1.9 2.6 16.9), (V 1.4 3.0 18.0), (V -1.4 3.0 18.0),
                        (V -4.4 -1.95 5.2), (V -3.7 -1.95 5.2), (V -2.7 -2.2 19.6), (V -3.3 -2.2 19.6)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'rail_cyan' 'pulse_cyan'),
                        (Face @(4, 5, 6, 7) 'panel_amber' 'pulse_amber'),
                        (Face @(8, 9, 10, 11) 'panel_white' 'glint'),
                        (Face @(12, 13, 14, 15) 'panel_white' 'glint')
                    )
                }
                @{
                    Key = 'halo'
                    StartTick = 18
                    EndTick = 63
                    MotionTicks = 10
                    Offset = @{ X = 0.0; Y = -0.12; Z = 0.16 }
                    OffsetStep = @{ X = 0.0; Y = 0.01; Z = -0.006 }
                    Vertices = @(
                        (V -6.4 3.9 15.8), (V 6.4 3.9 15.8), (V 5.4 4.7 18.8), (V -5.4 4.7 18.8),
                        (V -6.9 -0.6 15.0), (V -5.5 -0.6 15.0), (V -4.8 3.8 18.2), (V -6.1 3.8 18.2),
                        (V 5.5 -0.6 15.0), (V 6.9 -0.6 15.0), (V 6.1 3.8 18.2), (V 4.8 3.8 18.2),
                        (V -5.2 0.2 16.8), (V 5.2 0.2 16.8), (V 4.5 0.9 18.8), (V -4.5 0.9 18.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint'),
                        (Face @(4, 5, 6, 7) 'hazard_amber'),
                        (Face @(8, 9, 10, 11) 'hazard_amber'),
                        (Face @(12, 13, 14, 15) 'rail_cyan' 'pulse_cyan')
                    )
                }
            )
        }
        @{
            Key = 'sector1'
            TimelineTicks = 8
            Camera = @{
                X = 0.0
                Y = 0.7
                Z = -5.6
                YawDegrees = -10.0
                YawStepDegrees = 0.25
                PitchDegrees = -10.0
                PitchStepDegrees = 0.0
                ProjectScale = 98
                Viewport = @{ X = 56; Y = 42; W = 152; H = 64 }
            }
            Groups = @(
                @{
                    Key = 'deck'
                    StartTick = 0
                    EndTick = 7
                    MotionTicks = 0
                    Vertices = @(
                        (V -5.5 -1.0 3.0), (V 5.5 -1.0 3.0), (V 3.6 -1.0 10.0), (V -3.6 -1.0 10.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark')
                    )
                }
                @{
                    Key = 'vault'
                    StartTick = 1
                    EndTick = 7
                    MotionTicks = 3
                    Offset = @{ X = 0.0; Y = -0.18; Z = 0.35 }
                    OffsetStep = @{ X = 0.0; Y = 0.05; Z = -0.05 }
                    Vertices = @(
                        (V -2.7 -0.1 5.6), (V 2.7 -0.1 5.6), (V 1.8 1.5 8.8), (V -1.8 1.5 8.8),
                        (V -4.2 0.4 6.6), (V -3.2 2.0 8.8), (V 4.2 0.4 6.6), (V 3.2 2.0 8.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_cyan' 'pulse_cyan'),
                        (Face @(4, 5, 3, 0) 'panel_white')
                    )
                }
                @{
                    Key = 'trace'
                    StartTick = 3
                    EndTick = 7
                    MotionTicks = 2
                    Offset = @{ X = 0.0; Y = -0.08; Z = 0.2 }
                    OffsetStep = @{ X = 0.0; Y = 0.04; Z = -0.03 }
                    Vertices = @(
                        (V 2.7 -0.1 5.6), (V 4.2 0.4 6.6), (V 3.2 2.0 8.8), (V 1.8 1.5 8.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_amber' 'pulse_amber')
                    )
                }
            )
        }
        @{
            Key = 'sector2'
            TimelineTicks = 8
            Camera = @{
                X = 0.0
                Y = 0.7
                Z = -5.6
                YawDegrees = 10.0
                YawStepDegrees = -0.2
                PitchDegrees = -9.0
                PitchStepDegrees = 0.0
                ProjectScale = 98
                Viewport = @{ X = 56; Y = 42; W = 152; H = 64 }
            }
            Groups = @(
                @{
                    Key = 'deck'
                    StartTick = 0
                    EndTick = 7
                    MotionTicks = 0
                    Vertices = @(
                        (V -5.6 -1.0 3.0), (V 5.6 -1.0 3.0), (V 3.7 -1.0 10.0), (V -3.7 -1.0 10.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark')
                    )
                }
                @{
                    Key = 'furnace'
                    StartTick = 1
                    EndTick = 7
                    MotionTicks = 3
                    Offset = @{ X = 0.0; Y = -0.16; Z = 0.28 }
                    OffsetStep = @{ X = 0.0; Y = 0.04; Z = -0.045 }
                    YawDegrees = 4.0
                    YawStepDegrees = -0.15
                    Vertices = @(
                        (V -4.8 -0.3 4.8), (V -3.5 1.7 7.6), (V -0.9 1.2 9.8), (V -2.1 -0.3 8.5),
                        (V 4.8 -0.3 4.8), (V 3.5 1.7 7.6), (V 0.9 1.2 9.8), (V 2.1 -0.3 8.5)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_red'),
                        (Face @(4, 5, 6, 7) 'panel_amber' 'pulse_amber')
                    )
                }
                @{
                    Key = 'vent'
                    StartTick = 3
                    EndTick = 7
                    MotionTicks = 2
                    Offset = @{ X = 0.0; Y = -0.06; Z = 0.16 }
                    OffsetStep = @{ X = 0.0; Y = 0.03; Z = -0.02 }
                    Vertices = @(
                        (V -2.1 -0.3 8.5), (V 2.1 -0.3 8.5), (V 0.9 1.2 9.8), (V -0.9 1.2 9.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_dark')
                    )
                }
            )
        }
        @{
            Key = 'sector3'
            TimelineTicks = 8
            Camera = @{
                X = 0.0
                Y = 0.75
                Z = -5.8
                YawDegrees = 0.0
                YawStepDegrees = 0.22
                PitchDegrees = -9.0
                PitchStepDegrees = 0.0
                ProjectScale = 102
                Viewport = @{ X = 56; Y = 42; W = 152; H = 64 }
            }
            Groups = @(
                @{
                    Key = 'deck'
                    StartTick = 0
                    EndTick = 7
                    MotionTicks = 0
                    Vertices = @(
                        (V -5.8 -1.0 3.0), (V 5.8 -1.0 3.0), (V 3.9 -1.0 10.4), (V -3.9 -1.0 10.4)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark')
                    )
                }
                @{
                    Key = 'lock'
                    StartTick = 1
                    EndTick = 7
                    MotionTicks = 3
                    Offset = @{ X = 0.0; Y = -0.22; Z = 0.34 }
                    OffsetStep = @{ X = 0.0; Y = 0.05; Z = -0.045 }
                    Vertices = @(
                        (V -1.7 -0.3 5.8), (V 1.7 -0.3 5.8), (V 1.2 2.1 8.8), (V -1.2 2.1 8.8),
                        (V -4.9 0.2 7.2), (V -4.2 2.3 9.6), (V 4.9 0.2 7.2), (V 4.2 2.3 9.6)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'gate_glow'),
                        (Face @(4, 5, 3, 0) 'panel_red')
                    )
                }
                @{
                    Key = 'gate'
                    StartTick = 3
                    EndTick = 7
                    MotionTicks = 2
                    Offset = @{ X = 0.0; Y = -0.08; Z = 0.18 }
                    OffsetStep = @{ X = 0.0; Y = 0.03; Z = -0.02 }
                    Vertices = @(
                        (V 1.7 -0.3 5.8), (V 4.9 0.2 7.2), (V 4.2 2.3 9.6), (V 1.2 2.1 8.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint')
                    )
                }
            )
        }
        @{
            Key = 'win'
            TimelineTicks = 24
            Camera = @{
                X = 0.0
                Y = 1.0
                Z = -7.0
                YawDegrees = -6.0
                YawStepDegrees = 0.16
                PitchDegrees = -12.0
                PitchStepDegrees = 0.0
                ProjectScale = 104
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Groups = @(
                @{
                    Key = 'deck'
                    StartTick = 0
                    EndTick = 23
                    MotionTicks = 0
                    Vertices = @(
                        (V -9.8 -1.4 3.0), (V 9.8 -1.4 3.0), (V 7.0 -1.4 17.0), (V -7.0 -1.4 17.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark')
                    )
                }
                @{
                    Key = 'gate'
                    StartTick = 2
                    EndTick = 23
                    MotionTicks = 8
                    Offset = @{ X = 0.0; Y = -0.4; Z = 0.75 }
                    OffsetStep = @{ X = 0.0; Y = 0.04; Z = -0.03 }
                    Vertices = @(
                        (V -4.3 -0.8 7.8), (V 4.3 -0.8 7.8), (V 2.8 2.0 12.4), (V -2.8 2.0 12.4),
                        (V -7.0 -0.4 11.2), (V -5.8 2.2 13.8), (V 7.0 -0.4 11.2), (V 5.8 2.2 13.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'gate_glow'),
                        (Face @(4, 5, 3, 0) 'panel_cyan' 'pulse_cyan')
                    )
                }
                @{
                    Key = 'crown'
                    StartTick = 8
                    EndTick = 23
                    MotionTicks = 6
                    Offset = @{ X = 0.0; Y = -0.18; Z = 0.28 }
                    OffsetStep = @{ X = 0.0; Y = 0.025; Z = -0.015 }
                    Vertices = @(
                        (V -2.8 1.6 12.2), (V 2.8 1.6 12.2), (V 2.2 2.7 13.6), (V -2.2 2.7 13.6)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint')
                    )
                }
            )
        }
        @{
            Key = 'lose'
            TimelineTicks = 24
            Camera = @{
                X = 0.0
                Y = 1.0
                Z = -7.0
                YawDegrees = 6.0
                YawStepDegrees = -0.16
                PitchDegrees = -12.0
                PitchStepDegrees = 0.0
                ProjectScale = 104
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Groups = @(
                @{
                    Key = 'deck'
                    StartTick = 0
                    EndTick = 23
                    MotionTicks = 0
                    Vertices = @(
                        (V -9.8 -1.4 3.0), (V 9.8 -1.4 3.0), (V 7.0 -1.4 17.0), (V -7.0 -1.4 17.0)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark')
                    )
                }
                @{
                    Key = 'breach'
                    StartTick = 2
                    EndTick = 23
                    MotionTicks = 8
                    Offset = @{ X = 0.0; Y = -0.42; Z = 0.8 }
                    OffsetStep = @{ X = 0.0; Y = 0.04; Z = -0.03 }
                    Vertices = @(
                        (V -4.3 -0.8 7.8), (V 4.3 -0.8 7.8), (V 2.8 2.0 12.4), (V -2.8 2.0 12.4),
                        (V -7.0 -0.4 11.2), (V -5.8 2.2 13.8), (V 7.0 -0.4 11.2), (V 5.8 2.2 13.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_red'),
                        (Face @(4, 5, 3, 0) 'panel_dark')
                    )
                }
                @{
                    Key = 'trace'
                    StartTick = 8
                    EndTick = 23
                    MotionTicks = 6
                    Offset = @{ X = 0.0; Y = -0.16; Z = 0.24 }
                    OffsetStep = @{ X = 0.0; Y = 0.024; Z = -0.015 }
                    Vertices = @(
                        (V 4.3 -0.8 7.8), (V 7.0 -0.4 11.2), (V 5.8 2.2 13.8), (V 2.8 2.0 12.4)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint')
                    )
                }
            )
        }
    )
    GameplayKits = @(
        @{
            Key = 'sector1'
            FloorBase = 'concrete_damp'
            FloorTrim = 'trench_plate'
            WallBase = 'concrete_rib'
            WallTrim = 'ceiling_rib'
            WallCap = 'relay_panel'
            Lane = 'rail_cyan'
            GateMesh = 'gate_subgrid'
            TerminalMesh = 'terminal_subgrid'
            SurgeMesh = 'surge_subgrid'
            ShardMesh = 'shard_subgrid'
            Camera = @{
                Height = 5.35
                Distance = 8.05
                LookAhead = 0.92
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -13.0
                ProjectScale = 92
            }
            TerrainProfile = @{
                CliffMaterial = 'concrete_shadow'
                ShelfMaterial = 'concrete_damp'
                BridgeMaterial = 'catwalk_oil'
                CeilingMaterial = 'steel_truss'
                SoffitMaterial = 'metal_under'
                LaneTrimMaterial = 'grate_slot'
                FarMassMaterial = 'relay_panel'
                AccentMaterial = 'emissive_relay'
                LandmarkLift = 0.78
                PropDensity = 2
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 5.52
                    Distance = 8.28
                    LookAhead = 0.96
                    PitchDegrees = -12.0
                    ProjectScale = 94
                    Horizon = 44
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 5.28
                    Distance = 7.45
                    LookAhead = 1.05
                    PitchDegrees = -15.0
                    ProjectScale = 98
                    Horizon = 40
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.20
                }
                SectorEntry = @{
                    Height = 5.05
                    Distance = 9.15
                    LookAhead = 0.00
                    PitchDegrees = -12.0
                    ProjectScale = 96
                    Horizon = 43
                    FocusBiasX = 0.60
                    FocusBiasZ = -0.82
                }
                EnemyReveal = @{
                    Height = 4.95
                    Distance = 6.05
                    LookAhead = 0.18
                    PitchDegrees = -17.0
                    ProjectScale = 100
                    Horizon = 35
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                Interaction = @{
                    Height = 5.05
                    Distance = 6.20
                    LookAhead = 0.14
                    PitchDegrees = -18.0
                    ProjectScale = 98
                    Horizon = 35
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.12
                }
                WardenPressure = @{
                    Height = 5.00
                    Distance = 5.95
                    LookAhead = 0.12
                    PitchDegrees = -17.0
                    ProjectScale = 104
                    Horizon = 38
                    FocusBiasX = 0.10
                    FocusBiasZ = -0.08
                }
                EndBeat = @{
                    Height = 4.55
                    Distance = 5.35
                    LookAhead = 0.16
                    PitchDegrees = -20.0
                    ProjectScale = 104
                    Horizon = 33
                    FocusBiasX = 0.12
                    FocusBiasZ = 0.06
                }
            }
            Structure = @{
                NearInset = 0.40
                NearWidth = 0.32
                NearHeight = 1.48
                FarInset = 0.58
                FarHeight = 0.74
            }
            Framing = @{
                DoorFrameInset = 0.16
                DoorFrameWidth = 0.22
                DoorFrameHeight = 1.34
                RailInset = 0.60
                RailWidth = 0.18
                RailHeight = 0.76
                CeilingBeamHeight = 1.54
                CeilingBeamThickness = 0.24
                FarMassInset = 0.88
                FarMassWidth = 2.55
                FarMassHeight = 1.36
            }
            Landmark = @{
                Mesh = 'landmark_relay_gantry'
            }
            Atmosphere = @{
                BackdropFar = 'PAL_BG1'
                BackdropMid = 'PAL_CYAN2'
                BackdropNear = 'PAL_PANEL'
                HorizonA = 'PAL_WHITE'
                HorizonB = 'PAL_CYAN'
                HorizonY = 40
                FogNear = 1760
                FogFar = 3080
                WobbleStrength = 1
            }
        }
        @{
            Key = 'sector2'
            FloorBase = 'catwalk_oil'
            FloorTrim = 'hazard_rung'
            WallBase = 'metal_slot'
            WallTrim = 'hinge_steel'
            WallCap = 'skyline_panel'
            Lane = 'hazard_amber'
            GateMesh = 'gate_switchyard'
            TerminalMesh = 'terminal_switchyard'
            SurgeMesh = 'surge_switchyard'
            ShardMesh = 'shard_switchyard'
            Camera = @{
                Height = 5.45
                Distance = 7.25
                LookAhead = 0.92
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -14.0
                ProjectScale = 96
            }
            TerrainProfile = @{
                CliffMaterial = 'occluder_dark'
                ShelfMaterial = 'catwalk_oil'
                BridgeMaterial = 'hinge_steel'
                CeilingMaterial = 'hinge_steel'
                SoffitMaterial = 'metal_under'
                LaneTrimMaterial = 'hazard_rung'
                FarMassMaterial = 'skyline_panel'
                AccentMaterial = 'hazard_amber'
                LandmarkLift = 0.84
                PropDensity = 2
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 5.62
                    Distance = 7.52
                    LookAhead = 0.92
                    PitchDegrees = -13.0
                    ProjectScale = 98
                    Horizon = 40
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 5.35
                    Distance = 6.62
                    LookAhead = 1.08
                    PitchDegrees = -16.0
                    ProjectScale = 102
                    Horizon = 36
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.20
                }
                SectorEntry = @{
                    Height = 5.08
                    Distance = 8.92
                    LookAhead = 0.00
                    PitchDegrees = -13.0
                    ProjectScale = 94
                    Horizon = 38
                    FocusBiasX = -0.62
                    FocusBiasZ = -0.90
                }
                EnemyReveal = @{
                    Height = 5.05
                    Distance = 5.60
                    LookAhead = 0.12
                    PitchDegrees = -18.0
                    ProjectScale = 104
                    Horizon = 31
                    FocusBiasX = 0.12
                    FocusBiasZ = 0.00
                }
                Interaction = @{
                    Height = 5.10
                    Distance = 5.85
                    LookAhead = 0.12
                    PitchDegrees = -19.0
                    ProjectScale = 102
                    Horizon = 31
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.18
                }
                WardenPressure = @{
                    Height = 5.05
                    Distance = 5.42
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 108
                    Horizon = 33
                    FocusBiasX = 0.18
                    FocusBiasZ = -0.18
                }
                EndBeat = @{
                    Height = 4.60
                    Distance = 4.95
                    LookAhead = 0.18
                    PitchDegrees = -21.0
                    ProjectScale = 112
                    Horizon = 27
                    FocusBiasX = 0.10
                    FocusBiasZ = 0.10
                }
            }
            Structure = @{
                NearInset = 0.44
                NearWidth = 0.40
                NearHeight = 1.68
                FarInset = 0.52
                FarHeight = 0.88
            }
            Framing = @{
                DoorFrameInset = 0.20
                DoorFrameWidth = 0.28
                DoorFrameHeight = 1.52
                RailInset = 0.56
                RailWidth = 0.22
                RailHeight = 0.88
                CeilingBeamHeight = 1.72
                CeilingBeamThickness = 0.28
                FarMassInset = 0.80
                FarMassWidth = 2.72
                FarMassHeight = 1.62
            }
            Landmark = @{
                Mesh = 'landmark_switchframe'
            }
            Atmosphere = @{
                BackdropFar = 'PAL_BG0'
                BackdropMid = 'PAL_PANEL2'
                BackdropNear = 'PAL_PANEL'
                HorizonA = 'PAL_AMBER'
                HorizonB = 'PAL_WHITE'
                HorizonY = 35
                FogNear = 1880
                FogFar = 3200
                WobbleStrength = 1
            }
        }
        @{
            Key = 'sector3'
            FloorBase = 'metal_grime'
            FloorTrim = 'trench_hot'
            WallBase = 'metal_furnace'
            WallTrim = 'duct_shadow'
            WallCap = 'furnace_soot'
            Lane = 'strip_hot'
            GateMesh = 'gate_furnace'
            TerminalMesh = 'terminal_furnace'
            SurgeMesh = 'surge_furnace'
            ShardMesh = 'shard_furnace'
            Camera = @{
                Height = 5.95
                Distance = 6.70
                LookAhead = 0.86
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -15.0
                ProjectScale = 102
            }
            TerrainProfile = @{
                CliffMaterial = 'furnace_soot'
                ShelfMaterial = 'metal_grime'
                BridgeMaterial = 'trench_plate'
                CeilingMaterial = 'metal_duct'
                SoffitMaterial = 'duct_shadow'
                LaneTrimMaterial = 'trench_hot'
                FarMassMaterial = 'furnace_soot'
                AccentMaterial = 'strip_furnace'
                LandmarkLift = 0.90
                PropDensity = 3
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 6.10
                    Distance = 6.92
                    LookAhead = 0.86
                    PitchDegrees = -14.0
                    ProjectScale = 104
                    Horizon = 36
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 5.72
                    Distance = 6.28
                    LookAhead = 1.02
                    PitchDegrees = -17.0
                    ProjectScale = 106
                    Horizon = 33
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.24
                }
                SectorEntry = @{
                    Height = 5.28
                    Distance = 8.58
                    LookAhead = 0.00
                    PitchDegrees = -14.0
                    ProjectScale = 96
                    Horizon = 37
                    FocusBiasX = -0.48
                    FocusBiasZ = -0.88
                }
                EnemyReveal = @{
                    Height = 5.15
                    Distance = 5.30
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 108
                    Horizon = 28
                    FocusBiasX = 0.10
                    FocusBiasZ = 0.00
                }
                Interaction = @{
                    Height = 5.25
                    Distance = 5.45
                    LookAhead = 0.12
                    PitchDegrees = -19.0
                    ProjectScale = 106
                    Horizon = 28
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.20
                }
                WardenPressure = @{
                    Height = 5.10
                    Distance = 5.05
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 114
                    Horizon = 30
                    FocusBiasX = 0.18
                    FocusBiasZ = -0.18
                }
                EndBeat = @{
                    Height = 4.70
                    Distance = 4.65
                    LookAhead = 0.18
                    PitchDegrees = -21.0
                    ProjectScale = 116
                    Horizon = 25
                    FocusBiasX = 0.08
                    FocusBiasZ = 0.08
                }
            }
            Structure = @{
                NearInset = 0.38
                NearWidth = 0.44
                NearHeight = 1.78
                FarInset = 0.44
                FarHeight = 0.96
            }
            Framing = @{
                DoorFrameInset = 0.19
                DoorFrameWidth = 0.28
                DoorFrameHeight = 1.60
                RailInset = 0.54
                RailWidth = 0.20
                RailHeight = 0.92
                CeilingBeamHeight = 1.82
                CeilingBeamThickness = 0.30
                FarMassInset = 0.74
                FarMassWidth = 2.92
                FarMassHeight = 1.82
            }
            Landmark = @{
                Mesh = 'landmark_furnace'
            }
            Atmosphere = @{
                BackdropFar = 'PAL_BG1'
                BackdropMid = 'PAL_PANEL2'
                BackdropNear = 'PAL_PANEL'
                HorizonA = 'PAL_AMBER'
                HorizonB = 'PAL_RED'
                HorizonY = 33
                FogNear = 1960
                FogFar = 3320
                WobbleStrength = 2
            }
        }
        @{
            Key = 'sector4'
            FloorBase = 'vault_panel_cold'
            FloorTrim = 'vault_rib'
            WallBase = 'seal_panel'
            WallTrim = 'seal_rib'
            WallCap = 'uplink_panel'
            Lane = 'emissive_uplink'
            GateMesh = 'gate_vault'
            TerminalMesh = 'terminal_vault'
            SurgeMesh = 'surge_vault'
            ShardMesh = 'shard_vault'
            Camera = @{
                Height = 6.20
                Distance = 6.45
                LookAhead = 0.82
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -13.0
                ProjectScale = 106
            }
            TerrainProfile = @{
                CliffMaterial = 'vault_rib'
                ShelfMaterial = 'vault_panel_cold'
                BridgeMaterial = 'seal_rib'
                CeilingMaterial = 'vault_rib'
                SoffitMaterial = 'seal_rib'
                LaneTrimMaterial = 'rail_cold'
                FarMassMaterial = 'uplink_panel'
                AccentMaterial = 'emissive_uplink'
                LandmarkLift = 0.96
                PropDensity = 2
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 6.36
                    Distance = 6.68
                    LookAhead = 0.82
                    PitchDegrees = -12.0
                    ProjectScale = 108
                    Horizon = 34
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 5.92
                    Distance = 6.05
                    LookAhead = 0.98
                    PitchDegrees = -15.0
                    ProjectScale = 110
                    Horizon = 32
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.18
                }
                SectorEntry = @{
                    Height = 5.52
                    Distance = 8.38
                    LookAhead = 0.00
                    PitchDegrees = -12.0
                    ProjectScale = 98
                    Horizon = 36
                    FocusBiasX = 0.66
                    FocusBiasZ = -0.92
                }
                EnemyReveal = @{
                    Height = 5.35
                    Distance = 5.10
                    LookAhead = 0.08
                    PitchDegrees = -17.0
                    ProjectScale = 112
                    Horizon = 27
                    FocusBiasX = 0.10
                    FocusBiasZ = -0.04
                }
                Interaction = @{
                    Height = 5.45
                    Distance = 5.30
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 110
                    Horizon = 27
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.16
                }
                WardenPressure = @{
                    Height = 5.18
                    Distance = 4.88
                    LookAhead = 0.08
                    PitchDegrees = -17.0
                    ProjectScale = 118
                    Horizon = 29
                    FocusBiasX = 0.22
                    FocusBiasZ = -0.24
                }
                EndBeat = @{
                    Height = 4.80
                    Distance = 4.50
                    LookAhead = 0.16
                    PitchDegrees = -20.0
                    ProjectScale = 118
                    Horizon = 24
                    FocusBiasX = 0.08
                    FocusBiasZ = 0.06
                }
            }
            Structure = @{
                NearInset = 0.36
                NearWidth = 0.46
                NearHeight = 1.86
                FarInset = 0.40
                FarHeight = 1.02
            }
            Framing = @{
                DoorFrameInset = 0.20
                DoorFrameWidth = 0.30
                DoorFrameHeight = 1.70
                RailInset = 0.56
                RailWidth = 0.18
                RailHeight = 0.98
                CeilingBeamHeight = 1.90
                CeilingBeamThickness = 0.30
                FarMassInset = 0.70
                FarMassWidth = 3.00
                FarMassHeight = 1.92
            }
            Landmark = @{
                Mesh = 'landmark_vault'
            }
            Atmosphere = @{
                BackdropFar = 'PAL_BLACK'
                BackdropMid = 'PAL_BG0'
                BackdropNear = 'PAL_PANEL'
                HorizonA = 'PAL_WHITE'
                HorizonB = 'PAL_CYAN'
                HorizonY = 30
                FogNear = 1840
                FogFar = 3040
                WobbleStrength = 1
            }
        }
    )
    Meshes = @(
        @{
            Key = 'gate_vault'
            Vertices = @(
                (M -140 0 -28), (M -84 0 -28), (M -84 280 -28), (M -140 280 -28),
                (M 84 0 -28), (M 140 0 -28), (M 140 280 -28), (M 84 280 -28),
                (M -116 280 -28), (M 116 280 -28), (M 116 336 -28), (M -116 336 -28),
                (M -58 80 12), (M 58 80 12), (M 58 224 12), (M -58 224 12)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'vault_wall'),
                (Face @(4, 5, 6, 7) 'vault_wall'),
                (Face @(8, 9, 10, 11) 'vault_trim'),
                (Face @(12, 13, 14, 15) 'gate_glow')
            )
        }
        @{
            Key = 'gate_furnace'
            Vertices = @(
                (M -144 0 -30), (M -86 0 -30), (M -86 286 -30), (M -144 286 -30),
                (M 86 0 -30), (M 144 0 -30), (M 144 286 -30), (M 86 286 -30),
                (M -120 286 -30), (M 120 286 -30), (M 120 348 -30), (M -120 348 -30),
                (M -62 88 16), (M 62 88 16), (M 62 228 16), (M -62 228 16)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'furnace_wall'),
                (Face @(4, 5, 6, 7) 'furnace_wall'),
                (Face @(8, 9, 10, 11) 'panel_amber'),
                (Face @(12, 13, 14, 15) 'gate_glow')
            )
        }
        @{
            Key = 'gate_lock'
            Vertices = @(
                (M -146 0 -30), (M -88 0 -30), (M -88 296 -30), (M -146 296 -30),
                (M 88 0 -30), (M 146 0 -30), (M 146 296 -30), (M 88 296 -30),
                (M -122 296 -30), (M 122 296 -30), (M 122 356 -30), (M -122 356 -30),
                (M -64 92 16), (M 64 92 16), (M 64 236 16), (M -64 236 16)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'lock_wall'),
                (Face @(4, 5, 6, 7) 'lock_wall'),
                (Face @(8, 9, 10, 11) 'panel_red'),
                (Face @(12, 13, 14, 15) 'gate_glow')
            )
        }
        @{
            Key = 'terminal_vault'
            Vertices = @(
                (M -56 0 -48), (M 56 0 -48), (M 56 0 48), (M -56 0 48),
                (M -42 152 -38), (M 42 152 -38), (M 42 152 38), (M -42 152 38),
                (M -36 168 16), (M 36 168 16), (M 28 286 -18), (M -28 286 -18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'vault_wall'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 6, 7) 'vault_trim'),
                (Face @(8, 9, 10, 11) 'console_cyan')
            )
        }
        @{
            Key = 'terminal_furnace'
            Vertices = @(
                (M -60 0 -48), (M 60 0 -48), (M 60 0 48), (M -60 0 48),
                (M -44 160 -40), (M 44 160 -40), (M 44 160 40), (M -44 160 40),
                (M -38 176 18), (M 38 176 18), (M 30 294 -18), (M -30 294 -18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'furnace_wall'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 6, 7) 'panel_amber'),
                (Face @(8, 9, 10, 11) 'console_amber')
            )
        }
        @{
            Key = 'terminal_lock'
            Vertices = @(
                (M -58 0 -48), (M 58 0 -48), (M 58 0 48), (M -58 0 48),
                (M -42 156 -40), (M 42 156 -40), (M 42 156 40), (M -42 156 40),
                (M -38 174 18), (M 38 174 18), (M 30 292 -18), (M -30 292 -18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'lock_wall'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 6, 7) 'panel_red'),
                (Face @(8, 9, 10, 11) 'console_red')
            )
        }
        @{
            Key = 'surge_vault'
            Vertices = @(
                (M -42 0 -42), (M 42 0 -42), (M 42 0 42), (M -42 0 42),
                (M -18 164 -18), (M 18 164 -18), (M 18 164 18), (M -18 164 18),
                (M 0 308 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'panel_dark'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'panel_cyan'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'panel_cyan'),
                (Face @(7, 4, 8) 'panel_white')
            )
        }
        @{
            Key = 'surge_furnace'
            Vertices = @(
                (M -42 0 -42), (M 42 0 -42), (M 42 0 42), (M -42 0 42),
                (M -18 164 -18), (M 18 164 -18), (M 18 164 18), (M -18 164 18),
                (M 0 316 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'panel_dark'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'panel_amber'),
                (Face @(5, 6, 8) 'panel_red'),
                (Face @(6, 7, 8) 'panel_amber'),
                (Face @(7, 4, 8) 'panel_red')
            )
        }
        @{
            Key = 'surge_lock'
            Vertices = @(
                (M -42 0 -42), (M 42 0 -42), (M 42 0 42), (M -42 0 42),
                (M -18 164 -18), (M 18 164 -18), (M 18 164 18), (M -18 164 18),
                (M 0 316 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'panel_dark'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'gate_glow'),
                (Face @(5, 6, 8) 'panel_red'),
                (Face @(6, 7, 8) 'gate_glow'),
                (Face @(7, 4, 8) 'panel_red')
            )
        }
        @{
            Key = 'shard_vault'
            Vertices = @(
                (M -44 0 -44), (M 44 0 -44), (M 44 0 44), (M -44 0 44),
                (M -30 42 -30), (M 30 42 -30), (M 30 42 30), (M -30 42 30),
                (M 0 210 0), (M 0 108 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'panel_dark'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'panel_white'),
                (Face @(5, 6, 8) 'panel_cyan'),
                (Face @(6, 7, 8) 'panel_white'),
                (Face @(7, 4, 8) 'panel_cyan'),
                (Face @(4, 5, 9) 'panel_cyan'),
                (Face @(6, 7, 9) 'panel_white')
            )
        }
        @{
            Key = 'shard_furnace'
            Vertices = @(
                (M -44 0 -44), (M 44 0 -44), (M 44 0 44), (M -44 0 44),
                (M -30 42 -30), (M 30 42 -30), (M 30 42 30), (M -30 42 30),
                (M 0 210 0), (M 0 108 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'panel_dark'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'panel_amber'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'panel_amber'),
                (Face @(7, 4, 8) 'panel_white'),
                (Face @(4, 5, 9) 'panel_red'),
                (Face @(6, 7, 9) 'panel_amber')
            )
        }
        @{
            Key = 'shard_lock'
            Vertices = @(
                (M -44 0 -44), (M 44 0 -44), (M 44 0 44), (M -44 0 44),
                (M -30 42 -30), (M 30 42 -30), (M 30 42 30), (M -30 42 30),
                (M 0 210 0), (M 0 108 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'panel_dark'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'panel_dark'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'gate_glow'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'gate_glow'),
                (Face @(7, 4, 8) 'panel_white'),
                (Face @(4, 5, 9) 'panel_red'),
                (Face @(6, 7, 9) 'gate_glow')
            )
        }
        @{
            Key = 'beacon_exit'
            Vertices = @(
                (M -34 0 -34), (M 34 0 -34), (M 34 0 34), (M -34 0 34),
                (M -18 118 -18), (M 18 118 -18), (M 18 118 18), (M -18 118 18),
                (M 0 276 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'beacon_exit'),
                (Face @(1, 2, 6, 5) 'panel_white'),
                (Face @(2, 3, 7, 6) 'beacon_exit'),
                (Face @(3, 0, 4, 7) 'panel_white'),
                (Face @(4, 5, 8) 'beacon_exit'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'beacon_exit'),
                (Face @(7, 4, 8) 'panel_white')
            )
        }
        @{
            Key = 'beacon_focus'
            Vertices = @(
                (M -30 0 -30), (M 30 0 -30), (M 30 0 30), (M -30 0 30),
                (M -14 112 -14), (M 14 112 -14), (M 14 112 14), (M -14 112 14),
                (M 0 256 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'beacon_focus'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'beacon_focus'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'panel_white'),
                (Face @(5, 6, 8) 'beacon_focus'),
                (Face @(6, 7, 8) 'panel_white'),
                (Face @(7, 4, 8) 'beacon_focus')
            )
        }
        @{
            Key = 'beacon_spoof'
            Vertices = @(
                (M -30 0 -30), (M 30 0 -30), (M 30 0 30), (M -30 0 30),
                (M -14 114 -14), (M 14 114 -14), (M 14 114 14), (M -14 114 14),
                (M 0 266 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'beacon_spoof'),
                (Face @(1, 2, 6, 5) 'panel_white'),
                (Face @(2, 3, 7, 6) 'beacon_spoof'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'beacon_spoof'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'beacon_spoof'),
                (Face @(7, 4, 8) 'panel_white')
            )
        }
        @{
            Key = 'beacon_threat'
            Vertices = @(
                (M -32 0 -32), (M 32 0 -32), (M 32 0 32), (M -32 0 32),
                (M -16 118 -16), (M 16 118 -16), (M 16 118 16), (M -16 118 16),
                (M 0 284 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'beacon_threat'),
                (Face @(1, 2, 6, 5) 'panel_white'),
                (Face @(2, 3, 7, 6) 'panel_red'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 8) 'beacon_threat'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'panel_red'),
                (Face @(7, 4, 8) 'panel_white')
            )
        }
        @{
            Key = 'landmark_vault'
            Vertices = @(
                (M -112 0 -48), (M 112 0 -48), (M 112 0 48), (M -112 0 48),
                (M -86 188 -34), (M 86 188 -34), (M 74 254 54), (M -74 254 54),
                (M -32 308 -18), (M 32 308 -18), (M 0 392 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'vault_wall'),
                (Face @(1, 2, 6, 5) 'vault_trim'),
                (Face @(2, 3, 7, 6) 'vault_wall'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 9, 8) 'panel_cyan'),
                (Face @(5, 6, 9) 'panel_white'),
                (Face @(6, 7, 8, 9) 'vault_trim'),
                (Face @(8, 9, 10) 'panel_white')
            )
        }
        @{
            Key = 'landmark_furnace'
            Vertices = @(
                (M -128 0 -46), (M 128 0 -46), (M 128 0 46), (M -128 0 46),
                (M -96 174 -28), (M 96 174 -28), (M 84 228 54), (M -84 228 54),
                (M -76 292 -18), (M -28 332 -6), (M 28 332 -6), (M 76 292 -18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'furnace_wall'),
                (Face @(1, 2, 6, 5) 'furnace_trim'),
                (Face @(2, 3, 7, 6) 'furnace_wall'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 10, 9) 'panel_amber'),
                (Face @(5, 6, 11, 10) 'panel_white'),
                (Face @(6, 7, 8, 11) 'furnace_trim'),
                (Face @(8, 9, 10, 11) 'panel_red')
            )
        }
        @{
            Key = 'landmark_lock'
            Vertices = @(
                (M -118 0 -52), (M 118 0 -52), (M 118 0 52), (M -118 0 52),
                (M -88 206 -34), (M 88 206 -34), (M 76 276 60), (M -76 276 60),
                (M -34 340 -20), (M 34 340 -20), (M 0 424 -40)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'lock_wall'),
                (Face @(1, 2, 6, 5) 'panel_red'),
                (Face @(2, 3, 7, 6) 'lock_wall'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 9, 8) 'lock_trim'),
                (Face @(5, 6, 9) 'panel_white'),
                (Face @(6, 7, 8, 9) 'lock_trim'),
                (Face @(8, 9, 10) 'panel_red')
            )
        }
        @{
            Key = 'portal_arch'
            Vertices = @(
                (M -150 0 -34), (M -92 0 -34), (M -92 288 -34), (M -150 288 -34),
                (M 92 0 -34), (M 150 0 -34), (M 150 288 -34), (M 92 288 -34),
                (M -116 288 -34), (M 116 288 -34), (M 116 356 -34), (M -116 356 -34),
                (M -58 92 14), (M 58 92 14), (M 58 236 14), (M -58 236 14)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'sky_stone'),
                (Face @(4, 5, 6, 7) 'sky_stone'),
                (Face @(8, 9, 10, 11) 'sun_warm'),
                (Face @(12, 13, 14, 15) 'gate_glow')
            )
        }
        @{
            Key = 'switch_pedestal'
            Vertices = @(
                (M -62 0 -52), (M 62 0 -52), (M 62 0 52), (M -62 0 52),
                (M -46 136 -38), (M 46 136 -38), (M 46 136 38), (M -46 136 38),
                (M -22 206 -20), (M 22 206 -20), (M 0 294 18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'stone_soft'),
                (Face @(1, 2, 6, 5) 'sky_stone'),
                (Face @(2, 3, 7, 6) 'stone_soft'),
                (Face @(3, 0, 4, 7) 'sky_stone'),
                (Face @(4, 5, 9, 8) 'sun_warm'),
                (Face @(5, 6, 9) 'panel_white'),
                (Face @(6, 7, 8, 9) 'sun_warm'),
                (Face @(8, 9, 10) 'console_cyan')
            )
        }
        @{
            Key = 'lava_vent'
            Vertices = @(
                (M -68 0 -48), (M 68 0 -48), (M 68 0 48), (M -68 0 48),
                (M -42 78 -22), (M 42 78 -22), (M 42 78 22), (M -42 78 22),
                (M 0 154 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'stone_soft'),
                (Face @(1, 2, 6, 5) 'lava_hot'),
                (Face @(2, 3, 7, 6) 'stone_soft'),
                (Face @(3, 0, 4, 7) 'lava_hot'),
                (Face @(4, 5, 8) 'sun_warm'),
                (Face @(5, 6, 8) 'lava_hot'),
                (Face @(6, 7, 8) 'sun_warm'),
                (Face @(7, 4, 8) 'lava_hot')
            )
        }
        @{
            Key = 'gem_cluster'
            Vertices = @(
                (M -24 0 0), (M 0 0 -24), (M 24 0 0), (M 0 0 24),
                (M -14 86 -14), (M 14 86 -14), (M 14 86 14), (M -14 86 14),
                (M 0 164 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'gem_blue'),
                (Face @(1, 2, 6, 5) 'panel_white'),
                (Face @(2, 3, 7, 6) 'gem_blue'),
                (Face @(3, 0, 4, 7) 'panel_white'),
                (Face @(4, 5, 8) 'gem_blue'),
                (Face @(5, 6, 8) 'panel_white'),
                (Face @(6, 7, 8) 'gem_blue'),
                (Face @(7, 4, 8) 'panel_white')
            )
        }
        @{
            Key = 'tree_round'
            Vertices = @(
                (M -22 0 -22), (M 22 0 -22), (M 22 0 22), (M -22 0 22),
                (M -18 126 -18), (M 18 126 -18), (M 18 126 18), (M -18 126 18),
                (M -84 172 -42), (M 84 172 -42), (M 84 172 42), (M -84 172 42),
                (M 0 282 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'tree_trunk'),
                (Face @(1, 2, 6, 5) 'tree_trunk'),
                (Face @(2, 3, 7, 6) 'tree_trunk'),
                (Face @(3, 0, 4, 7) 'tree_trunk'),
                (Face @(8, 9, 12) 'tree_canopy'),
                (Face @(9, 10, 12) 'tree_canopy'),
                (Face @(10, 11, 12) 'tree_canopy'),
                (Face @(11, 8, 12) 'tree_canopy')
            )
        }
        @{
            Key = 'stone_stack'
            Vertices = @(
                (M -70 0 -44), (M 58 0 -36), (M 62 0 42), (M -64 0 48),
                (M -52 68 -30), (M 44 74 -28), (M 42 74 30), (M -48 68 34),
                (M -28 128 -12), (M 30 132 -14), (M 24 132 18), (M -26 128 20)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'stone_soft'),
                (Face @(1, 2, 6, 5) 'sky_stone'),
                (Face @(2, 3, 7, 6) 'stone_soft'),
                (Face @(3, 0, 4, 7) 'sky_stone'),
                (Face @(4, 5, 9, 8) 'stone_soft'),
                (Face @(5, 6, 10, 9) 'sky_stone'),
                (Face @(6, 7, 11, 10) 'stone_soft'),
                (Face @(7, 4, 8, 11) 'sky_stone')
            )
        }
        @{
            Key = 'bridge_span'
            Vertices = @(
                (M -120 0 -48), (M 120 0 -48), (M 120 0 48), (M -120 0 48),
                (M -120 26 -48), (M 120 26 -48), (M 120 26 48), (M -120 26 48),
                (M -92 92 -36), (M -62 92 -36), (M 62 92 36), (M 92 92 36)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'sun_warm'),
                (Face @(1, 2, 6, 5) 'stone_soft'),
                (Face @(2, 3, 7, 6) 'sun_warm'),
                (Face @(3, 0, 4, 7) 'stone_soft'),
                (Face @(8, 9, 1, 0) 'sky_stone'),
                (Face @(10, 11, 2, 3) 'sky_stone')
            )
        }
        @{
            Key = 'tower_toy'
            Vertices = @(
                (M -86 0 -86), (M 86 0 -86), (M 86 0 86), (M -86 0 86),
                (M -64 246 -64), (M 64 246 -64), (M 64 246 64), (M -64 246 64),
                (M -46 326 -46), (M 46 326 -46), (M 46 326 46), (M -46 326 46),
                (M 0 428 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'sky_stone'),
                (Face @(1, 2, 6, 5) 'sun_warm'),
                (Face @(2, 3, 7, 6) 'sky_stone'),
                (Face @(3, 0, 4, 7) 'sun_warm'),
                (Face @(4, 5, 9, 8) 'panel_white'),
                (Face @(5, 6, 10, 9) 'sun_warm'),
                (Face @(6, 7, 11, 10) 'panel_white'),
                (Face @(7, 4, 8, 11) 'sun_warm'),
                (Face @(8, 9, 12) 'gate_glow'),
                (Face @(9, 10, 12) 'panel_white'),
                (Face @(10, 11, 12) 'gate_glow'),
                (Face @(11, 8, 12) 'panel_white')
            )
        }
        @{
            Key = 'gate_subgrid'
            Vertices = @(
                (M -162 0 -40), (M -98 0 -40), (M -98 304 -40), (M -162 304 -40),
                (M 98 0 -40), (M 162 0 -40), (M 162 304 -40), (M 98 304 -40),
                (M -130 304 -40), (M 130 304 -40), (M 130 374 -40), (M -130 374 -40),
                (M -72 92 14), (M 72 92 14), (M 72 246 14), (M -72 246 14),
                (M -146 42 8), (M -104 42 8), (M -104 270 8), (M -146 270 8),
                (M 104 42 8), (M 146 42 8), (M 146 270 8), (M 104 270 8),
                (M -118 0 34), (M 118 0 34), (M 118 26 34), (M -118 26 34)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'concrete_rib'),
                (Face @(4, 5, 6, 7) 'concrete_rib'),
                (Face @(8, 9, 10, 11) 'steel_truss'),
                (Face @(12, 13, 14, 15) 'emissive_relay' 'pulse_cyan'),
                (Face @(16, 17, 18, 19) 'rail_cyan' 'pulse_cyan'),
                (Face @(20, 21, 22, 23) 'rail_cyan' 'pulse_cyan'),
                (Face @(24, 25, 26, 27) 'metal_under')
            )
        }
        @{
            Key = 'terminal_subgrid'
            Vertices = @(
                (M -66 0 -54), (M 66 0 -54), (M 66 0 54), (M -66 0 54),
                (M -48 146 -42), (M 48 146 -42), (M 48 146 42), (M -48 146 42),
                (M -40 194 -10), (M 40 194 -10), (M 40 244 18), (M -40 244 18),
                (M -18 292 0), (M 18 292 0), (M 0 328 -24)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'concrete_damp'),
                (Face @(1, 2, 6, 5) 'steel_truss'),
                (Face @(2, 3, 7, 6) 'concrete_damp'),
                (Face @(3, 0, 4, 7) 'steel_truss'),
                (Face @(4, 5, 9, 8) 'panel_dark'),
                (Face @(5, 6, 10, 9) 'emissive_relay' 'pulse_cyan'),
                (Face @(6, 7, 11, 10) 'panel_dark'),
                (Face @(8, 9, 13, 12) 'rail_cyan'),
                (Face @(9, 10, 14, 13) 'panel_white'),
                (Face @(10, 11, 12, 14) 'rail_cyan')
            )
        }
        @{
            Key = 'surge_subgrid'
            Vertices = @(
                (M -44 0 -44), (M 44 0 -44), (M 44 0 44), (M -44 0 44),
                (M -28 102 -28), (M 28 102 -28), (M 28 102 28), (M -28 102 28),
                (M -18 188 -18), (M 18 188 -18), (M 18 188 18), (M -18 188 18),
                (M 0 292 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'metal_under'),
                (Face @(1, 2, 6, 5) 'concrete_rib'),
                (Face @(2, 3, 7, 6) 'metal_under'),
                (Face @(3, 0, 4, 7) 'concrete_rib'),
                (Face @(4, 5, 9, 8) 'rail_cyan'),
                (Face @(5, 6, 10, 9) 'emissive_relay' 'pulse_cyan'),
                (Face @(6, 7, 11, 10) 'rail_cyan'),
                (Face @(8, 9, 12) 'panel_white'),
                (Face @(9, 10, 12) 'emissive_relay' 'pulse_cyan'),
                (Face @(10, 11, 12) 'panel_white'),
                (Face @(11, 8, 12) 'emissive_relay' 'pulse_cyan')
            )
        }
        @{
            Key = 'shard_subgrid'
            Vertices = @(
                (M -46 0 -46), (M 46 0 -46), (M 46 0 46), (M -46 0 46),
                (M -30 36 -30), (M 30 36 -30), (M 30 36 30), (M -30 36 30),
                (M -10 110 -10), (M 10 110 -10), (M 10 110 10), (M -10 110 10),
                (M 0 226 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'metal_slot'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'metal_slot'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 9, 8) 'rail_cyan'),
                (Face @(5, 6, 10, 9) 'panel_white'),
                (Face @(6, 7, 11, 10) 'rail_cyan'),
                (Face @(7, 4, 8, 11) 'panel_white'),
                (Face @(8, 9, 12) 'gem_blue'),
                (Face @(9, 10, 12) 'panel_white'),
                (Face @(10, 11, 12) 'gem_blue'),
                (Face @(11, 8, 12) 'panel_white')
            )
        }
        @{
            Key = 'gate_switchyard'
            Vertices = @(
                (M -166 0 -42), (M -100 0 -42), (M -100 312 -42), (M -166 312 -42),
                (M 100 0 -42), (M 166 0 -42), (M 166 312 -42), (M 100 312 -42),
                (M -132 312 -42), (M 132 312 -42), (M 132 382 -42), (M -132 382 -42),
                (M -74 88 12), (M 74 88 12), (M 74 248 12), (M -74 248 12),
                (M -150 30 8), (M -108 30 8), (M -108 286 8), (M -150 286 8),
                (M 108 30 8), (M 150 30 8), (M 150 286 8), (M 108 286 8)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'metal_slot'),
                (Face @(4, 5, 6, 7) 'metal_slot'),
                (Face @(8, 9, 10, 11) 'steel_truss'),
                (Face @(12, 13, 14, 15) 'hazard_amber' 'pulse_amber'),
                (Face @(16, 17, 18, 19) 'hazard_rung'),
                (Face @(20, 21, 22, 23) 'hazard_rung')
            )
        }
        @{
            Key = 'terminal_switchyard'
            Vertices = @(
                (M -70 0 -56), (M 70 0 -56), (M 70 0 56), (M -70 0 56),
                (M -50 150 -42), (M 50 150 -42), (M 50 150 42), (M -50 150 42),
                (M -46 206 -14), (M 46 206 -14), (M 46 252 18), (M -46 252 18),
                (M -22 294 -6), (M 22 294 -6), (M 0 334 -28)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'steel_catwalk'),
                (Face @(1, 2, 6, 5) 'metal_slot'),
                (Face @(2, 3, 7, 6) 'steel_catwalk'),
                (Face @(3, 0, 4, 7) 'metal_slot'),
                (Face @(4, 5, 9, 8) 'panel_dark'),
                (Face @(5, 6, 10, 9) 'hazard_amber' 'pulse_amber'),
                (Face @(6, 7, 11, 10) 'panel_dark'),
                (Face @(8, 9, 13, 12) 'hazard_rung'),
                (Face @(9, 10, 14, 13) 'panel_white'),
                (Face @(10, 11, 12, 14) 'hazard_rung')
            )
        }
        @{
            Key = 'surge_switchyard'
            Vertices = @(
                (M -46 0 -46), (M 46 0 -46), (M 46 0 46), (M -46 0 46),
                (M -30 104 -30), (M 30 104 -30), (M 30 104 30), (M -30 104 30),
                (M -20 186 -20), (M 20 186 -20), (M 20 186 20), (M -20 186 20),
                (M 0 300 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'metal_under'),
                (Face @(1, 2, 6, 5) 'steel_truss'),
                (Face @(2, 3, 7, 6) 'metal_under'),
                (Face @(3, 0, 4, 7) 'steel_truss'),
                (Face @(4, 5, 9, 8) 'hazard_rung'),
                (Face @(5, 6, 10, 9) 'hazard_amber' 'pulse_amber'),
                (Face @(6, 7, 11, 10) 'hazard_rung'),
                (Face @(8, 9, 12) 'panel_white'),
                (Face @(9, 10, 12) 'hazard_amber' 'pulse_amber'),
                (Face @(10, 11, 12) 'panel_white'),
                (Face @(11, 8, 12) 'hazard_amber' 'pulse_amber')
            )
        }
        @{
            Key = 'shard_switchyard'
            Vertices = @(
                (M -48 0 -48), (M 48 0 -48), (M 48 0 48), (M -48 0 48),
                (M -32 36 -32), (M 32 36 -32), (M 32 36 32), (M -32 36 32),
                (M -12 122 -12), (M 12 122 -12), (M 12 122 12), (M -12 122 12),
                (M 0 236 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'steel_catwalk'),
                (Face @(1, 2, 6, 5) 'panel_dark'),
                (Face @(2, 3, 7, 6) 'steel_catwalk'),
                (Face @(3, 0, 4, 7) 'panel_dark'),
                (Face @(4, 5, 9, 8) 'hazard_rung'),
                (Face @(5, 6, 10, 9) 'panel_white'),
                (Face @(6, 7, 11, 10) 'hazard_rung'),
                (Face @(7, 4, 8, 11) 'panel_white'),
                (Face @(8, 9, 12) 'panel_amber'),
                (Face @(9, 10, 12) 'panel_white'),
                (Face @(10, 11, 12) 'panel_amber'),
                (Face @(11, 8, 12) 'panel_white')
            )
        }
        @{
            Key = 'landmark_relay_gantry'
            Vertices = @(
                (M -150 0 -52), (M -84 0 -52), (M -84 286 -52), (M -150 286 -52),
                (M 84 0 -52), (M 150 0 -52), (M 150 286 -52), (M 84 286 -52),
                (M -114 286 -52), (M 114 286 -52), (M 114 364 -52), (M -114 364 -52),
                (M -52 118 18), (M 52 118 18), (M 52 222 18), (M -52 222 18),
                (M -96 0 42), (M 96 0 42), (M 96 38 42), (M -96 38 42)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'concrete_rib'),
                (Face @(4, 5, 6, 7) 'concrete_rib'),
                (Face @(8, 9, 10, 11) 'steel_truss'),
                (Face @(12, 13, 14, 15) 'emissive_relay' 'pulse_cyan'),
                (Face @(16, 17, 18, 19) 'metal_under')
            )
        }
        @{
            Key = 'landmark_switchframe'
            Vertices = @(
                (M -156 0 -56), (M -92 0 -56), (M -92 276 -56), (M -156 276 -56),
                (M 92 0 -56), (M 156 0 -56), (M 156 276 -56), (M 92 276 -56),
                (M -126 276 -56), (M 126 276 -56), (M 126 352 -56), (M -126 352 -56),
                (M -68 92 20), (M 68 92 20), (M 68 212 20), (M -68 212 20)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'metal_slot'),
                (Face @(4, 5, 6, 7) 'metal_slot'),
                (Face @(8, 9, 10, 11) 'steel_truss'),
                (Face @(12, 13, 14, 15) 'hazard_amber' 'pulse_amber')
            )
        }
        @{
            Key = 'storm_gate_mass'
            Vertices = @(
                (M -136 0 -64), (M 136 0 -64), (M 136 0 64), (M -136 0 64),
                (M -112 206 -44), (M 112 206 -44), (M 112 206 44), (M -112 206 44),
                (M -64 286 -24), (M 64 286 -24), (M 64 286 24), (M -64 286 24)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'concrete_damp'),
                (Face @(1, 2, 6, 5) 'steel_truss'),
                (Face @(2, 3, 7, 6) 'concrete_damp'),
                (Face @(3, 0, 4, 7) 'steel_truss'),
                (Face @(4, 5, 9, 8) 'rail_cyan'),
                (Face @(5, 6, 10, 9) 'panel_white'),
                (Face @(6, 7, 11, 10) 'rail_cyan'),
                (Face @(7, 4, 8, 11) 'panel_white')
            )
        }
        @{
            Key = 'cable_frame'
            Vertices = @(
                (M -118 0 -24), (M -78 0 -24), (M -78 188 -24), (M -118 188 -24),
                (M 78 0 -24), (M 118 0 -24), (M 118 188 -24), (M 78 188 -24),
                (M -92 188 -24), (M 92 188 -24), (M 92 232 -24), (M -92 232 -24),
                (M -84 188 20), (M 84 188 20)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'steel_truss'),
                (Face @(4, 5, 6, 7) 'steel_truss'),
                (Face @(8, 9, 10, 11) 'metal_duct'),
                (Face @(8, 9, 13, 12) 'emissive_relay')
            )
        }
        @{
            Key = 'transfer_frame'
            Vertices = @(
                (M -124 0 -34), (M -82 0 -34), (M -82 202 -34), (M -124 202 -34),
                (M 82 0 -34), (M 124 0 -34), (M 124 202 -34), (M 82 202 -34),
                (M -96 202 -34), (M 96 202 -34), (M 96 248 -34), (M -96 248 -34),
                (M -68 86 20), (M 68 86 20), (M 68 154 20), (M -68 154 20)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'steel_catwalk'),
                (Face @(4, 5, 6, 7) 'steel_catwalk'),
                (Face @(8, 9, 10, 11) 'steel_truss'),
                (Face @(12, 13, 14, 15) 'hazard_rung')
            )
        }
        @{
            Key = 'catwalk_rib'
            Vertices = @(
                (M -114 0 -30), (M 114 0 -30), (M 114 0 30), (M -114 0 30),
                (M -92 24 -30), (M 92 24 -30), (M 92 24 30), (M -92 24 30),
                (M -72 124 -18), (M 72 124 -18), (M 72 124 18), (M -72 124 18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'steel_catwalk'),
                (Face @(1, 2, 6, 5) 'hazard_rung'),
                (Face @(2, 3, 7, 6) 'steel_catwalk'),
                (Face @(3, 0, 4, 7) 'hazard_rung'),
                (Face @(4, 5, 9, 8) 'steel_truss'),
                (Face @(6, 7, 11, 10) 'steel_truss')
            )
        }
        @{
            Key = 'vent_stack'
            Vertices = @(
                (M -94 0 -42), (M 94 0 -42), (M 94 0 42), (M -94 0 42),
                (M -64 138 -26), (M 64 138 -26), (M 64 138 26), (M -64 138 26),
                (M -34 252 -16), (M 34 252 -16), (M 34 252 16), (M -34 252 16),
                (M 0 338 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'metal_furnace'),
                (Face @(1, 2, 6, 5) 'strip_furnace'),
                (Face @(2, 3, 7, 6) 'metal_furnace'),
                (Face @(3, 0, 4, 7) 'strip_furnace'),
                (Face @(4, 5, 9, 8) 'hazard_amber'),
                (Face @(5, 6, 10, 9) 'panel_white'),
                (Face @(6, 7, 11, 10) 'hazard_amber'),
                (Face @(8, 9, 12) 'strip_hot'),
                (Face @(9, 10, 12) 'panel_white'),
                (Face @(10, 11, 12) 'strip_hot'),
                (Face @(11, 8, 12) 'panel_white')
            )
        }
        @{
            Key = 'vault_buttress'
            Vertices = @(
                (M -118 0 -46), (M 118 0 -46), (M 118 0 46), (M -118 0 46),
                (M -88 182 -28), (M 88 182 -28), (M 88 182 28), (M -88 182 28),
                (M -56 284 -18), (M 56 284 -18), (M 56 284 18), (M -56 284 18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'seal_panel'),
                (Face @(1, 2, 6, 5) 'vault_panel_cold'),
                (Face @(2, 3, 7, 6) 'seal_panel'),
                (Face @(3, 0, 4, 7) 'vault_panel_cold'),
                (Face @(4, 5, 9, 8) 'panel_white'),
                (Face @(5, 6, 10, 9) 'emissive_uplink'),
                (Face @(6, 7, 11, 10) 'panel_white'),
                (Face @(7, 4, 8, 11) 'emissive_uplink')
            )
        }
        @{
            Key = 'uplink_spine'
            Vertices = @(
                (M -72 0 -36), (M 72 0 -36), (M 72 0 36), (M -72 0 36),
                (M -54 232 -24), (M 54 232 -24), (M 54 232 24), (M -54 232 24),
                (M -32 334 -14), (M 32 334 -14), (M 32 334 14), (M -32 334 14),
                (M 0 442 0)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'seal_panel'),
                (Face @(1, 2, 6, 5) 'vault_panel_cold'),
                (Face @(2, 3, 7, 6) 'seal_panel'),
                (Face @(3, 0, 4, 7) 'vault_panel_cold'),
                (Face @(4, 5, 9, 8) 'panel_white'),
                (Face @(5, 6, 10, 9) 'rail_cold'),
                (Face @(6, 7, 11, 10) 'panel_white'),
                (Face @(8, 9, 12) 'emissive_uplink' 'pulse_cyan'),
                (Face @(9, 10, 12) 'panel_white'),
                (Face @(10, 11, 12) 'emissive_uplink' 'pulse_cyan'),
                (Face @(11, 8, 12) 'panel_white')
            )
        }
        @{
            Key = 'enemy_rusher'
            Vertices = @(
                (M -34 0 -26), (M 34 0 -26), (M 34 0 26), (M -34 0 26),
                (M -44 118 -18), (M 44 118 -18), (M 36 162 28), (M -36 162 28),
                (M 0 286 -18)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'rusher_core'),
                (Face @(1, 2, 6, 5) 'rusher_trim'),
                (Face @(2, 3, 7, 6) 'rusher_core'),
                (Face @(3, 0, 4, 7) 'rusher_trim'),
                (Face @(4, 5, 8) 'panel_white'),
                (Face @(5, 6, 8) 'rusher_core'),
                (Face @(6, 7, 8) 'rusher_trim'),
                (Face @(7, 4, 8) 'rusher_core')
            )
        }
        @{
            Key = 'enemy_rusher_alt'
            Vertices = @(
                (M -34 0 -24), (M 34 0 -30), (M 34 0 30), (M -34 0 24),
                (M -46 120 -10), (M 40 114 -24), (M 34 164 32), (M -40 170 22),
                (M -4 288 -26)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'rusher_core'),
                (Face @(1, 2, 6, 5) 'rusher_trim'),
                (Face @(2, 3, 7, 6) 'rusher_core'),
                (Face @(3, 0, 4, 7) 'rusher_trim'),
                (Face @(4, 5, 8) 'panel_white'),
                (Face @(5, 6, 8) 'rusher_core'),
                (Face @(6, 7, 8) 'rusher_trim'),
                (Face @(7, 4, 8) 'rusher_core')
            )
        }
        @{
            Key = 'enemy_flanker'
            Vertices = @(
                (M -40 0 -34), (M 40 0 -20), (M 40 0 20), (M -40 0 34),
                (M -56 110 -14), (M 48 122 -24), (M 34 170 36), (M -48 160 44),
                (M -8 276 6)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'flanker_core'),
                (Face @(1, 2, 6, 5) 'flanker_trim'),
                (Face @(2, 3, 7, 6) 'flanker_core'),
                (Face @(3, 0, 4, 7) 'flanker_trim'),
                (Face @(4, 5, 8) 'panel_white'),
                (Face @(5, 6, 8) 'flanker_core'),
                (Face @(6, 7, 8) 'flanker_trim'),
                (Face @(7, 4, 8) 'flanker_core')
            )
        }
        @{
            Key = 'enemy_flanker_alt'
            Vertices = @(
                (M -40 0 -20), (M 40 0 -34), (M 40 0 34), (M -40 0 20),
                (M -48 122 -24), (M 56 110 -14), (M 48 160 44), (M -34 170 36),
                (M 8 276 6)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'flanker_core'),
                (Face @(1, 2, 6, 5) 'flanker_trim'),
                (Face @(2, 3, 7, 6) 'flanker_core'),
                (Face @(3, 0, 4, 7) 'flanker_trim'),
                (Face @(4, 5, 8) 'panel_white'),
                (Face @(5, 6, 8) 'flanker_core'),
                (Face @(6, 7, 8) 'flanker_trim'),
                (Face @(7, 4, 8) 'flanker_core')
            )
        }
        @{
            Key = 'player_runner'
            Vertices = @(
                (M -50 0 -34), (M 50 0 -34), (M 50 0 34), (M -50 0 34),
                (M -62 126 -24), (M 62 126 -24), (M 50 170 40), (M -50 170 40),
                (M -28 268 -6), (M 28 268 -6), (M 0 336 -28)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'player_core'),
                (Face @(1, 2, 6, 5) 'player_trim'),
                (Face @(2, 3, 7, 6) 'player_core'),
                (Face @(3, 0, 4, 7) 'player_trim'),
                (Face @(4, 5, 9, 8) 'player_core'),
                (Face @(5, 6, 9) 'player_trim'),
                (Face @(6, 7, 8, 9) 'player_core'),
                (Face @(8, 9, 10) 'panel_white')
            )
        }
        @{
            Key = 'player_runner_lean'
            Vertices = @(
                (M -52 0 -26), (M 52 0 -36), (M 52 0 28), (M -52 0 38),
                (M -68 120 -18), (M 60 120 -34), (M 46 166 36), (M -56 176 48),
                (M -30 254 -30), (M 24 252 -34), (M 10 332 -56)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'player_core'),
                (Face @(1, 2, 6, 5) 'player_trim'),
                (Face @(2, 3, 7, 6) 'player_core'),
                (Face @(3, 0, 4, 7) 'player_trim'),
                (Face @(4, 5, 9, 8) 'player_core'),
                (Face @(5, 6, 9) 'player_trim'),
                (Face @(6, 7, 8, 9) 'player_core'),
                (Face @(8, 9, 10) 'panel_white')
            )
        }
        @{
            Key = 'warden'
            Vertices = @(
                (M -60 0 -42), (M 60 0 -42), (M 60 0 42), (M -60 0 42),
                (M -78 148 -30), (M 78 148 -30), (M 60 204 48), (M -60 204 48),
                (M -40 300 -10), (M 40 300 -10), (M 0 378 -38)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'warden_core'),
                (Face @(1, 2, 6, 5) 'warden_trim'),
                (Face @(2, 3, 7, 6) 'warden_core'),
                (Face @(3, 0, 4, 7) 'warden_trim'),
                (Face @(4, 5, 9, 8) 'warden_core'),
                (Face @(5, 6, 9) 'panel_white'),
                (Face @(6, 7, 8, 9) 'warden_core'),
                (Face @(8, 9, 10) 'panel_red')
            )
        }
        @{
            Key = 'warden_pressure'
            Vertices = @(
                (M -66 0 -34), (M 66 0 -50), (M 66 0 34), (M -66 0 50),
                (M -92 154 -18), (M 84 154 -42), (M 68 214 54), (M -74 220 70),
                (M -54 306 -18), (M 52 300 -30), (M 18 396 -74)
            )
            Faces = @(
                (Face @(0, 1, 5, 4) 'warden_core'),
                (Face @(1, 2, 6, 5) 'warden_trim'),
                (Face @(2, 3, 7, 6) 'warden_core'),
                (Face @(3, 0, 4, 7) 'warden_trim'),
                (Face @(4, 5, 9, 8) 'warden_core'),
                (Face @(5, 6, 9) 'panel_white'),
                (Face @(6, 7, 8, 9) 'warden_core'),
                (Face @(8, 9, 10) 'panel_red')
            )
        }
    )
}
