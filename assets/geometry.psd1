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
        [string]$Fx = ''
    )

    return @{
        Indices = $Indices
        Material = $Material
        Fx = $Fx
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
        @{ Key = 'sky_stone'; Base = 7; Dither = 6 }
        @{ Key = 'sun_warm'; Base = 8; Dither = 7 }
        @{ Key = 'meadow_ground'; Base = 13; Dither = 8 }
        @{ Key = 'tree_canopy'; Base = 5; Dither = 7 }
        @{ Key = 'tree_trunk'; Base = 8; Dither = 9 }
        @{ Key = 'stone_soft'; Base = 7; Dither = 4 }
        @{ Key = 'lava_hot'; Base = 9; Dither = 8 }
        @{ Key = 'gem_blue'; Base = 6; Dither = 7 }
    )
    Scenes = @(
        @{
            Key = 'splash'
            TimelineTicks = 60
            Camera = @{
                X = 0.0
                Y = 1.45
                Z = -8.8
                YawDegrees = -4.0
                YawStepDegrees = 1.4
                PitchDegrees = -11.0
                PitchStepDegrees = -0.8
                ProjectScale = 118
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Groups = @(
                @{
                    Key = 'chamber'
                    StartTick = 0
                    EndTick = 59
                    MotionTicks = 0
                    Vertices = @(
                        (V -12.0 -1.7 2.0), (V 12.0 -1.7 2.0), (V 8.8 -1.7 20.0), (V -8.8 -1.7 20.0),
                        (V -6.4 -1.2 16.2), (V 6.4 -1.2 16.2), (V 5.4 4.2 18.8), (V -5.4 4.2 18.8),
                        (V -10.4 -1.7 4.8), (V -8.8 -1.7 4.8), (V -7.1 3.3 12.8), (V -9.1 3.3 12.8),
                        (V 8.8 -1.7 4.8), (V 10.4 -1.7 4.8), (V 9.1 3.3 12.8), (V 7.1 3.3 12.8)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark'),
                        (Face @(4, 5, 6, 7) 'panel_dark'),
                        (Face @(8, 9, 10, 11) 'wall_dark'),
                        (Face @(12, 13, 14, 15) 'wall_dark')
                    )
                }
                @{
                    Key = 'mark'
                    StartTick = 10
                    EndTick = 59
                    MotionTicks = 18
                    Offset = @{ X = 0.0; Y = -1.35; Z = 1.55 }
                    OffsetStep = @{ X = 0.0; Y = 0.075; Z = -0.07 }
                    YawDegrees = -6.0
                    YawStepDegrees = 0.35
                    Vertices = @(
                        (V -5.2 -1.0 5.8), (V 5.2 -1.0 5.8), (V 3.8 2.1 13.4), (V -3.8 2.1 13.4),
                        (V -2.0 -1.2 9.4), (V 2.0 -1.2 9.4), (V 1.4 0.8 12.4), (V -1.4 0.8 12.4),
                        (V -0.6 -0.1 10.6), (V 0.6 -0.1 10.6), (V 0.9 2.3 12.2), (V -0.9 2.3 12.2)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_cyan' 'pulse_cyan'),
                        (Face @(4, 5, 6, 7) 'panel_dark'),
                        (Face @(8, 9, 10, 11) 'panel_white')
                    )
                }
                @{
                    Key = 'crown'
                    StartTick = 26
                    EndTick = 59
                    MotionTicks = 14
                    Offset = @{ X = 0.0; Y = -0.8; Z = 0.7 }
                    OffsetStep = @{ X = 0.0; Y = 0.055; Z = -0.045 }
                    Vertices = @(
                        (V -4.6 2.5 15.7), (V 4.6 2.5 15.7), (V 3.9 3.0 16.6), (V -3.9 3.0 16.6),
                        (V -3.2 0.6 8.8), (V -2.0 0.6 8.8), (V 0.6 2.8 12.6), (V -0.6 2.8 12.6)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_amber' 'pulse_amber'),
                        (Face @(4, 5, 6, 7) 'panel_white' 'glint')
                    )
                }
            )
        }
        @{
            Key = 'title'
            TimelineTicks = 48
            LoopTicks = 48
            Camera = @{
                X = 0.0
                Y = 1.0
                Z = -7.6
                YawDegrees = 10.0
                YawStepDegrees = -1.4
                PitchDegrees = -10.0
                PitchStepDegrees = 0.0
                ProjectScale = 112
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Groups = @(
                @{
                    Key = 'deck'
                    StartTick = 0
                    EndTick = 47
                    MotionTicks = 0
                    Vertices = @(
                        (V -10.6 -1.5 2.8), (V 10.6 -1.5 2.8), (V 7.8 -1.5 18.6), (V -7.8 -1.5 18.6),
                        (V -8.4 -0.7 5.9), (V 8.4 -0.7 5.9), (V 5.8 -0.7 16.1), (V -5.8 -0.7 16.1)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'floor_dark'),
                        (Face @(4, 5, 6, 7) 'panel_dark')
                    )
                }
                @{
                    Key = 'spire'
                    StartTick = 6
                    EndTick = 47
                    MotionTicks = 18
                    Offset = @{ X = 0.0; Y = -0.35; Z = 0.85 }
                    OffsetStep = @{ X = 0.0; Y = 0.03; Z = -0.025 }
                    YawDegrees = -4.0
                    YawStepDegrees = 0.18
                    Vertices = @(
                        (V -6.4 1.2 8.4), (V 6.4 1.2 8.4), (V 4.3 2.8 15.1), (V -4.3 2.8 15.1),
                        (V -2.5 -0.5 9.9), (V 2.5 -0.5 9.9), (V 1.8 1.8 13.4), (V -1.8 1.8 13.4)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_cyan' 'pulse_cyan'),
                        (Face @(4, 5, 6, 7) 'panel_amber')
                    )
                }
                @{
                    Key = 'signal'
                    StartTick = 16
                    EndTick = 47
                    MotionTicks = 12
                    Offset = @{ X = 0.0; Y = -0.25; Z = 0.45 }
                    OffsetStep = @{ X = 0.0; Y = 0.02; Z = -0.015 }
                    Vertices = @(
                        (V -5.0 2.4 16.2), (V 5.0 2.4 16.2), (V 4.3 2.9 17.1), (V -4.3 2.9 17.1),
                        (V -2.6 0.9 11.3), (V 2.6 0.9 11.3), (V 2.0 1.3 12.3), (V -2.0 1.3 12.3)
                    )
                    Faces = @(
                        (Face @(0, 1, 2, 3) 'panel_white' 'glint'),
                        (Face @(4, 5, 6, 7) 'panel_amber' 'pulse_amber')
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
            FloorBase = 'meadow_ground'
            FloorTrim = 'sun_warm'
            WallBase = 'sky_stone'
            WallTrim = 'panel_white'
            WallCap = 'panel_cyan'
            Lane = 'panel_white'
            GateMesh = 'portal_arch'
            TerminalMesh = 'switch_pedestal'
            SurgeMesh = 'lava_vent'
            ShardMesh = 'gem_cluster'
            Camera = @{
                Height = 5.05
                Distance = 7.20
                LookAhead = 1.05
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -17.0
                ProjectScale = 100
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 5.05
                    Distance = 7.20
                    LookAhead = 1.05
                    PitchDegrees = -17.0
                    ProjectScale = 100
                    Horizon = 38
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 4.80
                    Distance = 6.55
                    LookAhead = 1.25
                    PitchDegrees = -18.0
                    ProjectScale = 104
                    Horizon = 36
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.20
                }
                SectorEntry = @{
                    Height = 4.35
                    Distance = 8.95
                    LookAhead = 0.00
                    PitchDegrees = -14.0
                    ProjectScale = 94
                    Horizon = 40
                    FocusBiasX = 0.70
                    FocusBiasZ = -0.85
                }
                EnemyReveal = @{
                    Height = 4.65
                    Distance = 5.85
                    LookAhead = 0.20
                    PitchDegrees = -18.0
                    ProjectScale = 108
                    Horizon = 34
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                Interaction = @{
                    Height = 4.75
                    Distance = 5.90
                    LookAhead = 0.10
                    PitchDegrees = -20.0
                    ProjectScale = 106
                    Horizon = 35
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.15
                }
                WardenPressure = @{
                    Height = 4.60
                    Distance = 5.40
                    LookAhead = 0.15
                    PitchDegrees = -19.0
                    ProjectScale = 110
                    Horizon = 33
                    FocusBiasX = 0.00
                    FocusBiasZ = -0.10
                }
                EndBeat = @{
                    Height = 4.25
                    Distance = 5.10
                    LookAhead = 0.20
                    PitchDegrees = -21.0
                    ProjectScale = 112
                    Horizon = 32
                    FocusBiasX = 0.10
                    FocusBiasZ = 0.05
                }
            }
            Structure = @{
                NearInset = 0.45
                NearWidth = 0.34
                NearHeight = 1.55
                FarInset = 0.55
                FarHeight = 0.72
            }
            Framing = @{
                DoorFrameInset = 0.16
                DoorFrameWidth = 0.22
                DoorFrameHeight = 1.36
                RailInset = 0.52
                RailWidth = 0.18
                RailHeight = 0.78
                CeilingBeamHeight = 1.46
                CeilingBeamThickness = 0.24
                FarMassInset = 0.88
                FarMassWidth = 2.25
                FarMassHeight = 1.28
            }
            Landmark = @{
                Mesh = 'tower_toy'
            }
            Atmosphere = @{
                BackdropFar = 'PAL_CYAN'
                BackdropMid = 'PAL_CYAN2'
                BackdropNear = 'PAL_BG1'
                HorizonA = 'PAL_WHITE'
                HorizonB = 'PAL_AMBER'
                HorizonY = 38
                WobbleStrength = 0
            }
        }
        @{
            Key = 'sector2'
            FloorBase = 'floor_dark'
            FloorTrim = 'panel_amber'
            WallBase = 'furnace_wall'
            WallTrim = 'furnace_trim'
            WallCap = 'panel_dark'
            Lane = 'panel_amber'
            GateMesh = 'gate_furnace'
            TerminalMesh = 'terminal_furnace'
            SurgeMesh = 'surge_furnace'
            ShardMesh = 'shard_furnace'
            Camera = @{
                Height = 5.55
                Distance = 6.75
                LookAhead = 0.95
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -16.0
                ProjectScale = 96
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 5.55
                    Distance = 6.75
                    LookAhead = 0.95
                    PitchDegrees = -16.0
                    ProjectScale = 96
                    Horizon = 36
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 5.20
                    Distance = 6.10
                    LookAhead = 1.15
                    PitchDegrees = -18.0
                    ProjectScale = 100
                    Horizon = 33
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.25
                }
                SectorEntry = @{
                    Height = 4.90
                    Distance = 8.30
                    LookAhead = 0.00
                    PitchDegrees = -15.0
                    ProjectScale = 90
                    Horizon = 38
                    FocusBiasX = -0.55
                    FocusBiasZ = -0.80
                }
                EnemyReveal = @{
                    Height = 5.05
                    Distance = 5.45
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 106
                    Horizon = 31
                    FocusBiasX = 0.12
                    FocusBiasZ = 0.00
                }
                Interaction = @{
                    Height = 5.10
                    Distance = 5.70
                    LookAhead = 0.12
                    PitchDegrees = -20.0
                    ProjectScale = 102
                    Horizon = 32
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.20
                }
                WardenPressure = @{
                    Height = 4.95
                    Distance = 5.20
                    LookAhead = 0.10
                    PitchDegrees = -19.0
                    ProjectScale = 110
                    Horizon = 30
                    FocusBiasX = 0.18
                    FocusBiasZ = -0.15
                }
                EndBeat = @{
                    Height = 4.60
                    Distance = 4.80
                    LookAhead = 0.18
                    PitchDegrees = -22.0
                    ProjectScale = 112
                    Horizon = 28
                    FocusBiasX = 0.10
                    FocusBiasZ = 0.10
                }
            }
            Structure = @{
                NearInset = 0.40
                NearWidth = 0.38
                NearHeight = 1.65
                FarInset = 0.48
                FarHeight = 0.82
            }
            Framing = @{
                DoorFrameInset = 0.18
                DoorFrameWidth = 0.24
                DoorFrameHeight = 1.48
                RailInset = 0.54
                RailWidth = 0.20
                RailHeight = 0.84
                CeilingBeamHeight = 1.58
                CeilingBeamThickness = 0.26
                FarMassInset = 0.84
                FarMassWidth = 2.55
                FarMassHeight = 1.40
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
                HorizonY = 36
                WobbleStrength = 2
            }
        }
        @{
            Key = 'sector3'
            FloorBase = 'panel_dark'
            FloorTrim = 'lock_trim'
            WallBase = 'lock_wall'
            WallTrim = 'panel_red'
            WallCap = 'panel_dark'
            Lane = 'gate_glow'
            GateMesh = 'gate_lock'
            TerminalMesh = 'terminal_lock'
            SurgeMesh = 'surge_lock'
            ShardMesh = 'shard_lock'
            Camera = @{
                Height = 5.85
                Distance = 6.50
                LookAhead = 0.80
                HeadingNorthYawDegrees = 135.0
                HeadingEastYawDegrees = 45.0
                HeadingSouthYawDegrees = 315.0
                HeadingWestYawDegrees = 225.0
            }
            Projection = @{
                PitchDegrees = -14.0
                ProjectScale = 100
            }
            ShotRigs = @{
                BaseChase = @{
                    Height = 5.85
                    Distance = 6.50
                    LookAhead = 0.80
                    PitchDegrees = -14.0
                    ProjectScale = 100
                    Horizon = 32
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.00
                }
                MoveSettle = @{
                    Height = 5.40
                    Distance = 5.90
                    LookAhead = 1.00
                    PitchDegrees = -16.0
                    ProjectScale = 104
                    Horizon = 30
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.22
                }
                SectorEntry = @{
                    Height = 5.10
                    Distance = 8.00
                    LookAhead = 0.00
                    PitchDegrees = -13.0
                    ProjectScale = 92
                    Horizon = 34
                    FocusBiasX = 0.62
                    FocusBiasZ = -0.76
                }
                EnemyReveal = @{
                    Height = 5.20
                    Distance = 5.20
                    LookAhead = 0.10
                    PitchDegrees = -17.0
                    ProjectScale = 110
                    Horizon = 28
                    FocusBiasX = 0.08
                    FocusBiasZ = -0.04
                }
                Interaction = @{
                    Height = 5.30
                    Distance = 5.45
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 106
                    Horizon = 29
                    FocusBiasX = 0.00
                    FocusBiasZ = 0.18
                }
                WardenPressure = @{
                    Height = 5.00
                    Distance = 4.95
                    LookAhead = 0.10
                    PitchDegrees = -18.0
                    ProjectScale = 114
                    Horizon = 27
                    FocusBiasX = 0.20
                    FocusBiasZ = -0.22
                }
                EndBeat = @{
                    Height = 4.70
                    Distance = 4.60
                    LookAhead = 0.16
                    PitchDegrees = -21.0
                    ProjectScale = 116
                    Horizon = 26
                    FocusBiasX = 0.08
                    FocusBiasZ = 0.08
                }
            }
            Structure = @{
                NearInset = 0.36
                NearWidth = 0.42
                NearHeight = 1.75
                FarInset = 0.42
                FarHeight = 0.92
            }
            Framing = @{
                DoorFrameInset = 0.19
                DoorFrameWidth = 0.26
                DoorFrameHeight = 1.58
                RailInset = 0.58
                RailWidth = 0.18
                RailHeight = 0.90
                CeilingBeamHeight = 1.66
                CeilingBeamThickness = 0.28
                FarMassInset = 0.76
                FarMassWidth = 2.80
                FarMassHeight = 1.58
            }
            Landmark = @{
                Mesh = 'landmark_lock'
            }
            Atmosphere = @{
                BackdropFar = 'PAL_BLACK'
                BackdropMid = 'PAL_BG0'
                BackdropNear = 'PAL_PANEL'
                HorizonA = 'PAL_RED'
                HorizonB = 'PAL_WHITE'
                HorizonY = 32
                WobbleStrength = 2
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
