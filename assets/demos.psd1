@{
    Demos = @(
        @{
            Id = 'subgrid-attract-a'
            Name = 'SUBGRID BEAUTY PASS'
            StartSector = 1
            Seed = 0x1234
            Attract = $true
            CaptureRole = 'beauty'
            DistrictName = 'SUBGRID INGRESS'
            Purpose = 'Storm-gate reveal'
            CaptureTicks = 52
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '6,10'
                Heading = 'NORTH'
                Data = 1
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 100
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'FORWARD 12'
                'TURNRIGHT 4'
                'FORWARD 10'
                'WAIT 8'
            )
        }
        @{
            Id = 'subgrid-attract-b'
            Name = 'SUBGRID ACTION PASS'
            StartSector = 1
            Seed = 0x2468
            Attract = $true
            CaptureRole = 'action'
            DistrictName = 'SUBGRID INGRESS'
            Purpose = 'Dash-strike pass'
            CaptureTicks = 50
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '8,12'
                Heading = 'EAST'
                Data = 1
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 1
                Score = 170
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'CHARGE 1'
                'WAIT 12'
                'WAIT 6'
            )
        }
        @{
            Id = 'adventure-idle-verify'
            Name = 'ADVENTURE IDLE VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 46
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '4,12'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 46'
            )
        }
        @{
            Id = 'adventure-turn-verify'
            Name = 'ADVENTURE TURN VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 48
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '4,12'
                Heading = 'NORTH'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'TURNRIGHT 4'
                'WAIT 4'
            )
        }
        @{
            Id = 'adventure-run-verify'
            Name = 'ADVENTURE RUN VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 56
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '6,12'
                Heading = 'EAST'
                Data = 1
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 100
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'FORWARD 12'
                'WAIT 4'
            )
        }
        @{
            Id = 'adventure-jump-glide-verify'
            Name = 'ADVENTURE JUMP GLIDE VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 64
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '4,12'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'JUMP 1'
                'GLIDE 12'
                'WAIT 8'
            )
        }
        @{
            Id = 'adventure-charge-hit-verify'
            Name = 'ADVENTURE CHARGE HIT VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 58
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '8,12'
                Heading = 'EAST'
                Data = 1
                Objectives = 0
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 1
                Score = 170
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'CHARGE 1'
                'WAIT 14'
                'WAIT 3'
            )
        }
        @{
            Id = 'adventure-switch-verify'
            Name = 'ADVENTURE SWITCH VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 66
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '10,12'
                Heading = 'EAST'
                Data = 1
                Objectives = 1
                ObjectivesTotal = 2
                Key = $false
                Portal = 'LOCKED'
                Kills = 1
                Score = 170
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'CHARGE 1'
                'WAIT 10'
                'FORWARD 2'
                'FLAME 1'
                'WAIT 4'
            )
        }
        @{
            Id = 'adventure-key-verify'
            Name = 'ADVENTURE KEY VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 92
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '18,4'
                Heading = 'NORTH'
                Data = 8
                Objectives = 1
                ObjectivesTotal = 2
                Key = $true
                Portal = 'LOCKED'
                Kills = 1
                Score = 870
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'CHARGE 1'
                'WAIT 10'
                'TURNRIGHT 4'
                'FORWARD 18'
                'TURNLEFT 4'
                'FORWARD 14'
                'WAIT 2'
            )
        }
        @{
            Id = 'adventure-portal-unlock-verify'
            Name = 'ADVENTURE PORTAL UNLOCK VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 120
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 1
                Player = '24,2'
                Heading = 'EAST'
                Data = 20
                Objectives = 2
                ObjectivesTotal = 2
                Key = $true
                Portal = 'OPEN'
                Kills = 1
                Score = 2070
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'CHARGE 1'
                'WAIT 10'
                'TURNRIGHT 4'
                'FORWARD 18'
                'TURNLEFT 4'
                'FORWARD 16'
                'FLAME 1'
                'TURNRIGHT 4'
                'FORWARD 14'
                'WAIT 8'
            )
        }
        @{
            Id = 'adventure-portal-complete-verify'
            Name = 'ADVENTURE PORTAL COMPLETE VERIFY'
            StartSector = 1
            Seed = 0x1357
            Attract = $false
            CaptureRole = 'technical'
            CaptureTicks = 136
            RuntimeVerify = $true
            RuntimeCheckpoints = $false
            Expected = @{
                State = 'WIN'
                Sector = 1
                Player = '24,2'
                Heading = 'EAST'
                Data = 20
                Objectives = 2
                ObjectivesTotal = 2
                Key = $true
                Portal = 'OPEN'
                Kills = 1
                Score = 2070
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 40'
                'CHARGE 1'
                'WAIT 10'
                'TURNRIGHT 4'
                'FORWARD 18'
                'TURNLEFT 4'
                'FORWARD 16'
                'FLAME 1'
                'TURNRIGHT 4'
                'FORWARD 14'
                'ENTER 1'
                'WAIT 12'
            )
        }
        @{
            Id = 'switchyard-attract-a'
            Name = 'SWITCHYARD BEAUTY PASS'
            StartSector = 2
            Seed = 0x3579
            Attract = $true
            CaptureRole = 'beauty'
            DistrictName = 'SWITCHYARD SPINE'
            Purpose = 'Hinge-yard reveal'
            CaptureTicks = 58
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Player = '2,13'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 3
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 28'
                'FORWARD 10'
                'TURNLEFT 4'
                'FORWARD 12'
                'WAIT 8'
            )
        }
        @{
            Id = 'switchyard-attract-b'
            Name = 'SWITCHYARD ACTION PASS'
            StartSector = 2
            Seed = 0x468A
            Attract = $true
            CaptureRole = 'action'
            DistrictName = 'SWITCHYARD SPINE'
            Purpose = 'Combat pass'
            CaptureTicks = 54
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 2
                Player = '2,13'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 3
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 24'
                'FORWARD 8'
                'CHARGE 1'
                'WAIT 10'
                'FLAME 1'
                'WAIT 10'
            )
        }
        @{
            Id = 'thermal-attract-a'
            Name = 'THERMAL BEAUTY PASS'
            StartSector = 3
            Seed = 0x579B
            Attract = $true
            CaptureRole = 'beauty'
            DistrictName = 'THERMAL FOUNDRY'
            Purpose = 'Smelter-rise reveal'
            CaptureTicks = 60
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 3
                Player = '2,13'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 3
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 30'
                'FORWARD 12'
                'TURNLEFT 4'
                'FORWARD 10'
                'WAIT 8'
            )
        }
        @{
            Id = 'thermal-attract-b'
            Name = 'THERMAL ACTION PASS'
            StartSector = 3
            Seed = 0x68AC
            Attract = $true
            CaptureRole = 'action'
            DistrictName = 'THERMAL FOUNDRY'
            Purpose = 'Hazard pass'
            CaptureTicks = 56
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 3
                Player = '2,13'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 3
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 22'
                'FORWARD 8'
                'FLAME 1'
                'WAIT 8'
                'CHARGE 1'
                'WAIT 10'
            )
        }
        @{
            Id = 'vault-attract-a'
            Name = 'VAULT BEAUTY PASS'
            StartSector = 4
            Seed = 0x79BD
            Attract = $true
            CaptureRole = 'beauty'
            DistrictName = 'APEX VAULT'
            Purpose = 'Final-breach reveal'
            CaptureTicks = 62
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 4
                Player = '2,13'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 3
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 30'
                'FORWARD 10'
                'TURNRIGHT 4'
                'WAIT 6'
                'FORWARD 12'
                'WAIT 8'
            )
        }
        @{
            Id = 'vault-attract-b'
            Name = 'VAULT ACTION PASS'
            StartSector = 4
            Seed = 0x8ACE
            Attract = $true
            CaptureRole = 'action'
            DistrictName = 'APEX VAULT'
            Purpose = 'Warden finale pass'
            CaptureTicks = 58
            RuntimeVerify = $false
            Expected = @{
                State = 'PLAYING'
                Sector = 4
                Player = '2,13'
                Heading = 'EAST'
                Data = 0
                Objectives = 0
                ObjectivesTotal = 3
                Key = $false
                Portal = 'LOCKED'
                Kills = 0
                Score = 0
                Actions = 0
                Hits = 0
                PulsesUsed = 0
                Spoof = 0
            }
            Steps = @(
                'WAIT 24'
                'FORWARD 8'
                'CHARGE 1'
                'WAIT 8'
                'TURNLEFT 4'
                'FLAME 1'
                'WAIT 8'
            )
        }
    )
}
