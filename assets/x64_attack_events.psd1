@{
    SchemaVersion = 1
    AttackEvents = @{
        Id = 'neon-spine-hostile-shots'
        DamageModel = 'existing-pressure-hit'
        Selection = 'round-robin-live-actors'
        TraceTicks = 12
        TraceColor = 16770669
        MuzzleHalfSize = 5
        Sources = @(
            @{ Id = 'warden'; SourceId = 1; AliveSymbol = 'EnemyAlive' }
            @{ Id = 'sentry-left'; SourceId = 2; AliveSymbol = 'SentryLeftAlive' }
            @{ Id = 'sentry-right'; SourceId = 3; AliveSymbol = 'SentryRightAlive' }
        )
        Notes = 'Every existing integrity hit is attributed to one currently-live hostile. Selection rotates through Warden, left sentry, and right sentry, skipping dead actors. The event only adds source attribution and a brief visible shot trace; it does not change exposure thresholds, cooldown, integrity damage, actor HP, or objective progression.'
    }
}
