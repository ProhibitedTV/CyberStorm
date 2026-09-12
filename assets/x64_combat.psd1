@{
    SchemaVersion = 1
    Combat = @{
        Id = 'neon-spine-integrity'
        TickUsec = 10000
        IntegrityMax = 3
        EngageWorldZ = 96
        InitialGraceTicks = 250
        MoveGraceTicks = 45
        ExposureTicksPerHit = 90
        ExposureWarningTicks = 45
        DamageCooldownTicks = 100
        DamageFlashTicks = 24
        RebootNoticeTicks = 90
        FailAction = 'restart-level'
        ThreatActors = @('warden', 'sentry-left', 'sentry-right')
        Rank = @{
            SRequiresFullIntegrity = $true
            SRequiresPerfectAccuracy = $true
            ARequiresIntegrity = 3
            AMaxShotsPerHit = 2
            BRequiresIntegrity = 2
            BMaxShotsPerHit = 3
            DefaultRank = 'C'
        }
        Notes = 'Pressure is an authored lock-on abstraction for the first x64 vertical slice. Moving clears exposure and grants a short grace window; standing exposed while any hostile is alive eventually costs integrity. Zero integrity restarts LEVEL 01 rather than adding a separate death screen before the combat loop is proven. Mission completion grades accuracy plus remaining integrity to give the short vertical slice an immediate replay target.'
    }
}
