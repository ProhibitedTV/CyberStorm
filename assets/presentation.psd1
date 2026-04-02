function Segs {
    param([string[]]$Parts)

    $row = ($Parts -join '')
    if ($row.Length -ne 64) {
        throw ("Presentation row must be 64 characters wide. Received {0}." -f $row.Length)
    }

    return $row
}

function Rows24 {
    param([string[]]$Rows)

    if ($Rows.Count -ne 24) {
        throw ("Presentation asset must define exactly 24 rows. Received {0}." -f $Rows.Count)
    }

    return $Rows
}

function Banner {
    param(
        [string]$Key,
        [string[]]$Rows
    )

    return @{
        Key = $Key
        Rows = (Rows24 -Rows $Rows)
    }
}

function New-WordmarkBanner {
    param(
        [string]$Major,
        [string]$Minor,
        [string]$Spark
    )

    $major4 = ("..{0}{0}{0}{0}.." -f $Major)
    $minor4 = ("..{0}{0}{0}{0}.." -f $Minor)
    $spark2 = ("...{0}{0}..." -f $Spark)
    $hookMajor = ("{0}{0}....{0}{0}" -f $Major)
    $hookMinor = ("{0}{0}....{0}{0}" -f $Minor)

    return Rows24 @(
        $blank
        $blank
        $blank
        $blank
        $blank
        $blank
        (Segs @('........', $spark2, '........', $major4, $minor4, '........', $spark2, '........'))
        (Segs @('........', $hookMajor, $major4, '........', '........', $minor4, $hookMinor, '........'))
        (Segs @('........', $major4, $minor4, $spark2, $spark2, $minor4, $major4, '........'))
        (Segs @('........', $minor4, '........', $hookMajor, $hookMinor, '........', $minor4, '........'))
        (Segs @('........', $spark2, $major4, $minor4, $major4, $minor4, $spark2, '........'))
        (Segs @('........', '........', $hookMinor, '........', '........', $hookMajor, '........', '........'))
        (Segs @('........', $spark2, $major4, $minor4, $minor4, $major4, $spark2, '........'))
        (Segs @('........', $minor4, '........', $hookMajor, $hookMinor, '........', $minor4, '........'))
        (Segs @('........', $major4, $minor4, $spark2, $spark2, $minor4, $major4, '........'))
        (Segs @('........', $hookMajor, $major4, '........', '........', $minor4, $hookMinor, '........'))
        (Segs @('........', $spark2, '........', $minor4, $major4, '........', $spark2, '........'))
        $blank
        $blank
        $blank
        $blank
        $blank
        $blank
        $blank
    )
}

function New-FrameBanner {
    param(
        [string]$Major,
        [string]$Minor,
        [string]$Spark
    )

    $major4 = ("..{0}{0}{0}{0}.." -f $Major)
    $minor4 = ("..{0}{0}{0}{0}.." -f $Minor)
    $spark2 = ("...{0}{0}..." -f $Spark)
    $majorCorner = ("{0}{0}....{0}{0}" -f $Major)
    $minorCorner = ("{0}{0}....{0}{0}" -f $Minor)

    return Rows24 @(
        $blank
        $blank
        (Segs @('........', '........', $spark2, $major4, $major4, $spark2, '........', '........'))
        (Segs @('........', $majorCorner, $major4, '........', '........', $major4, $majorCorner, '........'))
        (Segs @($spark2, $minor4, '........', $minor4, $minor4, '........', $minor4, $spark2))
        (Segs @($major4, '........', $minorCorner, '........', '........', $minorCorner, '........', $major4))
        (Segs @($major4, '........', $spark2, '........', '........', $spark2, '........', $major4))
        (Segs @($minor4, '........', '........', $major4, $major4, '........', '........', $minor4))
        (Segs @($spark2, '........', $minorCorner, '........', '........', $minorCorner, '........', $spark2))
        (Segs @('........', $major4, '........', $spark2, $spark2, '........', $major4, '........'))
        (Segs @('........', $minor4, '........', $major4, $major4, '........', $minor4, '........'))
        (Segs @($spark2, '........', $minorCorner, '........', '........', $minorCorner, '........', $spark2))
        (Segs @($minor4, '........', '........', $major4, $major4, '........', '........', $minor4))
        (Segs @($major4, '........', $spark2, '........', '........', $spark2, '........', $major4))
        (Segs @($major4, '........', $minorCorner, '........', '........', $minorCorner, '........', $major4))
        (Segs @($spark2, $minor4, '........', $minor4, $minor4, '........', $minor4, $spark2))
        (Segs @('........', $majorCorner, $major4, '........', '........', $major4, $majorCorner, '........'))
        (Segs @('........', '........', $spark2, $major4, $major4, $spark2, '........', '........'))
        $blank
        $blank
        $blank
        $blank
        $blank
        $blank
    )
}

