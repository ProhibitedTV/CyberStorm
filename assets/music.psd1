@{
    Themes = @(
        @{
            Key = 'splash'
            Events = @(
                'C3 10'
                'REST 6'
                'G2 8'
                'REST 12'
                'LOOP'
            )
        }
        @{
            Key = 'title'
            Events = @(
                'G2 12'
                'REST 4'
                'D3 8'
                'REST 4'
                'C3 10'
                'REST 10'
                'G2 8'
                'REST 8'
                'LOOP'
            )
        }
        @{
            Key = 'run'
            Events = @(
                'G2 6'
                'REST 2'
                'G2 4'
                'REST 4'
                'C3 4'
                'REST 2'
                'D3 4'
                'REST 6'
                'A2 4'
                'REST 2'
                'C3 4'
                'REST 8'
                'LOOP'
            )
        }
        @{
            Key = 'win'
            Events = @(
                'C3 8'
                'E3 8'
                'G3 10'
                'REST 12'
                'LOOP'
            )
        }
        @{
            Key = 'lose'
            Events = @(
                'E3 8'
                'D3 8'
                'C3 12'
                'REST 12'
                'LOOP'
            )
        }
    )
}
