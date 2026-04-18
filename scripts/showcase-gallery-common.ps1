function Get-ShowcaseGallerySlotDefinitions {
    return @(
        [pscustomobject]@{
            Slot = 'title'
            ReadmeSlot = 'readme-shot-1.png'
            Candidate = 'showcase-title.png'
        },
        [pscustomobject]@{
            Slot = 'beauty'
            ReadmeSlot = 'readme-shot-2.png'
            Candidate = 'showcase-beauty.png'
        },
        [pscustomobject]@{
            Slot = 'action'
            ReadmeSlot = 'readme-shot-3.png'
            Candidate = 'showcase-action.png'
        }
    )
}

function Get-ShowcaseGalleryManifestPath {
    param([string]$ShowcaseDir)

    return (Join-Path $ShowcaseDir 'verified-gallery.json')
}

function New-ShowcaseGallerySlotRecord {
    param(
        [string]$Slot,
        [string]$ReadmeSlot,
        [AllowNull()]
        [string]$SourceArtifactPath,
        [AllowNull()]
        [string]$SourceId,
        [AllowNull()]
        [string]$CaptureTime,
        [ValidateSet('fresh', 'stale', 'missing')]
        [string]$Freshness,
        [AllowNull()]
        [string]$FailureReason
    )

    return [ordered]@{
        slot = $Slot
        readmeSlot = $ReadmeSlot
        sourceArtifactPath = $SourceArtifactPath
        sourceId = $SourceId
        captureTime = $CaptureTime
        freshness = $Freshness
        failureReason = $FailureReason
    }
}

function New-ShowcaseGalleryManifest {
    param(
        [ValidateSet('fresh', 'stale', 'missing')]
        [string]$Status,
        [AllowNull()]
        [string]$FailureReason,
        [object[]]$Slots,
        [AllowNull()]
        [string]$ReportPath
    )

    return [ordered]@{
        version = 1
        updatedAt = (Get-Date -Format 'o')
        status = $Status
        failureReason = $FailureReason
        reportPath = $ReportPath
        slots = @($Slots)
    }
}

function Read-ShowcaseGalleryManifest {
    param([string]$ManifestPath)

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $ManifestPath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $null
        }

        return ($raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Write-ShowcaseGalleryManifest {
    param(
        [string]$ManifestPath,
        $Manifest
    )

    $directory = Split-Path -Parent $ManifestPath
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $Manifest.updatedAt = (Get-Date -Format 'o')
    $json = $Manifest | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $ManifestPath -Encoding ascii -Value $json
}

function Get-ShowcaseGallerySlotRecord {
    param(
        $Manifest,
        [string]$Slot
    )

    if ($null -eq $Manifest -or $null -eq $Manifest.slots) {
        return $null
    }

    return (@($Manifest.slots | Where-Object { $_.slot -eq $Slot }) | Select-Object -First 1)
}

function Test-ShowcaseGalleryManifestUsable {
    param($Manifest)

    if ($null -eq $Manifest -or $null -eq $Manifest.slots) {
        return $false
    }

    foreach ($slotDefinition in @(Get-ShowcaseGallerySlotDefinitions)) {
        $slotRecord = Get-ShowcaseGallerySlotRecord -Manifest $Manifest -Slot $slotDefinition.Slot
        if ($null -eq $slotRecord) {
            return $false
        }

        $sourceArtifactPath = [string]$slotRecord.sourceArtifactPath
        if ([string]::IsNullOrWhiteSpace($sourceArtifactPath)) {
            return $false
        }

        if (-not (Test-Path -LiteralPath $sourceArtifactPath)) {
            return $false
        }
    }

    return $true
}

function Convert-ShowcaseGalleryManifestToState {
    param(
        $Manifest,
        [ValidateSet('stale', 'missing')]
        [string]$Status,
        [AllowNull()]
        [string]$FailureReason,
        [AllowNull()]
        [string]$ReportPath
    )

    if ($Status -eq 'missing' -or -not (Test-ShowcaseGalleryManifestUsable -Manifest $Manifest)) {
        $missingSlots = foreach ($slotDefinition in @(Get-ShowcaseGallerySlotDefinitions)) {
            New-ShowcaseGallerySlotRecord `
                -Slot $slotDefinition.Slot `
                -ReadmeSlot $slotDefinition.ReadmeSlot `
                -SourceArtifactPath $null `
                -SourceId $null `
                -CaptureTime $null `
                -Freshness 'missing' `
                -FailureReason $FailureReason
        }

        return (New-ShowcaseGalleryManifest -Status 'missing' -FailureReason $FailureReason -Slots $missingSlots -ReportPath $ReportPath)
    }

    $staleSlots = foreach ($slotDefinition in @(Get-ShowcaseGallerySlotDefinitions)) {
        $slotRecord = Get-ShowcaseGallerySlotRecord -Manifest $Manifest -Slot $slotDefinition.Slot
        New-ShowcaseGallerySlotRecord `
            -Slot $slotDefinition.Slot `
            -ReadmeSlot $slotDefinition.ReadmeSlot `
            -SourceArtifactPath ([string]$slotRecord.sourceArtifactPath) `
            -SourceId ([string]$slotRecord.sourceId) `
            -CaptureTime ([string]$slotRecord.captureTime) `
            -Freshness 'stale' `
            -FailureReason $FailureReason
    }

    return (New-ShowcaseGalleryManifest -Status 'stale' -FailureReason $FailureReason -Slots $staleSlots -ReportPath $ReportPath)
}