function New-BadgeBanner {
    param(
        [string]$Major,
        [string]$Minor,
        [string]$Spark
    )

    $major4 = ("..{0}{0}{0}{0}.." -f $Major)
    $minor4 = ("..{0}{0}{0}{0}.." -f $Minor)
    $spark2 = ("...{0}{0}..." -f $Spark)

    return Rows24 @(
        $blank
        $blank
        $blank
        $blank
        $blank
        (Segs @('........', '........', '........', $spark2, '........', '........', '........', '........'))
        (Segs @('........', '........', $major4, '........', $minor4, '........', '........', '........'))
        (Segs @('........', $major4, '........', $spark2, '........', $minor4, '........', '........'))
        (Segs @($major4, '........', $minor4, '........', $spark2, '........', $minor4, '........'))
        (Segs @('........', $minor4, '........', $major4, '........', $spark2, '........', $major4))
        (Segs @('........', '........', $spark2, '........', $major4, '........', $minor4, '........'))
        (Segs @('........', '........', '........', $minor4, '........', $major4, '........', '........'))
        (Segs @('........', '........', $major4, '........', $minor4, '........', '........', '........'))
        (Segs @('........', $spark2, '........', $major4, '........', $minor4, '........', '........'))
        (Segs @($minor4, '........', $major4, '........', $spark2, '........', $major4, '........'))
        (Segs @('........', $major4, '........', $minor4, '........', $spark2, '........', $minor4))
        (Segs @('........', '........', $minor4, '........', $major4, '........', '........', '........'))
        (Segs @('........', '........', '........', $spark2, '........', '........', '........', '........'))
        $blank
        $blank
        $blank
        $blank
        $blank
        $blank
    )
}

$blank = Segs @('........', '........', '........', '........', '........', '........', '........', '........')

