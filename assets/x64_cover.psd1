@{
    SchemaVersion = 1
    Cover = @{
        Id = 'neon-spine-visible-cover'
        HudText = 'SIGNAL MASKED'
        ActiveOnlyWithHostiles = $true
        Zones = @(
            @{
                Id = 'front-left-pillar'
                StateId = 1
                MinX = -132
                MaxX = -84
                MinZ = 96
                MaxZ = 128
                Blocker = @{ MinX = -120; MaxX = -92; NearZ = 138; FarZ = 186 }
            }
            @{
                Id = 'front-right-pillar'
                StateId = 2
                MinX = 84
                MaxX = 132
                MinZ = 96
                MaxZ = 128
                Blocker = @{ MinX = 92; MaxX = 120; NearZ = 138; FarZ = 186 }
            }
            @{
                Id = 'mid-center-column'
                StateId = 3
                MinX = -36
                MaxX = 36
                MinZ = 264
                MaxZ = 300
                Blocker = @{ MinX = -18; MaxX = 18; NearZ = 310; FarZ = 360 }
            }
        )
        Notes = 'Cover zones sit on the player-facing side of visible fallback geometry already authored in bootx64.asm. While the player point is inside a cover pocket, hostile exposure is cleared and lock acquisition cannot build. Movement grace and all existing damage timing remain unchanged.'
    }
}
