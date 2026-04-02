@{
    Demos = @(
        @{
            Name = 'SCOUT ATTRACT'
            StartSector = 1
            Seed = 0x1234
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
            Name = 'SURGE ATTRACT'
            StartSector = 2
            Seed = 0x2468
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
            Name = 'WARDEN ATTRACT'
            StartSector = 3
            Seed = 0x3579
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
    )
}
