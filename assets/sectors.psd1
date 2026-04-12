@{
    Sectors = @(
        @{
            Id = 1
            Title = 'SCOUT'
            Intro = 'SCOUT GRID LIVE. OPEN LANES FAVOR CLEAN CHASES.'
            Rules = @{
                SurgeCount = 0
                TerminalCount = 1
                EnemyBonus = 0
                FlankerThreshold = 48
                WardenThreshold = 0
                WardenEngageDistance = 6
            }
            Maps = @(
                @{
                    Name = 'sector1_map_a'
                    Scenario = @{
                        Name = 'FORK SPIKE'
                        Entry = 'LEFT FORK FIRST. CUT CENTER BEFORE THE PINCH.'
                        ShardPool = @('5,13', '8,9', '13,7', '18,9', '19,5', '23,3')
                    }
                    Anchors = @{
                        Terminals = @('10,7')
                    }
                    Rows = @(
                        '############################'
                        '#..........#...............#'
                        '#..####....#..#####..####..#'
                        '#......#...#......#.....#..#'
                        '#.####.#...####...#.###.#..#'
                        '#.#....#..........#.#...#..#'
                        '#.#.########..#####.#.###..#'
                        '#.#..................#.....#'
                        '#.#.######.######.####.##..#'
                        '#...#....#......#......##..#'
                        '###.#.##.####.#.######.##..#'
                        '#...#.##......#.#......##..#'
                        '#.###.#########.#.########.#'
                        '#..........................#'
                        '############################'
                    )
                }
                @{
                    Name = 'sector1_map_b'
                    Scenario = @{
                        Name = 'CROSSLANE LURE'
                        Entry = 'THE FIRST FLANK CROSSES MID. DO NOT CHASE BLIND.'
                        ShardPool = @('4,13', '8,11', '11,9', '16,7', '20,11', '23,3')
                    }
                    Anchors = @{
                        Terminals = @('8,7')
                        Enemies = @(
                            @{ X = 18; Y = 7; Kind = 'FLANKER' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#....#..............#......#'
                        '#.##.#.######.####..#.###..#'
                        '#.#..#......#....#..#...#..#'
                        '#.#.####.##.#.##.####.#.#..#'
                        '#.#......##.#.##......#.#..#'
                        '#.######....#....######.#..#'
                        '#........#######........#..#'
                        '#.######....#....######.#..#'
                        '#.#......##.#.##......#.#..#'
                        '#.#.####.##.#.##.####.#.#..#'
                        '#.#....#....#....#....#.#..#'
                        '#.####.######.######.##.#..#'
                        '#..........................#'
                        '############################'
                    )
                }
                @{
                    Name = 'sector1_map_c'
                    Scenario = @{
                        Name = 'SPINE THREAD'
                        Entry = 'CROSS EARLY. THE RIGHT LANE TIGHTENS FAST.'
                        ShardPool = @('4,13', '9,11', '15,13', '15,9', '19,11', '24,3')
                    }
                    Anchors = @{
                        Terminals = @('10,7')
                        Enemies = @(
                            @{ X = 20; Y = 7; Kind = 'FLANKER' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#..........#.....#.........#'
                        '#.######.#.#.###.#.######..#'
                        '#......#.#.#...#.#.#.......#'
                        '######.#.#.###.#.#.#.#####.#'
                        '#......#.#.....#.#.#.....#.#'
                        '#.######.#####.#.#.#####.#.#'
                        '#.#...........#.#.#.....#..#'
                        '#.#.###########.#.#.###.##.#'
                        '#.#.......#.....#.#...#....#'
                        '#.#######.#.#####.###.####.#'
                        '#.......#.#.....#...#....#.#'
                        '#.#####.#.#####.###.####.#.#'
                        '#..........................#'
                        '############################'
                    )
                }
            )
        }
        @{
            Id = 2
            Title = 'SURGE'
            Intro = 'SURGE FURNACE LIVE. ARC NODES BITE BOTH SIDES.'
            Rules = @{
                SurgeCount = 3
                TerminalCount = 2
                EnemyBonus = 0
                FlankerThreshold = 112
                WardenThreshold = 0
                WardenEngageDistance = 6
            }
            Maps = @(
                @{
                    Name = 'sector2_map_a'
                    Scenario = @{
                        Name = 'FURNACE FORK'
                        Entry = 'HOT MIDLINE SHARDS PAY OFF IF YOU SELL THE CHASE.'
                        ShardPool = @('5,13', '11,11', '14,7', '17,5', '20,3', '24,1')
                    }
                    Anchors = @{
                        Terminals = @('10,7', '20,9')
                        Surges = @('14,5', '22,7')
                        Enemies = @(
                            @{ X = 20; Y = 11; Kind = 'FLANKER' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#......#....#.........#....#'
                        '#.####.#.##.#.######..#....#'
                        '#.#....#....#......#..#....#'
                        '#.#.####.########..#.##.##.#'
                        '#.#....#...........#....##.#'
                        '#.####.#.###########.####..#'
                        '#......#.....#.............#'
                        '#.##########.#.###########.#'
                        '#.#..........#.#...........#'
                        '#.#.##########.#.#########.#'
                        '#.#.............#.......#..#'
                        '#.###############.#####.#..#'
                        '#..........................#'
                        '############################'
                    )
                }
                @{
                    Name = 'sector2_map_b'
                    Scenario = @{
                        Name = 'HINGE BAIT'
                        Entry = 'THE SAFE LOOP IS SLOW. THE HOT HINGE PAYS FASTER.'
                        ShardPool = @('4,13', '10,11', '12,9', '15,7', '20,5', '24,3')
                    }
                    Anchors = @{
                        Terminals = @('7,7', '18,7')
                        Surges = @('11,9', '20,11')
                        Enemies = @(
                            @{ X = 18; Y = 11; Kind = 'FLANKER' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#....#......#....#.........#'
                        '#.##.#.####.#.##.#.#######.#'
                        '#.#..#.#..#.#.##.#.....#...#'
                        '#.#.##.#..#.#.##.#####.#.###'
                        '#.#....#..#.#....#.....#...#'
                        '#.######..#.######.#####.#.#'
                        '#........##.............#..#'
                        '#.######.#########.######..#'
                        '#.#....#.....#.....#....#..#'
                        '#.#.##.#####.#.#####.##.#..#'
                        '#...##.....#.#.#.....##.#..#'
                        '###.######.#.#.#.######.#..#'
                        '#..........................#'
                        '############################'
                    )
                }
                @{
                    Name = 'sector2_map_c'
                    Scenario = @{
                        Name = 'ARC WEAVE'
                        Entry = 'PULL HUNTERS THROUGH CENTER SURGES, THEN SLIP OUT.'
                        ShardPool = @('6,13', '10,11', '14,7', '16,3', '21,5', '24,11')
                    }
                    Anchors = @{
                        Terminals = @('8,7', '18,11')
                        Surges = @('14,5', '22,9')
                        Enemies = @(
                            @{ X = 22; Y = 11; Kind = 'FLANKER' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#.........#....#...........#'
                        '#.#######.#.##.#.#########.#'
                        '#.....#...#..#.#.#.......#.#'
                        '#####.#.######.#.#.#####.#.#'
                        '#...#.#........#.#.....#.#.#'
                        '#.#.#.##########.#####.#.#.#'
                        '#.#.#....#...........#.#...#'
                        '#.#.####.#.#########.#.###.#'
                        '#.#....#.#.#.......#.#.....#'
                        '#.####.#.#.#.#####.#.#####.#'
                        '#......#...#.....#...#.....#'
                        '#.#############.#####.#.##.#'
                        '#..........................#'
                        '############################'
                    )
                }
            )
        }
        @{
            Id = 3
            Title = 'WARDEN'
            Intro = 'WARDEN LOCK LIVE. EXTRA HUNTERS CROWD THE EXIT.'
            Rules = @{
                SurgeCount = 4
                TerminalCount = 2
                EnemyBonus = 1
                FlankerThreshold = 176
                WardenThreshold = 80
                WardenEngageDistance = 10
            }
            Maps = @(
                @{
                    Name = 'sector3_map_a'
                    Scenario = @{
                        Name = 'LOCKSTEP BREACH'
                        Entry = 'THE GATE LANE IS LIVE EARLY. DO NOT ARRIVE LATE.'
                        ShardPool = @('6,13', '10,7', '15,9', '16,3', '19,7', '24,3')
                    }
                    Anchors = @{
                        Terminals = @('10,9', '20,11')
                        Surges = @('13,5', '22,5', '22,11')
                        Enemies = @(
                            @{ X = 21; Y = 3; Kind = 'WARDEN' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#....#...........#.........#'
                        '#.##.#.#########.#.#######.#'
                        '#....#.....#.....#.....#...#'
                        '####.#####.#.#########.#.###'
                        '#....#.....#.....#.....#...#'
                        '#.####.#########.#.#######.#'
                        '#.#....#.........#.........#'
                        '#.#.####.###############.###'
                        '#.#......#.......#.......#.#'
                        '#.######.#.#####.#.#####.#.#'
                        '#......#.#.....#.#.....#...#'
                        '#.####.#.#####.#.#####.###.#'
                        '#..........................#'
                        '############################'
                    )
                }
                @{
                    Name = 'sector3_map_b'
                    Scenario = @{
                        Name = 'UPLINK CHOKE'
                        Entry = 'THE UPPER GRID IS RICH, BUT THE WARDEN OWNS IT.'
                        ShardPool = @('4,13', '9,11', '15,7', '18,5', '20,1', '23,3')
                    }
                    Anchors = @{
                        Terminals = @('9,7', '18,9')
                        Surges = @('14,5', '21,7', '20,11')
                        Enemies = @(
                            @{ X = 21; Y = 3; Kind = 'WARDEN' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#....#.....#....#.....#....#'
                        '#.##.#.###.#.##.#.###.#.##.#'
                        '#.#..#...#.#..#.#...#.#..#.#'
                        '#.#.###.#.#.##.#.#.#.#.###.#'
                        '#.#.....#.#....#.#.#.#.....#'
                        '#.#######.######.#.#.#####.#'
                        '#.......#........#.#.....#.#'
                        '#.#####.##########.#####.#.#'
                        '#.#...#.....#......#...#.#.#'
                        '#.#.#.#####.#.######.#.#.#.#'
                        '#...#.....#.#.#......#...#.#'
                        '###.#####.#.#.#.##########.#'
                        '#..........................#'
                        '############################'
                    )
                }
                @{
                    Name = 'sector3_map_c'
                    Scenario = @{
                        Name = 'FINAL CORRIDOR'
                        Entry = 'THE LAST SHARD LINE RUNS STRAIGHT INTO THE EXIT.'
                        ShardPool = @('4,13', '9,11', '15,9', '19,5', '19,3', '23,1')
                    }
                    Anchors = @{
                        Terminals = @('10,7', '19,11')
                        Surges = @('13,5', '21,7', '22,11')
                        Enemies = @(
                            @{ X = 21; Y = 3; Kind = 'WARDEN' }
                        )
                    }
                    Rows = @(
                        '############################'
                        '#......#....#.......#......#'
                        '#.####.#.##.#.#####.#.####.#'
                        '#.#....#.#..#.#...#.#....#.#'
                        '#.#.####.#.##.#.#.#.####.#.#'
                        '#.#......#....#.#.#......#.#'
                        '#.########.####.#.########.#'
                        '#........#......#........#.#'
                        '#.######.########.######.#.#'
                        '#.#....#........#.#....#.#.#'
                        '#.#.##.########.#.#.##.#.#.#'
                        '#.#..#........#.#.#..#.#...#'
                        '#.##.########.#.#.##.#.###.#'
                        '#..........................#'
                        '############################'
                    )
                }
            )
        }
    )
    AdventureRealm = @{
        Title = 'SUNSPARK GLADE'
        Intro = 'FOLLOW THE GEM TRAIL, SPARK THE PEDESTAL, CLAIM THE HILLTOP KEY, AND WAKE THE PORTAL.'
        Start = '4,12'
        Portal = '24,2'
        RequiredGems = 20
        MacroZones = @(
            @{ Id = 'start-glade'; Label = 'Start Glade'; Bounds = '2,10,10,13' }
            @{ Id = 'first-loop'; Label = 'First Loop'; Bounds = '8,8,16,11' }
            @{ Id = 'charge-lane'; Label = 'Charge Lane'; Bounds = '6,11,12,13' }
            @{ Id = 'high-key-terrace'; Label = 'High Key Terrace'; Bounds = '14,3,22,6' }
            @{ Id = 'glide-return'; Label = 'Glide Return'; Bounds = '18,7,25,10' }
            @{ Id = 'portal-plaza'; Label = 'Portal Plaza'; Bounds = '21,1,25,4' }
        )
        RouteBeats = @(
            @{ Zone = 'start-glade'; Sequence = 1; Summary = 'Opening gem ribbon and a clean first read of the portal tower.' }
            @{ Zone = 'first-loop'; Sequence = 2; Summary = 'A broad first bend that teaches the realm without crowding the player.' }
            @{ Zone = 'charge-lane'; Sequence = 3; Summary = 'One obvious rusher and the flame pedestal in an open teaching lane.' }
            @{ Zone = 'high-key-terrace'; Sequence = 4; Summary = 'The visible hilltop key route framed against the skyline.' }
            @{ Zone = 'glide-return'; Sequence = 5; Summary = 'A return lane with one hazard lesson and a late combat beat.' }
            @{ Zone = 'portal-plaza'; Sequence = 6; Summary = 'The unlocked arch, the sparse warden set-piece, and the finish.' }
        )
        Chunks = @(
            @{ Id = 'glade-west'; Zone = 'start-glade'; Bounds = '2,10,7,13'; Role = 'start-lane' }
            @{ Id = 'glade-east'; Zone = 'start-glade'; Bounds = '8,10,12,13'; Role = 'intro-turn' }
            @{ Id = 'loop-bend'; Zone = 'first-loop'; Bounds = '10,8,16,11'; Role = 'route-read' }
            @{ Id = 'charge-teach'; Zone = 'charge-lane'; Bounds = '6,11,12,13'; Role = 'charge-lesson' }
            @{ Id = 'terrace-climb'; Zone = 'high-key-terrace'; Bounds = '14,5,18,8'; Role = 'climb' }
            @{ Id = 'terrace-key'; Zone = 'high-key-terrace'; Bounds = '18,3,22,5'; Role = 'key-reveal' }
            @{ Id = 'glide-ramp'; Zone = 'glide-return'; Bounds = '18,7,22,10'; Role = 'glide-setup' }
            @{ Id = 'return-lane'; Zone = 'glide-return'; Bounds = '22,7,25,10'; Role = 'return-pressure' }
            @{ Id = 'portal-front'; Zone = 'portal-plaza'; Bounds = '21,1,23,4'; Role = 'portal-read' }
            @{ Id = 'portal-arch'; Zone = 'portal-plaza'; Bounds = '23,1,25,3'; Role = 'finish' }
        )
        EncounterLanes = @(
            @{ Id = 'charge-lane-rusher'; Zone = 'charge-lane'; Enemy = 'RUSHER'; Summary = 'Open frontal lane that teaches the charge counter clearly.' }
            @{ Id = 'switch-flanker'; Zone = 'first-loop'; Enemy = 'FLANKER'; Summary = 'Side pressure near the pedestal without crowding the route read.' }
            @{ Id = 'portal-warden'; Zone = 'portal-plaza'; Enemy = 'WARDEN'; Summary = 'Late sparse set-piece that only activates near the finish.' }
        )
        LandmarkSightlines = @(
            @{ From = 'start-glade'; To = 'portal-plaza'; Subject = 'portal-arch'; Summary = 'The tower and arch peek over the upper cliff from the opening lane.' }
            @{ From = 'first-loop'; To = 'high-key-terrace'; Subject = 'sun-key'; Summary = 'The key terrace stays visible while the player rounds the first bend.' }
            @{ From = 'glide-return'; To = 'portal-plaza'; Subject = 'portal-arch'; Summary = 'The final glide points directly back into the portal silhouette.' }
        )
        CaptureAnchors = @{
            Beauty = 'glade-attract-a'
            Action = 'glade-attract-b'
        }
        Key = @(
            '18,4'
        )
        Rows = @(
            '############################'
            '#..........................#'
            '#..######.............##...#'
            '#..#....#.............##...#'
            '#..#....#.............##...#'
            '#..#....#####....####......#'
            '#..#.............#.........#'
            '#..######...##...#..#####..#'
            '#................#......#..#'
            '#..#####..#....#####...#...#'
            '#..#......#...........##...#'
            '#..#..##########......##...#'
            '#..#.................###...#'
            '#..........................#'
            '############################'
        )
        Gems = @(
            '5,12'
            '6,12'
            '7,12'
            '8,12'
            '9,12'
            '10,10'
            '10,11'
            '8,10'
            '12,9'
            '14,8'
            '16,8'
            '18,8'
            '14,6'
            '16,5'
            '17,4'
            '19,4'
            '21,4'
            '24,5'
            '24,7'
            '23,8'
            '22,9'
            '21,3'
            '23,3'
            '25,2'
        )
        Switches = @(
            '10,12'
        )
        Hazards = @(
            '21,6'
            '22,6'
        )
        Enemies = @(
            @{ X = 8; Y = 12; Kind = 'RUSHER' }
            @{ X = 15; Y = 9; Kind = 'RUSHER' }
            @{ X = 22; Y = 10; Kind = 'RUSHER' }
            @{ X = 19; Y = 6; Kind = 'FLANKER' }
            @{ X = 22; Y = 3; Kind = 'WARDEN' }
        )
        Props = @(
            @{ X = 3; Y = 12; Mesh = 'tree_round'; YawDegrees = 22.0 }
            @{ X = 7; Y = 13; Mesh = 'tree_round'; YawDegrees = 214.0 }
            @{ X = 11; Y = 12; Mesh = 'stone_stack'; YawDegrees = 30.0 }
            @{ X = 12; Y = 10; Mesh = 'bridge_span'; YawDegrees = 0.0 }
            @{ X = 17; Y = 8; Mesh = 'bridge_span'; YawDegrees = 0.0 }
            @{ X = 19; Y = 4; Mesh = 'stone_stack'; YawDegrees = 96.0 }
            @{ X = 10; Y = 12; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
            @{ X = 23; Y = 2; Mesh = 'portal_arch'; YawDegrees = 0.0 }
            @{ X = 24; Y = 2; Mesh = 'tower_toy'; YawDegrees = 0.0 }
            @{ X = 21; Y = 2; Mesh = 'stone_stack'; YawDegrees = 0.0 }
            @{ X = 5; Y = 3; Mesh = 'tree_round'; YawDegrees = 148.0 }
        )
    }
}
