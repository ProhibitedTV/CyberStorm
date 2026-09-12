@{
    SchemaVersion = 1
    Presentation = @{
        Id = 'neon-spine-hostile-fire'
        RequiresCombatProfile = 'neon-spine-integrity'
        LockTargetX = 320
        LockTargetY = 240
        LockColor = 0x00FF90FF
        LockPulseColor = 0x00FF4058
        ImpactColor = 0x00FF4058
        ImpactInset = 16
        ImpactCrossHalfSize = 30
        PulseMask = 8
        Sources = @(
            @{ Id = 'warden'; AliveSymbol = 'EnemyAlive'; X = 0; Y = 28; Z = 188 }
            @{ Id = 'sentry-left'; AliveSymbol = 'SentryLeftAlive'; X = -99; Y = 18; Z = 282 }
            @{ Id = 'sentry-right'; AliveSymbol = 'SentryRightAlive'; X = 99; Y = 18; Z = 282 }
        )
        Notes = 'Presentation only. Once ExposureTicks reaches the existing warning threshold, every live hostile projects a lock beam from its authored world-space weapon point toward the center of the player view. DamageFlashTicks replaces the beams with a hard red viewport frame/cross. This does not change exposure, integrity, damage cadence, or objective logic.'
    }
}
