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

function Face {
    param(
        [int[]]$Indices,
        [string]$Material
    )

    return @{
        Indices = $Indices
        Material = $Material
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
    )
    Scenes = @(
        @{
            Key = 'splash'
            Camera = @{
                X = 0.0
                Y = 1.15
                Z = -7.5
                YawDegrees = 0.0
                YawStepDegrees = 0.45
                PitchDegrees = -14.0
                PitchStepDegrees = 0.0
                ProjectScale = 114
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Vertices = @(
                (V -12.0 -1.5 3.0), (V 12.0 -1.5 3.0), (V 8.0 -1.5 18.0), (V -8.0 -1.5 18.0),
                (V -3.6 -0.2 6.4), (V 3.6 -0.2 6.4), (V 2.4 -0.2 11.5), (V -2.4 -0.2 11.5),
                (V -6.7 -1.5 8.0), (V -5.4 2.8 8.6), (V -4.6 2.8 12.4), (V -6.0 -1.5 12.0),
                (V 6.7 -1.5 8.0), (V 5.4 2.8 8.6), (V 4.6 2.8 12.4), (V 6.0 -1.5 12.0),
                (V -1.8 -1.0 12.4), (V 1.8 -1.0 12.4), (V 1.2 1.8 13.5), (V -1.2 1.8 13.5),
                (V -5.8 1.6 16.8), (V 5.8 1.6 16.8), (V 5.1 2.3 17.6), (V -5.1 2.3 17.6)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 6, 7) 'panel_cyan'),
                (Face @(8, 9, 10, 11) 'wall_dark'),
                (Face @(12, 13, 14, 15) 'wall_dark'),
                (Face @(16, 17, 18, 19) 'panel_white'),
                (Face @(20, 21, 22, 23) 'panel_amber')
            )
        }
        @{
            Key = 'title'
            Camera = @{
                X = 0.0
                Y = 0.9
                Z = -7.2
                YawDegrees = 8.0
                YawStepDegrees = -0.18
                PitchDegrees = -11.0
                PitchStepDegrees = 0.0
                ProjectScale = 108
                Viewport = @{ X = 0; Y = 0; W = 320; H = 200 }
            }
            Vertices = @(
                (V -10.0 -1.4 3.0), (V 10.0 -1.4 3.0), (V 7.2 -1.4 18.0), (V -7.2 -1.4 18.0),
                (V -8.0 -0.7 6.2), (V 8.0 -0.7 6.2), (V 5.0 -0.7 15.8), (V -5.0 -0.7 15.8),
                (V -6.2 1.0 8.1), (V 6.2 1.0 8.1), (V 4.0 2.5 15.0), (V -4.0 2.5 15.0),
                (V -2.1 -0.4 10.3), (V 2.1 -0.4 10.3), (V 1.4 1.6 13.2), (V -1.4 1.6 13.2)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 6, 7) 'panel_dark'),
                (Face @(8, 9, 10, 11) 'panel_cyan'),
                (Face @(12, 13, 14, 15) 'panel_amber')
            )
        }
        @{
            Key = 'sector1'
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
            Vertices = @(
                (V -5.5 -1.0 3.0), (V 5.5 -1.0 3.0), (V 3.6 -1.0 10.0), (V -3.6 -1.0 10.0),
                (V -2.7 -0.1 5.6), (V 2.7 -0.1 5.6), (V 1.8 1.5 8.8), (V -1.8 1.5 8.8),
                (V -4.2 0.4 6.6), (V -3.2 2.0 8.8), (V 4.2 0.4 6.6), (V 3.2 2.0 8.8)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 6, 7) 'panel_cyan'),
                (Face @(8, 9, 7, 4) 'panel_white'),
                (Face @(5, 10, 11, 6) 'panel_amber')
            )
        }
        @{
            Key = 'sector2'
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
            Vertices = @(
                (V -5.6 -1.0 3.0), (V 5.6 -1.0 3.0), (V 3.7 -1.0 10.0), (V -3.7 -1.0 10.0),
                (V -4.8 -0.3 4.8), (V -3.5 1.7 7.6), (V -2.1 -0.3 8.5), (V -0.9 1.2 9.8),
                (V 4.8 -0.3 4.8), (V 3.5 1.7 7.6), (V 2.1 -0.3 8.5), (V 0.9 1.2 9.8)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 7, 6) 'panel_red'),
                (Face @(8, 9, 11, 10) 'panel_amber'),
                (Face @(6, 10, 11, 7) 'panel_dark')
            )
        }
        @{
            Key = 'sector3'
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
            Vertices = @(
                (V -5.8 -1.0 3.0), (V 5.8 -1.0 3.0), (V 3.9 -1.0 10.4), (V -3.9 -1.0 10.4),
                (V -1.7 -0.3 5.8), (V 1.7 -0.3 5.8), (V 1.2 2.1 8.8), (V -1.2 2.1 8.8),
                (V -4.9 0.2 7.2), (V -4.2 2.3 9.6), (V 4.9 0.2 7.2), (V 4.2 2.3 9.6)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 6, 7) 'gate_glow'),
                (Face @(8, 9, 7, 4) 'panel_red'),
                (Face @(5, 10, 11, 6) 'panel_white')
            )
        }
        @{
            Key = 'win'
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
            Vertices = @(
                (V -9.8 -1.4 3.0), (V 9.8 -1.4 3.0), (V 7.0 -1.4 17.0), (V -7.0 -1.4 17.0),
                (V -4.3 -0.8 7.8), (V 4.3 -0.8 7.8), (V 2.8 2.0 12.4), (V -2.8 2.0 12.4),
                (V -7.0 -0.4 11.2), (V -5.8 2.2 13.8), (V 7.0 -0.4 11.2), (V 5.8 2.2 13.8)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 6, 7) 'gate_glow'),
                (Face @(8, 9, 7, 4) 'panel_cyan'),
                (Face @(5, 10, 11, 6) 'panel_white')
            )
        }
        @{
            Key = 'lose'
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
            Vertices = @(
                (V -9.8 -1.4 3.0), (V 9.8 -1.4 3.0), (V 7.0 -1.4 17.0), (V -7.0 -1.4 17.0),
                (V -4.3 -0.8 7.8), (V 4.3 -0.8 7.8), (V 2.8 2.0 12.4), (V -2.8 2.0 12.4),
                (V -7.0 -0.4 11.2), (V -5.8 2.2 13.8), (V 7.0 -0.4 11.2), (V 5.8 2.2 13.8)
            )
            Faces = @(
                (Face @(0, 1, 2, 3) 'floor_dark'),
                (Face @(4, 5, 6, 7) 'panel_red'),
                (Face @(8, 9, 7, 4) 'panel_dark'),
                (Face @(5, 10, 11, 6) 'panel_white')
            )
        }
    )
}
