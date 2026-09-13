@{
    SchemaVersion = 1
    Mission = @{
        Id = 'neon-spine'
        Title = 'LEVEL 01 NEON SPINE'
        MaxLiveHostiles = 3
        ObjectiveStates = @(
            @{ State = 0; Id = 'clear-hostiles'; Prompt = 'ELIMINATE HOSTILES' }
            @{ State = 1; Id = 'breach-terminal'; Prompt = 'BREACH TERMINAL' }
            @{ State = 2; Id = 'survive-trace'; Prompt = 'BREAK TRACE / REACH EXIT' }
            @{ State = 3; Id = 'complete'; Prompt = 'MISSION COMPLETE' }
        )
        Actors = @(
            @{ Id = 'warden'; AliveSymbol = 'EnemyAlive'; HpSymbol = 'EnemyHp'; BaseHp = 3; Role = 'anchor' }
            @{ Id = 'sentry-left'; AliveSymbol = 'SentryLeftAlive'; HpSymbol = 'SentryLeftHp'; BaseHp = 1; Role = 'crossfire' }
            @{ Id = 'sentry-right'; AliveSymbol = 'SentryRightAlive'; HpSymbol = 'SentryRightHp'; BaseHp = 1; Role = 'crossfire' }
        )
        Responses = @(
            @{
                Id = 'terminal-trace'
                Trigger = 'objective-1-to-2'
                Telegraph = 'TRACE'
                TelegraphTicks = 45
                RuntimePrompt = 'BREAK TRACE / REACH EXIT'
                RuntimeStatus = 'TRACE RESPONSE'
                ExitLockedUntilClear = $true
                ExitVisualLockedUntilClear = $true
                Reactivate = @('sentry-left', 'sentry-right')
                Notes = 'Terminal breach reboots the two side sentries. This reuses existing actors and hit logic, creates a second combat beat, and avoids inventing a new spawn system for the first x64 vertical slice.'
            }
        )
        Tuning = @{
            ResponseSentryHp = 1
            ResponseCount = 2
            ResponseKillRequirement = 2
            MaxExtraShotsRequired = 2
        }
    }
}