@{
    Legend = @{
        '.' = 0
        '1' = 1
        '2' = 2
        'p' = 4
        'c' = 5
        'y' = 6
        'w' = 7
        'a' = 8
        'r' = 9
        'h' = 10
        'g' = 17
    }

    Assets = @(
        (Banner 'splash_logo' @(
            $blank
            $blank
            $blank
            (Segs @('........', '..c..c..', '........', '..y..y..', '........', '..c..c..', '........', '........'))
            (Segs @('....cccc', 'cccc....', '....yyyy', 'yyyy....', '....cccc', 'cccc....', '....yyyy', 'yyyy....'))
            (Segs @('...ccccc', 'y......y', '...ccccy', 'y......c', '...ccccc', 'y......y', '...ccccy', 'y......c'))
            (Segs @('..cc..ww', '..yy..ww', '..cc..ww', '..yy..ww', '..cc..ww', '..yy..ww', '..cc..ww', '..yy..ww'))
            (Segs @('.cc..ww.', '.yy..ww.', '.cc..ww.', '.yy..ww.', '.cc..ww.', '.yy..ww.', '.cc..ww.', '.yy..ww.'))
            (Segs @('cc..ww..', 'yy..ww..', 'cc..ww..', 'yy..ww..', 'cc..ww..', 'yy..ww..', 'cc..ww..', 'yy..ww..'))
            (Segs @('....cc..', 'ww..yy..', '....cc..', 'ww..yy..', '....cc..', 'ww..yy..', '....cc..', 'ww..yy..'))
            (Segs @('..aa....', '..aa....', '..aa....', '..aa....', '..aa....', '..aa....', '..aa....', '..aa....'))
            (Segs @('....aaaa', '....aaaa', '....aaaa', '....aaaa', '....aaaa', '....aaaa', '....aaaa', '....aaaa'))
            (Segs @('........', '.a....a.', '........', '.a....a.', '........', '.a....a.', '........', '.a....a.'))
            (Segs @('........', '........', '..cccc..', '..yyyy..', '..cccc..', '..yyyy..', '........', '........'))
            (Segs @('........', '..c..c..', '..y..y..', '..c..c..', '..y..y..', '..c..c..', '..y..y..', '........'))
            (Segs @('........', '...cc...', '..cwwc..', '.cwwwwc.', '.cwwwwc.', '..cwwc..', '...cc...', '........'))
            (Segs @('........', '..cccc..', '.cc..cc.', '.c....c.', '.c....c.', '.cc..cc.', '..cccc..', '........'))
            (Segs @('........', '.yyyyyy.', '.y....y.', '.y....y.', '.y....y.', '.y....y.', '.yyyyyy.', '........'))
            (Segs @('........', '..aa....', '....aa..', '..aa....', '....aa..', '..aa....', '....aa..', '........'))
            (Segs @('........', '........', '....ww..', '..ww....', '....ww..', '..ww....', '........', '........'))
            $blank
            $blank
            $blank
            $blank
        ))
        (Banner 'splash_wordmark' (New-WordmarkBanner -Major 'c' -Minor 'y' -Spark 'w'))
        (Banner 'title_logo' @(
            $blank
            $blank
            $blank
            (Segs @('........', '..yyyy..', '........', '..yyyy..', '........', '..yyyy..', '........', '..yyyy..'))
            (Segs @('..cccc..', '.c....c.', '..cccc..', '.c....c.', '..cccc..', '.c....c.', '..cccc..', '.c....c.'))
            (Segs @('.c....c.', '..cccc..', '.c....c.', '..cccc..', '.c....c.', '..cccc..', '.c....c.', '..cccc..'))
            (Segs @('....aa..', '..aa....', '....aa..', '..aa....', '....aa..', '..aa....', '....aa..', '..aa....'))
            (Segs @('..wwww..', '.w....w.', '.w.aa.w.', '.w....w.', '..wwww..', '.w....w.', '.w.aa.w.', '.w....w.'))
            (Segs @('.y..y..y', 'y..y..y.', '.y..y..y', 'y..y..y.', '.y..y..y', 'y..y..y.', '.y..y..y', 'y..y..y.'))
            (Segs @('....yyyy', 'cccc....', '....yyyy', 'cccc....', '....yyyy', 'cccc....', '....yyyy', 'cccc....'))
            (Segs @('..a..a..', '........', '..a..a..', '........', '..a..a..', '........', '..a..a..', '........'))
            (Segs @('..yyyy..', '.y....y.', '.y.aa.y.', '.y....y.', '..yyyy..', '.y....y.', '.y.aa.y.', '.y....y.'))
            (Segs @('...cc...', '..c..c..', '.c....c.', '.c.ww.c.', '.c....c.', '..c..c..', '...cc...', '........'))
            (Segs @('........', '..aa....', '....aa..', '..aa....', '....aa..', '..aa....', '....aa..', '........'))
            (Segs @('........', '...yyyy.', '..y....y', '.y..aa..', '.y....y.', '..y....y', '...yyyy.', '........'))
            (Segs @('........', '..cccc..', '.c....c.', '.c....c.', '.c....c.', '.c....c.', '..cccc..', '........'))
            (Segs @('........', '..wwww..', '.w....w.', '.w....w.', '.w....w.', '.w....w.', '..wwww..', '........'))
            (Segs @('........', '..a..a..', '........', '..a..a..', '........', '..a..a..', '........', '..a..a..'))
            (Segs @('..yyyy..', '........', '..yyyy..', '........', '..yyyy..', '........', '..yyyy..', '........'))
            (Segs @('...cc...', '..c..c..', '........', '..c..c..', '........', '..c..c..', '...cc...', '........'))
            $blank
            $blank
            $blank
            $blank
        ))
        (Banner 'title_tagline' (New-WordmarkBanner -Major 'c' -Minor 'a' -Spark 'w'))
        (Banner 'title_prompt' (New-FrameBanner -Major 'a' -Minor 'c' -Spark 'w'))
        (Banner 'demo_badge' (New-BadgeBanner -Major 'c' -Minor 'y' -Spark 'w'))
        (Banner 'sector1_card' (New-FrameBanner -Major 'c' -Minor 'y' -Spark 'w'))
        (Banner 'sector2_card' (New-FrameBanner -Major 'a' -Minor 'r' -Spark 'w'))
        (Banner 'sector3_card' (New-FrameBanner -Major 'r' -Minor 'h' -Spark 'w'))
        (Banner 'win_banner' (New-WordmarkBanner -Major 'g' -Minor 'w' -Spark 'c'))
        (Banner 'win_plate' (New-FrameBanner -Major 'g' -Minor 'w' -Spark 'c'))
        (Banner 'lose_banner' (New-WordmarkBanner -Major 'h' -Minor 'r' -Spark 'w'))
        (Banner 'lose_plate' (New-FrameBanner -Major 'h' -Minor 'r' -Spark 'w'))
    )
}
