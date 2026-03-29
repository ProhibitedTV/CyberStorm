@{
    Demos = @(
        @{
            Name = 'SCOUT ATTRACT'
            StartSector = 1
            Seed = 0x1234
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
            Steps = @(
                'WAIT 6'
                'RIGHT 5'
                'UP 1'
                'PULSE 1'
                'LEFT 2'
                'UP 2'
                'RIGHT 2'
                'WAIT 5'
            )
        }
        @{
            Name = 'WARDEN ATTRACT'
            StartSector = 3
            Seed = 0x3579
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
