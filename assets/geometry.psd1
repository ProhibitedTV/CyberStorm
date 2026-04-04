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
        @{ Key = 'vault_wall'; Base = 11; Dither = 6 }
        @{ Key = 'vault_trim'; Base = 6; Dither = 7 }
        @{ Key = 'furnace_wall'; Base = 10; Dither = 8 }
        @{ Key = 'furnace_trim'; Base = 8; Dither = 7 }
        @{ Key = 'lock_wall'; Base = 3; Dither = 10 }
        @{ Key = 'lock_trim'; Base = 17; Dither = 10 }
        @{ Key = 'console_cyan'; Base = 5; Dither = 7 }
        @{ Key = 'console_amber'; Base = 8; Dither = 7 }
        @{ Key = 'console_red'; Base = 10; Dither = 7 }
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
            FloorBase = 'floor_dark'
            FloorTrim = 'panel_cyan'
            WallBase = 'vault_wall'
            WallTrim = 'vault_trim'
            WallCap = 'panel_dark'
            Lane = 'panel_cyan'
            GateMesh = 'gate_vault'
            TerminalMesh = 'terminal_vault'
            SurgeMesh = 'surge_vault'
            ShardMesh = 'shard_vault'
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
            Key = 'player_runner'
            Vertices = @(
                (M -38 0 -28), (M 38 0 -28), (M 38 0 28), (M -38 0 28),
                (M -44 118 -20), (M 44 118 -20), (M 30 152 28), (M -30 152 28),
                (M -18 252 -4), (M 18 252 -4), (M 0 318 -22)
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
                (M -46 0 -34), (M 46 0 -34), (M 46 0 34), (M -46 0 34),
                (M -56 136 -24), (M 56 136 -24), (M 40 188 34), (M -40 188 34),
                (M -28 284 -6), (M 28 284 -6), (M 0 356 -30)
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
