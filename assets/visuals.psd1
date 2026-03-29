@{
    Legend = @(
        @{ Pixel = '.'; Value = '0' }
        @{ Pixel = 'a'; Value = 'PAL_AMBER' }
        @{ Pixel = 'c'; Value = 'PAL_CYAN' }
        @{ Pixel = 'C'; Value = 'PAL_CYAN2' }
        @{ Pixel = 'f'; Value = 'PAL_FLOOR' }
        @{ Pixel = 'F'; Value = 'PAL_FLOOR2' }
        @{ Pixel = 'g'; Value = 'PAL_GATE' }
        @{ Pixel = 'm'; Value = 'PAL_WALL' }
        @{ Pixel = 'M'; Value = 'PAL_WALL2' }
        @{ Pixel = 'p'; Value = 'PAL_PANEL2' }
        @{ Pixel = 'r'; Value = 'PAL_RED' }
        @{ Pixel = 'R'; Value = 'PAL_RED2' }
        @{ Pixel = 'w'; Value = 'PAL_WHITE' }
    )

    Assets = @(
        @{
            Section = 'Sprites'
            Name = 'sprite_player_a'
            Width = 8
            Height = 8
            Rows = @(
                '..pppp..'
                '.pCCCCp.'
                'pCCwwCCp'
                'pCpwwpCp'
                'pcCCCCcp'
                '.pcaacp.'
                '.cp..pc.'
                'c.p..p.c'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_player_b'
            Width = 8
            Height = 8
            Rows = @(
                '..pppp..'
                '.pCCCCp.'
                'pCCwwCCp'
                'pCpwwpCp'
                '.pCCCCp.'
                'pcCaaCcp'
                'c.p..p.c'
                '.p....p.'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_enemy_a'
            Width = 8
            Height = 8
            Rows = @(
                '..prrp..'
                '.pRRRRp.'
                'pRrwwrRp'
                'pRRaaRRp'
                'prRRRRrp'
                '.prpprp.'
                'r.p..p.r'
                '..R..R..'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_enemy_b'
            Width = 8
            Height = 8
            Rows = @(
                '..prrp..'
                '.pRRRRp.'
                'pRwrrwRp'
                'pRRaaRRp'
                '.pRRRRp.'
                'prRppRrp'
                '.r.pp.r.'
                'R......R'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_enemy_flanker_a'
            Width = 8
            Height = 8
            Rows = @(
                '..pccp..'
                '.pCCCCp.'
                'pCwppwCp'
                'pCCaaCCp'
                'pcpCCpcp'
                '.Cp..pC.'
                'c.p..p.c'
                '..C..C..'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_enemy_flanker_b'
            Width = 8
            Height = 8
            Rows = @(
                '..pccp..'
                '.pCCCCp.'
                'pCpwwpCp'
                'pCwaawCp'
                '.pCCCCp.'
                'C.pppp.C'
                '.c.pp.c.'
                'C......C'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_enemy_warden_a'
            Width = 8
            Height = 8
            Rows = @(
                '.pggggp.'
                'pgpwwpgp'
                'gpgaagpg'
                'ggpggpgg'
                'pggppggp'
                '.pgaagp.'
                '.g.pp.g.'
                'p..pp..p'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_enemy_warden_b'
            Width = 8
            Height = 8
            Rows = @(
                '.pggggp.'
                'pgwppwgp'
                'gpgwwgpg'
                'ggpaapgg'
                '.pggggp.'
                'p.gaag.p'
                '.g.pp.g.'
                '..p..p..'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_shard_a'
            Width = 8
            Height = 8
            Rows = @(
                '...c....'
                '..CwC...'
                '.CwawC..'
                'CwaaawC.'
                '.CwawC..'
                '..CwC...'
                '...c....'
                '........'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_shard_b'
            Width = 8
            Height = 8
            Rows = @(
                '....w...'
                '...CwC..'
                '..CwawC.'
                '.CwawC..'
                '..Cwaw..'
                '...Cw...'
                '....c...'
                '........'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_gate_a'
            Width = 8
            Height = 8
            Rows = @(
                '..pggp..'
                '.pgCCgp.'
                'pgCwwCgp'
                'gCwggwCg'
                'pgCwwCgp'
                '.pgCCgp.'
                '..pggp..'
                '........'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_gate_b'
            Width = 8
            Height = 8
            Rows = @(
                '...pp...'
                '..pggp..'
                '.pgwwgp.'
                'pgwCCwgp'
                '.pgwwgp.'
                '..pggp..'
                '...pp...'
                '........'
            )
        }
        @{
            Section = 'Sprites'
            Name = 'sprite_bitriver_mark'
            Width = 16
            Height = 16
            Rows = @(
                '................'
                '....ccCCCCcc....'
                '...cpppppppppc..'
                '..cpggggppaapc..'
                '..CpwwggppaapC..'
                '..CppwwggppppC..'
                '..CpppwwggpppC..'
                '..CppppwwggppC..'
                '..CppggwwppppC..'
                '..CpggwwpppppC..'
                '..CpgwwpppggpC..'
                '..cpwwpppgggpc..'
                '...cpppppppppc..'
                '....ccCCCCcc....'
                '................'
                '................'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_floor_a'
            Width = 8
            Height = 8
            Rows = @(
                'fFpffFpf'
                'FcFfpfcF'
                'pFfCFpff'
                'fpcFfCFp'
                'ffpfcFpf'
                'FCfpFfcF'
                'pfFcpfFp'
                'fpfFfpCf'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_floor_b'
            Width = 8
            Height = 8
            Rows = @(
                'fpFfFpff'
                'pFCffcFp'
                'FcfpCFpf'
                'fFpcFfCF'
                'FpfFCpff'
                'pcFfpCFp'
                'fFpfcFpf'
                'FpCfFfpF'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_wall_a'
            Width = 8
            Height = 8
            Rows = @(
                'MMMMMMMM'
                'MmpmmpmM'
                'MpMcpMpM'
                'MmpMmpCM'
                'MMmpMmpM'
                'MpCmpMmM'
                'MmpMcpmM'
                'MMMMMMMM'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_wall_b'
            Width = 8
            Height = 8
            Rows = @(
                'MMMMMMMM'
                'MmpmCpmM'
                'MpMpmcpM'
                'MmcMpmpM'
                'MpmCMpmM'
                'MmpmpcMM'
                'MpCpmpmM'
                'MMMMMMMM'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_locked_a'
            Width = 8
            Height = 8
            Rows = @(
                'prpRRprp'
                'rpRwwRpr'
                'pRprrpRp'
                'RwrpprwR'
                'RwrpprwR'
                'pRprrpRp'
                'rpRRRRpr'
                'prpRRprp'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_locked_b'
            Width = 8
            Height = 8
            Rows = @(
                'pRprrpRp'
                'RprwwrpR'
                'prpRRprp'
                'rwRppRwr'
                'rwRppRwr'
                'prpRRprp'
                'RprrrrpR'
                'pRprrpRp'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_open_a'
            Width = 8
            Height = 8
            Rows = @(
                'pgpCCpgp'
                'gpCwwCpg'
                'pCpggpCp'
                'CwgppgwC'
                'CwgppgwC'
                'pCpggpCp'
                'gpCCCCpg'
                'pgpCCpgp'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_open_b'
            Width = 8
            Height = 8
            Rows = @(
                'pwpggpwp'
                'wpgCCgpw'
                'pgpwwpgp'
                'gCwppwCg'
                'gCwppwCg'
                'pgpwwpgp'
                'wpggggpw'
                'pwpggpwp'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_surge_a'
            Width = 8
            Height = 8
            Rows = @(
                'fRpffpRf'
                'RFCppCFR'
                'pCwaawCp'
                'fparrapf'
                'fparrapf'
                'pCwaawCp'
                'RFCppCFR'
                'fRpffpRf'
            )
        }
        @{
            Section = 'Tiles'
            Name = 'tile_surge_b'
            Width = 8
            Height = 8
            Rows = @(
                'fpRffRpf'
                'pCFRRFCp'
                'RFCwwCFR'
                'fRwaawRf'
                'fRwaawRf'
                'RFCwwCFR'
                'pCFRRFCp'
                'fpRffRpf'
            )
        }
    )
}
