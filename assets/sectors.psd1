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
    Campaign = @{
        Districts = @(
            @{
                Id = 'subgrid-ingress'
                Title = 'SUBGRID INGRESS'
                Intro = 'BREACH THE SUBGRID. SCOOP DATA SHARDS, OVERLOAD THE RELAY, LIFT THE KEYCARD, AND WAKE THE STORM GATE.'
                Start = '4,12'
                Exit = '24,2'
                NextDistrict = 2
                ObjectiveCounts = @{
                    RequiredDataShards = 20
                    RelayCount = 1
                    KeycardCount = 1
                }
                MacroZones = @(
                    @{ Id = 'dock-ramp'; Label = 'Dock Ramp'; Bounds = '2,10,10,13' }
                    @{ Id = 'relay-loop'; Label = 'Relay Loop'; Bounds = '8,8,16,11' }
                    @{ Id = 'charge-bridge'; Label = 'Charge Bridge'; Bounds = '6,11,12,13' }
                    @{ Id = 'vault-terrace'; Label = 'Vault Terrace'; Bounds = '14,3,22,6' }
                    @{ Id = 'return-span'; Label = 'Return Span'; Bounds = '18,7,25,10' }
                    @{ Id = 'storm-gate'; Label = 'Storm Gate'; Bounds = '21,1,25,4' }
                )
                RouteBeats = @(
                    @{ Zone = 'dock-ramp'; Sequence = 1; Summary = 'Open with a readable shard ribbon and the storm tower framed in the distance.' }
                    @{ Zone = 'relay-loop'; Sequence = 2; Summary = 'Teach the first wide bend before the route compresses around the relay.' }
                    @{ Zone = 'charge-bridge'; Sequence = 3; Summary = 'The dash-strike lane stays obvious and safe enough for the first hard commit.' }
                    @{ Zone = 'vault-terrace'; Sequence = 4; Summary = 'The raised keycard terrace reads cleanly against the skyline.' }
                    @{ Zone = 'return-span'; Sequence = 5; Summary = 'Loop back through one hazard lesson and a late pressure beat.' }
                    @{ Zone = 'storm-gate'; Sequence = 6; Summary = 'Finish under the gate arch with the final breach silhouette filling the frame.' }
                )
                Chunks = @(
                    @{ Id = 'dock-west'; Zone = 'dock-ramp'; Bounds = '2,10,7,13'; Role = 'start-lane'; BaseHeight = 0; ShelfHeight = 0; RampDir = 'none'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '24,2'; PropBudget = 1 }
                    @{ Id = 'dock-east'; Zone = 'dock-ramp'; Bounds = '8,10,12,13'; Role = 'intro-turn'; BaseHeight = 0; ShelfHeight = 64; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '18,6'; PropBudget = 1 }
                    @{ Id = 'relay-bend'; Zone = 'relay-loop'; Bounds = '10,8,16,11'; Role = 'route-read'; BaseHeight = 64; ShelfHeight = 96; RampDir = 'north'; CliffSide = 'east'; BridgeSpan = 'none'; LandmarkAnchor = '18,4'; PropBudget = 1 }
                    @{ Id = 'charge-teach'; Zone = 'charge-bridge'; Bounds = '6,11,12,13'; Role = 'dash-lesson'; BaseHeight = 64; ShelfHeight = 112; RampDir = 'north'; CliffSide = 'south'; BridgeSpan = 'east-west'; LandmarkAnchor = '10,12'; PropBudget = 1 }
                    @{ Id = 'vault-climb'; Zone = 'vault-terrace'; Bounds = '14,5,18,8'; Role = 'climb'; BaseHeight = 112; ShelfHeight = 176; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '18,5'; PropBudget = 1 }
                    @{ Id = 'vault-key'; Zone = 'vault-terrace'; Bounds = '18,3,22,5'; Role = 'key-reveal'; BaseHeight = 176; ShelfHeight = 208; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '18,4'; PropBudget = 1 }
                    @{ Id = 'return-ramp'; Zone = 'return-span'; Bounds = '18,7,22,10'; Role = 'glide-setup'; BaseHeight = 128; ShelfHeight = 176; RampDir = 'west'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '23,3'; PropBudget = 1 }
                    @{ Id = 'return-lane'; Zone = 'return-span'; Bounds = '22,7,25,10'; Role = 'return-pressure'; BaseHeight = 96; ShelfHeight = 128; RampDir = 'east'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '23,2'; PropBudget = 1 }
                    @{ Id = 'gate-front'; Zone = 'storm-gate'; Bounds = '21,1,23,4'; Role = 'gate-read'; BaseHeight = 96; ShelfHeight = 144; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '23,2'; PropBudget = 2 }
                    @{ Id = 'gate-arch'; Zone = 'storm-gate'; Bounds = '23,1,25,3'; Role = 'finish'; BaseHeight = 144; ShelfHeight = 176; RampDir = 'none'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '24,2'; PropBudget = 2 }
                )
                CaptureAnchors = @{
                    Beauty = 'subgrid-attract-a'
                    Action = 'subgrid-attract-b'
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
                )
                Enemies = @(
                    @{ X = 8; Y = 12; Kind = 'RUSHER' }
                    @{ X = 13; Y = 9; Kind = 'FLANKER' }
                    @{ X = 22; Y = 3; Kind = 'WARDEN' }
                )
                Props = @(
                    @{ X = 3; Y = 12; Mesh = 'stone_stack'; YawDegrees = 22.0 }
                    @{ X = 7; Y = 13; Mesh = 'tower_toy'; YawDegrees = 214.0 }
                    @{ X = 12; Y = 10; Mesh = 'bridge_span'; YawDegrees = 0.0 }
                    @{ X = 17; Y = 8; Mesh = 'bridge_span'; YawDegrees = 0.0 }
                    @{ X = 18; Y = 4; Mesh = 'stone_stack'; YawDegrees = 96.0 }
                    @{ X = 10; Y = 12; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 23; Y = 2; Mesh = 'portal_arch'; YawDegrees = 0.0 }
                    @{ X = 24; Y = 2; Mesh = 'tower_toy'; YawDegrees = 0.0 }
                    @{ X = 21; Y = 2; Mesh = 'stone_stack'; YawDegrees = 0.0 }
                    @{ X = 5; Y = 3; Mesh = 'tower_toy'; YawDegrees = 148.0 }
                )
            }
            @{
                Id = 'switchyard-spine'
                Title = 'SWITCHYARD SPINE'
                Intro = 'RIDE THE SWITCHYARD SPINE. THREAD CROSSFIRE, WAKE TWO RELAYS, SECURE THE KEYCARD, AND CUT THE BREACH LATTICE.'
                Start = '2,13'
                Exit = '24,1'
                NextDistrict = 3
                ObjectiveCounts = @{
                    RequiredDataShards = 12
                    RelayCount = 2
                    KeycardCount = 1
                }
                MacroZones = @(
                    @{ Id = 'rail-dock'; Label = 'Rail Dock'; Bounds = '1,11,8,13' }
                    @{ Id = 'crosslane'; Label = 'Crosslane'; Bounds = '8,7,15,10' }
                    @{ Id = 'hinge-yard'; Label = 'Hinge Yard'; Bounds = '15,7,22,10' }
                    @{ Id = 'upper-switch'; Label = 'Upper Switch'; Bounds = '8,1,20,6' }
                    @{ Id = 'spur-run'; Label = 'Spur Run'; Bounds = '20,9,25,13' }
                    @{ Id = 'breach-lock'; Label = 'Breach Lock'; Bounds = '21,1,25,4' }
                )
                RouteBeats = @(
                    @{ Zone = 'rail-dock'; Sequence = 1; Summary = 'Kick off in a broad loading lane with the first relay sightline already visible.' }
                    @{ Zone = 'crosslane'; Sequence = 2; Summary = 'The main spine asks for a clean commit through readable flanker pressure.' }
                    @{ Zone = 'hinge-yard'; Sequence = 3; Summary = 'The right hinge lets the player choose between the safe loop and the hot line.' }
                    @{ Zone = 'upper-switch'; Sequence = 4; Summary = 'Upper switchbacks compress the route and keep the second relay in view.' }
                    @{ Zone = 'spur-run'; Sequence = 5; Summary = 'The return sprint gathers late shards while enemy pressure pinches from both sides.' }
                    @{ Zone = 'breach-lock'; Sequence = 6; Summary = 'The breach lock gives one final clean read before the district handoff.' }
                )
                Chunks = @(
                    @{ Id = 'dock-lane'; Zone = 'rail-dock'; Bounds = '1,11,8,13'; Role = 'start-lane'; BaseHeight = 0; ShelfHeight = 32; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '24,1'; PropBudget = 1 }
                    @{ Id = 'crosslane-core'; Zone = 'crosslane'; Bounds = '8,7,15,10'; Role = 'crossfire'; BaseHeight = 32; ShelfHeight = 96; RampDir = 'north'; CliffSide = 'east'; BridgeSpan = 'east-west'; LandmarkAnchor = '16,7'; PropBudget = 1 }
                    @{ Id = 'hinge-yard'; Zone = 'hinge-yard'; Bounds = '15,7,22,10'; Role = 'route-choice'; BaseHeight = 64; ShelfHeight = 128; RampDir = 'west'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '20,9'; PropBudget = 1 }
                    @{ Id = 'upper-switch'; Zone = 'upper-switch'; Bounds = '8,1,20,6'; Role = 'switchback'; BaseHeight = 96; ShelfHeight = 160; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'north-south'; LandmarkAnchor = '18,3'; PropBudget = 1 }
                    @{ Id = 'spur-run'; Zone = 'spur-run'; Bounds = '20,9,25,13'; Role = 'return-run'; BaseHeight = 64; ShelfHeight = 112; RampDir = 'east'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '22,11'; PropBudget = 1 }
                    @{ Id = 'breach-lock'; Zone = 'breach-lock'; Bounds = '21,1,25,4'; Role = 'finish'; BaseHeight = 128; ShelfHeight = 176; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '24,1'; PropBudget = 2 }
                )
                CaptureAnchors = @{
                    Beauty = 'switchyard-attract-a'
                    Action = 'switchyard-attract-b'
                }
                Key = @(
                    '24,3'
                )
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
                Gems = @(
                    '4,13'
                    '6,13'
                    '8,11'
                    '10,13'
                    '11,9'
                    '14,13'
                    '16,7'
                    '18,7'
                    '20,11'
                    '22,13'
                    '23,3'
                    '24,5'
                    '24,9'
                    '18,11'
                    '12,13'
                    '16,13'
                )
                Switches = @(
                    '8,7'
                    '18,7'
                )
                Hazards = @(
                    '11,9'
                    '20,11'
                )
                Enemies = @(
                    @{ X = 10; Y = 11; Kind = 'RUSHER' }
                    @{ X = 18; Y = 7; Kind = 'FLANKER' }
                    @{ X = 21; Y = 9; Kind = 'FLANKER' }
                )
                Props = @(
                    @{ X = 3; Y = 13; Mesh = 'stone_stack'; YawDegrees = 0.0 }
                    @{ X = 8; Y = 7; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 18; Y = 7; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 14; Y = 13; Mesh = 'bridge_span'; YawDegrees = 0.0 }
                    @{ X = 24; Y = 3; Mesh = 'tower_toy'; YawDegrees = 64.0 }
                    @{ X = 24; Y = 1; Mesh = 'portal_arch'; YawDegrees = 0.0 }
                    @{ X = 21; Y = 11; Mesh = 'stone_stack'; YawDegrees = 180.0 }
                )
            }
            @{
                Id = 'thermal-foundry'
                Title = 'THERMAL FOUNDRY'
                Intro = 'PUSH THE THERMAL FOUNDRY. TIME THE OVERLOAD BURSTS, CLEAR THE HOT FLOOR, CLAIM THE KEYCARD, AND OPEN THE STORM GATE.'
                Start = '2,13'
                Exit = '24,1'
                NextDistrict = 4
                ObjectiveCounts = @{
                    RequiredDataShards = 14
                    RelayCount = 2
                    KeycardCount = 1
                }
                MacroZones = @(
                    @{ Id = 'coolant-dock'; Label = 'Coolant Dock'; Bounds = '1,11,8,13' }
                    @{ Id = 'ember-loop'; Label = 'Ember Loop'; Bounds = '8,7,15,10' }
                    @{ Id = 'heat-spine'; Label = 'Heat Spine'; Bounds = '15,7,22,10' }
                    @{ Id = 'smelter-rise'; Label = 'Smelter Rise'; Bounds = '8,1,20,6' }
                    @{ Id = 'slag-return'; Label = 'Slag Return'; Bounds = '20,9,25,13' }
                    @{ Id = 'forge-gate'; Label = 'Forge Gate'; Bounds = '21,1,25,4' }
                )
                RouteBeats = @(
                    @{ Zone = 'coolant-dock'; Sequence = 1; Summary = 'Open with clean footing before the furnace lanes start to punish delay.' }
                    @{ Zone = 'ember-loop'; Sequence = 2; Summary = 'The first hazard teaches the short overload burst without choking the route.' }
                    @{ Zone = 'heat-spine'; Sequence = 3; Summary = 'Mid-route crossfire and hot floor force sharper line choice.' }
                    @{ Zone = 'smelter-rise'; Sequence = 4; Summary = 'The keycard climb keeps the upper catwalk in view while the player commits upward.' }
                    @{ Zone = 'slag-return'; Sequence = 5; Summary = 'The lower return run escalates hazard density and rewards quick recovery.' }
                    @{ Zone = 'forge-gate'; Sequence = 6; Summary = 'The forge gate resolves into a clean sprint once the district is fully unlocked.' }
                )
                Chunks = @(
                    @{ Id = 'coolant-dock'; Zone = 'coolant-dock'; Bounds = '1,11,8,13'; Role = 'start-lane'; BaseHeight = 0; ShelfHeight = 32; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '24,1'; PropBudget = 1 }
                    @{ Id = 'ember-loop'; Zone = 'ember-loop'; Bounds = '8,7,15,10'; Role = 'hazard-lesson'; BaseHeight = 32; ShelfHeight = 96; RampDir = 'north'; CliffSide = 'east'; BridgeSpan = 'none'; LandmarkAnchor = '14,5'; PropBudget = 1 }
                    @{ Id = 'heat-spine'; Zone = 'heat-spine'; Bounds = '15,7,22,10'; Role = 'pressure-lane'; BaseHeight = 64; ShelfHeight = 128; RampDir = 'west'; CliffSide = 'south'; BridgeSpan = 'east-west'; LandmarkAnchor = '20,9'; PropBudget = 1 }
                    @{ Id = 'smelter-rise'; Zone = 'smelter-rise'; Bounds = '8,1,20,6'; Role = 'catwalk-climb'; BaseHeight = 96; ShelfHeight = 176; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'north-south'; LandmarkAnchor = '20,3'; PropBudget = 1 }
                    @{ Id = 'slag-return'; Zone = 'slag-return'; Bounds = '20,9,25,13'; Role = 'return-run'; BaseHeight = 64; ShelfHeight = 112; RampDir = 'east'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '23,11'; PropBudget = 1 }
                    @{ Id = 'forge-gate'; Zone = 'forge-gate'; Bounds = '21,1,25,4'; Role = 'finish'; BaseHeight = 144; ShelfHeight = 192; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '24,1'; PropBudget = 2 }
                )
                CaptureAnchors = @{
                    Beauty = 'thermal-attract-a'
                    Action = 'thermal-attract-b'
                }
                Key = @(
                    '20,3'
                )
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
                Gems = @(
                    '5,13'
                    '8,13'
                    '11,11'
                    '14,7'
                    '17,5'
                    '20,3'
                    '24,1'
                    '14,13'
                    '18,13'
                    '22,13'
                    '10,7'
                    '20,9'
                    '23,11'
                    '24,9'
                    '6,7'
                    '12,5'
                )
                Switches = @(
                    '10,7'
                    '20,9'
                )
                Hazards = @(
                    '14,5'
                    '22,7'
                )
                Enemies = @(
                    @{ X = 15; Y = 7; Kind = 'RUSHER' }
                    @{ X = 20; Y = 11; Kind = 'FLANKER' }
                    @{ X = 22; Y = 9; Kind = 'FLANKER' }
                )
                Props = @(
                    @{ X = 3; Y = 13; Mesh = 'stone_stack'; YawDegrees = 0.0 }
                    @{ X = 10; Y = 7; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 20; Y = 9; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 14; Y = 5; Mesh = 'tower_toy'; YawDegrees = 64.0 }
                    @{ X = 20; Y = 3; Mesh = 'stone_stack'; YawDegrees = 96.0 }
                    @{ X = 24; Y = 1; Mesh = 'portal_arch'; YawDegrees = 0.0 }
                    @{ X = 22; Y = 11; Mesh = 'bridge_span'; YawDegrees = 0.0 }
                )
            }
            @{
                Id = 'apex-vault'
                Title = 'APEX VAULT'
                Intro = 'CRACK THE APEX VAULT. HOLD OFF THE WARDEN, WAKE THE FINAL RELAYS, PULL THE KEYCARD, AND FORCE THE LAST BREACH.'
                Start = '2,13'
                Exit = '23,1'
                NextDistrict = 0
                ObjectiveCounts = @{
                    RequiredDataShards = 14
                    RelayCount = 2
                    KeycardCount = 1
                }
                MacroZones = @(
                    @{ Id = 'vault-dock'; Label = 'Vault Dock'; Bounds = '1,11,8,13' }
                    @{ Id = 'corridor-spine'; Label = 'Corridor Spine'; Bounds = '8,7,16,10' }
                    @{ Id = 'seal-run'; Label = 'Seal Run'; Bounds = '16,7,22,10' }
                    @{ Id = 'warden-rise'; Label = 'Warden Rise'; Bounds = '8,1,20,6' }
                    @{ Id = 'key-branch'; Label = 'Key Branch'; Bounds = '18,1,23,6' }
                    @{ Id = 'final-breach'; Label = 'Final Breach'; Bounds = '21,1,25,4' }
                )
                RouteBeats = @(
                    @{ Zone = 'vault-dock'; Sequence = 1; Summary = 'Start in the quiet dock before the vault camera line closes in.' }
                    @{ Zone = 'corridor-spine'; Sequence = 2; Summary = 'The center corridor is direct but keeps flanker pressure live.' }
                    @{ Zone = 'seal-run'; Sequence = 3; Summary = 'Late hazards and tighter lanes punish hesitation.' }
                    @{ Zone = 'warden-rise'; Sequence = 4; Summary = 'The upper rise frames the warden and the final gate in one glance.' }
                    @{ Zone = 'key-branch'; Sequence = 5; Summary = 'The key branch is short, exposed, and worth the commitment.' }
                    @{ Zone = 'final-breach'; Sequence = 6; Summary = 'Once the gate opens, the last sprint should feel urgent and unmistakable.' }
                )
                Chunks = @(
                    @{ Id = 'vault-dock'; Zone = 'vault-dock'; Bounds = '1,11,8,13'; Role = 'start-lane'; BaseHeight = 0; ShelfHeight = 32; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '23,1'; PropBudget = 1 }
                    @{ Id = 'corridor-spine'; Zone = 'corridor-spine'; Bounds = '8,7,16,10'; Role = 'main-corridor'; BaseHeight = 32; ShelfHeight = 96; RampDir = 'north'; CliffSide = 'east'; BridgeSpan = 'none'; LandmarkAnchor = '15,9'; PropBudget = 1 }
                    @{ Id = 'seal-run'; Zone = 'seal-run'; Bounds = '16,7,22,10'; Role = 'lockdown'; BaseHeight = 64; ShelfHeight = 128; RampDir = 'west'; CliffSide = 'south'; BridgeSpan = 'east-west'; LandmarkAnchor = '21,7'; PropBudget = 1 }
                    @{ Id = 'warden-rise'; Zone = 'warden-rise'; Bounds = '8,1,20,6'; Role = 'warden-overlook'; BaseHeight = 112; ShelfHeight = 192; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'north-south'; LandmarkAnchor = '19,3'; PropBudget = 1 }
                    @{ Id = 'key-branch'; Zone = 'key-branch'; Bounds = '18,1,23,6'; Role = 'key-route'; BaseHeight = 160; ShelfHeight = 208; RampDir = 'east'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '21,3'; PropBudget = 1 }
                    @{ Id = 'final-breach'; Zone = 'final-breach'; Bounds = '21,1,25,4'; Role = 'finish'; BaseHeight = 176; ShelfHeight = 224; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '23,1'; PropBudget = 2 }
                )
                CaptureAnchors = @{
                    Beauty = 'vault-attract-a'
                    Action = 'vault-attract-b'
                }
                Key = @(
                    '21,3'
                )
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
                Gems = @(
                    '4,13'
                    '7,13'
                    '9,11'
                    '12,13'
                    '15,9'
                    '16,13'
                    '19,5'
                    '19,3'
                    '20,13'
                    '23,1'
                    '24,13'
                    '10,7'
                    '19,11'
                    '21,7'
                    '22,11'
                    '14,5'
                )
                Switches = @(
                    '10,7'
                    '19,11'
                )
                Hazards = @(
                    '13,5'
                    '21,7'
                    '22,11'
                )
                Enemies = @(
                    @{ X = 12; Y = 11; Kind = 'RUSHER' }
                    @{ X = 16; Y = 9; Kind = 'FLANKER' }
                    @{ X = 21; Y = 3; Kind = 'WARDEN' }
                )
                Props = @(
                    @{ X = 3; Y = 13; Mesh = 'stone_stack'; YawDegrees = 0.0 }
                    @{ X = 10; Y = 7; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 19; Y = 11; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
                    @{ X = 21; Y = 3; Mesh = 'tower_toy'; YawDegrees = 0.0 }
                    @{ X = 23; Y = 1; Mesh = 'portal_arch'; YawDegrees = 0.0 }
                    @{ X = 18; Y = 5; Mesh = 'bridge_span'; YawDegrees = 0.0 }
                    @{ X = 20; Y = 9; Mesh = 'stone_stack'; YawDegrees = 128.0 }
                )
            }
        )
    }
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
            @{ Id = 'glade-west'; Zone = 'start-glade'; Bounds = '2,10,7,13'; Role = 'start-lane'; BaseHeight = 0; ShelfHeight = 0; RampDir = 'none'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '24,2'; PropBudget = 1 }
            @{ Id = 'glade-east'; Zone = 'start-glade'; Bounds = '8,10,12,13'; Role = 'intro-turn'; BaseHeight = 0; ShelfHeight = 64; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '18,6'; PropBudget = 1 }
            @{ Id = 'loop-bend'; Zone = 'first-loop'; Bounds = '10,8,16,11'; Role = 'route-read'; BaseHeight = 64; ShelfHeight = 96; RampDir = 'north'; CliffSide = 'east'; BridgeSpan = 'none'; LandmarkAnchor = '18,4'; PropBudget = 1 }
            @{ Id = 'charge-teach'; Zone = 'charge-lane'; Bounds = '6,11,12,13'; Role = 'charge-lesson'; BaseHeight = 64; ShelfHeight = 112; RampDir = 'north'; CliffSide = 'south'; BridgeSpan = 'east-west'; LandmarkAnchor = '10,12'; PropBudget = 1 }
            @{ Id = 'terrace-climb'; Zone = 'high-key-terrace'; Bounds = '14,5,18,8'; Role = 'climb'; BaseHeight = 112; ShelfHeight = 176; RampDir = 'east'; CliffSide = 'north'; BridgeSpan = 'none'; LandmarkAnchor = '18,5'; PropBudget = 1 }
            @{ Id = 'terrace-key'; Zone = 'high-key-terrace'; Bounds = '18,3,22,5'; Role = 'key-reveal'; BaseHeight = 176; ShelfHeight = 208; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '18,4'; PropBudget = 1 }
            @{ Id = 'glide-ramp'; Zone = 'glide-return'; Bounds = '18,7,22,10'; Role = 'glide-setup'; BaseHeight = 128; ShelfHeight = 176; RampDir = 'west'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '23,3'; PropBudget = 1 }
            @{ Id = 'return-lane'; Zone = 'glide-return'; Bounds = '22,7,25,10'; Role = 'return-pressure'; BaseHeight = 96; ShelfHeight = 128; RampDir = 'east'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '23,2'; PropBudget = 1 }
            @{ Id = 'portal-front'; Zone = 'portal-plaza'; Bounds = '21,1,23,4'; Role = 'portal-read'; BaseHeight = 96; ShelfHeight = 144; RampDir = 'north'; CliffSide = 'west'; BridgeSpan = 'none'; LandmarkAnchor = '23,2'; PropBudget = 2 }
            @{ Id = 'portal-arch'; Zone = 'portal-plaza'; Bounds = '23,1,25,3'; Role = 'finish'; BaseHeight = 144; ShelfHeight = 176; RampDir = 'none'; CliffSide = 'south'; BridgeSpan = 'none'; LandmarkAnchor = '24,2'; PropBudget = 2 }
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
        )
        Enemies = @(
            @{ X = 8; Y = 12; Kind = 'RUSHER' }
            @{ X = 13; Y = 9; Kind = 'FLANKER' }
            @{ X = 22; Y = 3; Kind = 'WARDEN' }
        )
        Props = @(
            @{ X = 3; Y = 12; Mesh = 'tree_round'; YawDegrees = 22.0 }
            @{ X = 7; Y = 13; Mesh = 'tree_round'; YawDegrees = 214.0 }
            @{ X = 12; Y = 10; Mesh = 'bridge_span'; YawDegrees = 0.0 }
            @{ X = 17; Y = 8; Mesh = 'bridge_span'; YawDegrees = 0.0 }
            @{ X = 18; Y = 4; Mesh = 'stone_stack'; YawDegrees = 96.0 }
            @{ X = 10; Y = 12; Mesh = 'switch_pedestal'; YawDegrees = 0.0 }
            @{ X = 23; Y = 2; Mesh = 'portal_arch'; YawDegrees = 0.0 }
            @{ X = 24; Y = 2; Mesh = 'tower_toy'; YawDegrees = 0.0 }
            @{ X = 21; Y = 2; Mesh = 'stone_stack'; YawDegrees = 0.0 }
            @{ X = 5; Y = 3; Mesh = 'tree_round'; YawDegrees = 148.0 }
        )
    }
}
