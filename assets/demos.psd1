@{
    Demos = @(
        @{
            Id = 'scout-attract'
            Name = 'SCOUT ATTRACT'
            StartSector = 1
            Seed = 0x1234
            CaptureRole = 'gameplay'
            CaptureTicks = 15
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '7,13'
                Shields = 5
                Pulses = 2
                Data = 1
                Kills = 0
                AliveEnemies = 5
                Score = 100
                Actions = 10
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'WAIT 8'
                'RIGHT 4'
                'UP 2'
                'PULSE 1'
                'RIGHT 3'
                'DOWN 1'
                'LEFT 2'
                'WAIT 6'
            )
        }
        @{
            Id = 'surge-attract'
            Name = 'SURGE ATTRACT'
            StartSector = 2
            Seed = 0x2468
            CaptureRole = 'hazard'
            CaptureTicks = 18
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '8,11'
                Shields = 5
                Pulses = 3
                Data = 1
                Kills = 1
                AliveEnemies = 6
                Score = 170
                Actions = 13
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0xA7CC
            }
            Steps = @(
                'WAIT 4'
                'RIGHT 8'
                'UP 4'
                'RIGHT 2'
                'PULSE 1'
                'LEFT 2'
                'WAIT 5'
            )
        }
        @{
            Id = 'warden-attract'
            Name = 'WARDEN ATTRACT'
            StartSector = 3
            Seed = 0x3579
            CaptureRole = 'elite-pressure'
            CaptureTicks = 12
            RuntimeVerify = $false
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 3
                Map = 'sector3_map_c'
                Player = '6,13'
                Shields = 5
                Pulses = 4
                Data = 1
                Kills = 0
                AliveEnemies = 10
                Score = 100
                Actions = 7
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0x88BA
            }
            Steps = @(
                'WAIT 6'
                'RIGHT 3'
                'UP 1'
                'PULSE 1'
                'RIGHT 2'
                'DOWN 1'
                'LEFT 1'
                'UP 2'
                'WAIT 4'
            )
        }
        @{
            Id = 'sector1-depth-showcase'
            Name = 'SECTOR 1 DEPTH SHOWCASE'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $true
            CaptureRole = 'sector1-depth'
            CaptureTicks = 10
            RuntimeVerify = $false
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '7,12'
                Shields = 5
                Pulses = 3
                Data = 1
                Kills = 0
                AliveEnemies = 5
                Score = 100
                Actions = 6
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'RIGHT 5'
                'UP 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'sector1-threat-showcase'
            Name = 'SECTOR 1 THREAT SHOWCASE'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $true
            CaptureRole = 'sector1-threat'
            CaptureTicks = 15
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '7,13'
                Shields = 5
                Pulses = 2
                Data = 1
                Kills = 0
                AliveEnemies = 5
                Score = 100
                Actions = 10
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'WAIT 8'
                'RIGHT 4'
                'UP 2'
                'PULSE 1'
                'RIGHT 3'
                'DOWN 1'
                'LEFT 2'
                'WAIT 6'
            )
        }
        @{
            Id = 'sector2-depth-showcase'
            Name = 'SECTOR 2 DEPTH SHOWCASE'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $true
            CaptureRole = 'sector2-depth'
            CaptureTicks = 12
            RuntimeVerify = $false
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '7,7'
                Shields = 5
                Pulses = 4
                Data = 0
                Kills = 1
                AliveEnemies = 6
                Score = 70
                Actions = 15
                Hits = 0
                PulsesUsed = 0
                Spoof = 2
                Rng = 0xA7CC
            }
            Steps = @(
                'RIGHT 1'
                'UP 2'
                'LEFT 2'
                'UP 4'
                'RIGHT 6'
                'WAIT 1'
            )
        }
        @{
            Id = 'sector2-threat-showcase'
            Name = 'SECTOR 2 THREAT SHOWCASE'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $true
            CaptureRole = 'sector2-threat'
            CaptureTicks = 18
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '8,11'
                Shields = 5
                Pulses = 3
                Data = 1
                Kills = 1
                AliveEnemies = 6
                Score = 170
                Actions = 13
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0xA7CC
            }
            Steps = @(
                'WAIT 4'
                'RIGHT 8'
                'UP 4'
                'RIGHT 2'
                'PULSE 1'
                'LEFT 2'
                'WAIT 5'
            )
        }
        @{
            Id = 'sector3-depth-showcase'
            Name = 'SECTOR 3 DEPTH SHOWCASE'
            StartSector = 3
            Seed = 0x3579
            Attract = $false
            Showcase = $true
            CaptureRole = 'sector3-depth'
            CaptureTicks = 8
            RuntimeVerify = $false
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 3
                Map = 'sector3_map_c'
                Player = '5,13'
                Shields = 5
                Pulses = 5
                Data = 1
                Kills = 0
                AliveEnemies = 10
                Score = 100
                Actions = 3
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x88BA
            }
            Steps = @(
                'RIGHT 3'
                'UP 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'sector3-threat-showcase'
            Name = 'SECTOR 3 THREAT SHOWCASE'
            StartSector = 3
            Seed = 0x3579
            Attract = $false
            Showcase = $true
            CaptureRole = 'sector3-threat'
            CaptureTicks = 12
            RuntimeVerify = $false
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 3
                Map = 'sector3_map_c'
                Player = '6,13'
                Shields = 5
                Pulses = 4
                Data = 1
                Kills = 0
                AliveEnemies = 10
                Score = 100
                Actions = 7
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0x88BA
            }
            Steps = @(
                'WAIT 6'
                'RIGHT 3'
                'UP 1'
                'PULSE 1'
                'RIGHT 2'
                'DOWN 1'
                'LEFT 1'
                'UP 2'
                'WAIT 4'
            )
        }
        @{
            Id = 'warden-pressure-verify'
            Name = 'WARDEN PRESSURE VERIFY'
            StartSector = 3
            Seed = 0x3579
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 10
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 3
                Map = 'sector3_map_c'
                Player = '5,13'
                Shields = 5
                Pulses = 5
                Data = 1
                Kills = 0
                AliveEnemies = 10
                Score = 100
                Actions = 3
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x88BA
            }
            Steps = @(
                'RIGHT 3'
                'UP 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'rusher-mesh-verify'
            Name = 'RUSHER MESH VERIFY'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 4
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '2,13'
                Shields = 5
                Pulses = 4
                Data = 0
                Kills = 0
                AliveEnemies = 7
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0xA7CC
            }
            Steps = @(
                'WAIT 2'
            )
        }
        @{
            Id = 'flanker-mesh-verify'
            Name = 'FLANKER MESH VERIFY'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 14
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '8,11'
                Shields = 5
                Pulses = 3
                Data = 1
                Kills = 1
                AliveEnemies = 6
                Score = 170
                Actions = 13
                Hits = 0
                PulsesUsed = 1
                Spoof = 0
                Rng = 0xA7CC
            }
            Steps = @(
                'WAIT 4'
                'RIGHT 8'
                'UP 4'
                'RIGHT 2'
                'PULSE 1'
                'LEFT 2'
                'WAIT 5'
            )
        }
        @{
            Id = 'far-exit-verify'
            Name = 'FAR EXIT VERIFY'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 4
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '2,13'
                Shields = 5
                Pulses = 4
                Data = 0
                Kills = 0
                AliveEnemies = 7
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0xA7CC
            }
            Steps = @(
                'WAIT 2'
            )
        }
        @{
            Id = 'camera-east-verify'
            Name = 'CAMERA EAST VERIFY'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 6
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '3,13'
                Shields = 5
                Pulses = 3
                Data = 0
                Kills = 0
                AliveEnemies = 5
                Score = 0
                Actions = 1
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'RIGHT 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'camera-west-verify'
            Name = 'CAMERA WEST VERIFY'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 8
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '2,13'
                Shields = 5
                Pulses = 3
                Data = 0
                Kills = 0
                AliveEnemies = 5
                Score = 0
                Actions = 2
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'RIGHT 1'
                'LEFT 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'camera-north-verify'
            Name = 'CAMERA NORTH VERIFY'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 12
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '7,12'
                Shields = 5
                Pulses = 3
                Data = 1
                Kills = 0
                AliveEnemies = 5
                Score = 100
                Actions = 6
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'RIGHT 5'
                'UP 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'camera-south-verify'
            Name = 'CAMERA SOUTH VERIFY'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 14
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '7,13'
                Shields = 5
                Pulses = 3
                Data = 1
                Kills = 0
                AliveEnemies = 5
                Score = 100
                Actions = 7
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'RIGHT 5'
                'UP 1'
                'DOWN 1'
                'WAIT 1'
            )
        }
        @{
            Id = 'sector-entry-verify'
            Name = 'SECTOR ENTRY VERIFY'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 4
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '2,13'
                Shields = 5
                Pulses = 4
                Data = 0
                Kills = 0
                AliveEnemies = 7
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
                Rng = 0xA7CC
            }
            Steps = @(
                'WAIT 2'
            )
        }
        @{
            Id = 'terminal-spoof-verify'
            Name = 'TERMINAL SPOOF VERIFY'
            StartSector = 2
            Seed = 0x2468
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 16
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Map = 'sector2_map_b'
                Player = '7,7'
                Shields = 5
                Pulses = 4
                Data = 0
                Kills = 1
                AliveEnemies = 6
                Score = 70
                Actions = 15
                Hits = 0
                PulsesUsed = 0
                Spoof = 2
                Rng = 0xA7CC
            }
            Steps = @(
                'RIGHT 1'
                'UP 2'
                'LEFT 2'
                'UP 4'
                'RIGHT 6'
                'WAIT 1'
            )
        }
        @{
            Id = 'gate-unlock-verify'
            Name = 'GATE UNLOCK VERIFY'
            StartSector = 1
            Seed = 0x1234
            Attract = $false
            Showcase = $false
            CaptureRole = 'technical'
            CaptureTicks = 58
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Map = 'sector1_map_c'
                Player = '24,3'
                Shields = 4
                Pulses = 3
                Data = 4
                Kills = 1
                AliveEnemies = 3
                Score = 430
                Actions = 68
                Hits = 1
                PulsesUsed = 0
                Spoof = 0
                Rng = 0x764A
            }
            Steps = @(
                'RIGHT 2'
                'RIGHT 5'
                'UP 2'
                'DOWN 2'
                'RIGHT 6'
                'UP 2'
                'LEFT 4'
                'UP 2'
                'RIGHT 4'
                'LEFT 4'
                'DOWN 2'
                'RIGHT 4'
                'DOWN 2'
                'RIGHT 4'
                'UP 2'
                'DOWN 2'
                'RIGHT 7'
                'UP 10'
                'LEFT 2'
                'WAIT 2'
            )
        }
    )
}
