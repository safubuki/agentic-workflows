[CmdletBinding()]
param(
  [string]$WorkspaceRoot,
  [string]$TargetRoot,
  [switch]$Apply,
  [switch]$NoMirror,
  [switch]$NoVariants,
  [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$PathValue) {
  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    return $null
  }
  return [System.IO.Path]::GetFullPath($PathValue)
}

function Is-UnderPath([string]$PathValue, [string]$RootValue) {
  $full = [System.IO.Path]::GetFullPath($PathValue).TrimEnd('\')
  $root = [System.IO.Path]::GetFullPath($RootValue).TrimEnd('\')
  return $full.Equals($root, [System.StringComparison]::OrdinalIgnoreCase) -or
    $full.StartsWith($root + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Ensure-Parent([string]$FilePath) {
  $parent = Split-Path -Parent $FilePath
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
}

function Get-HashOrNull([string]$FilePath) {
  if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
    return $null
  }
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $FilePath).Hash
}

function Get-GitTop([string]$PathValue) {
  try {
    $top = git -C $PathValue rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $top) {
      return [System.IO.Path]::GetFullPath($top.Trim())
    }
  } catch {}
  return $null
}

function Get-ProjectRoot([string]$PathValue, [string]$WorkspaceValue) {
  $gitTop = Get-GitTop $PathValue
  if ($gitTop) {
    return $gitTop
  }
  $full = [System.IO.Path]::GetFullPath($PathValue)
  $workspace = [System.IO.Path]::GetFullPath($WorkspaceValue).TrimEnd('\')
  $relative = $full.Substring($workspace.Length).TrimStart('\')
  $first = $relative.Split('\')[0]
  return Join-Path $workspace $first
}

function Get-GitDate([string]$ProjectRoot, [string]$FilePath) {
  try {
    $project = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
    $file = [System.IO.Path]::GetFullPath($FilePath)
    $rel = $file.Substring($project.Length + 1).Replace('\', '/')
    $date = git -C $project log -1 --format=%cI -- $rel 2>$null
    if ($LASTEXITCODE -eq 0 -and $date) {
      return [DateTimeOffset]::Parse($date.Trim())
    }
  } catch {}
  return [DateTimeOffset]::MinValue
}

function Find-SkillsRoots([string]$WorkspaceValue, [string]$TargetValue) {
  $skipNames = @('.git', 'node_modules', 'dist', 'build', '.next', 'coverage', '.venv', 'venv', '__pycache__')
  $queue = New-Object System.Collections.Queue
  foreach ($dir in Get-ChildItem -Path $WorkspaceValue -Directory -Force -ErrorAction SilentlyContinue) {
    $queue.Enqueue($dir)
  }

  $roots = @()
  while ($queue.Count -gt 0) {
    $dir = $queue.Dequeue()
    if (Is-UnderPath $dir.FullName $TargetValue) {
      continue
    }
    if ($skipNames -contains $dir.Name) {
      continue
    }

    $parent = Split-Path -Parent $dir.FullName
    $parentName = if ($parent) { Split-Path -Leaf $parent } else { '' }
    $skillParentNames = @('.agents', '.agent', '.claude', '.github')
    if ($dir.Name -eq 'skills' -and ($skillParentNames -contains $parentName)) {
      $roots += $dir
      continue
    }

    foreach ($child in Get-ChildItem -Path $dir.FullName -Directory -Force -ErrorAction SilentlyContinue) {
      $queue.Enqueue($child)
    }
  }
  return $roots | Sort-Object FullName
}

function Get-VariantRank($Candidate, [int]$Count) {
  $extension = [System.IO.Path]::GetExtension($Candidate.Path).ToLowerInvariant()
  $rel = $Candidate.Rel.Replace('\', '/')
  $isScript = @('.mjs', '.js', '.cjs', '.ts', '.tsx', '.ps1', '.py', '.sh') -contains $extension
  $isAccumulatedReference = $Candidate.Skill -like '*overview' -or
    $rel -match '^references/(implementation-patterns|project-details)\.md$'

  if ($isScript -or $isAccumulatedReference) {
    return [pscustomobject]@{
      A = [int64]$Candidate.Length
      B = $Candidate.GitDate.UtcTicks
      C = $Candidate.MTime.Ticks
      D = $Count
    }
  }

  return [pscustomobject]@{
    A = $Candidate.GitDate.UtcTicks
    B = $Candidate.MTime.Ticks
    C = [int64]$Candidate.Length
    D = $Count
  }
}

function Is-RankBetter($Left, $Right) {
  if ($null -eq $Right) {
    return $true
  }
  if ($Left.A -ne $Right.A) {
    return $Left.A -gt $Right.A
  }
  if ($Left.B -ne $Right.B) {
    return $Left.B -gt $Right.B
  }
  if ($Left.C -ne $Right.C) {
    return $Left.C -gt $Right.C
  }
  return $Left.D -gt $Right.D
}

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$defaultTarget = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..\..\..\..'))
if (-not $TargetRoot) {
  $TargetRoot = $defaultTarget
}
$TargetRoot = Resolve-FullPath $TargetRoot
if (-not $WorkspaceRoot) {
  $WorkspaceRoot = Split-Path -Parent $TargetRoot
}
$WorkspaceRoot = Resolve-FullPath $WorkspaceRoot

if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
  throw "WorkspaceRoot does not exist: $WorkspaceRoot"
}
if ($Apply -and -not (Test-Path -LiteralPath $TargetRoot -PathType Container)) {
  New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null
}

# Canonical output: .agents/skills (read by OpenAI Codex; also picked up by GitHub Copilot)
# Mirrors: .claude/skills (Claude Code) and .github/skills (GitHub Copilot)
$targetAgents = Join-Path $TargetRoot '.agents\skills'
$targetMirrors = [ordered]@{
  '.claude/skills' = Join-Path $TargetRoot '.claude\skills'
  '.github/skills' = Join-Path $TargetRoot '.github\skills'
}
$variantsRoot = Join-Path $TargetRoot '.skill-variants'

$sourceRoots = @(Find-SkillsRoots $WorkspaceRoot $TargetRoot)
$candidates = @()

foreach ($root in $sourceRoots) {
  $projectRoot = Get-ProjectRoot $root.FullName $WorkspaceRoot
  $project = Split-Path -Leaf $projectRoot
  $kind = Split-Path -Leaf (Split-Path -Parent $root.FullName)

  foreach ($skill in Get-ChildItem -Path $root.FullName -Directory -Force -ErrorAction SilentlyContinue) {
    foreach ($file in Get-ChildItem -Path $skill.FullName -File -Recurse -Force -ErrorAction SilentlyContinue) {
      $rel = $file.FullName.Substring($skill.FullName.Length + 1)
      $candidates += [pscustomobject]@{
        Skill = $skill.Name
        Rel = $rel
        Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
        Path = $file.FullName
        Length = $file.Length
        MTime = $file.LastWriteTime
        GitDate = (Get-GitDate $projectRoot $file.FullName)
        Project = $project
        Kind = $kind
        Source = "$project/$kind"
      }
    }
  }
}

$summary = [ordered]@{
  WorkspaceRoot = $WorkspaceRoot
  TargetRoot = $TargetRoot
  Apply = [bool]$Apply
  SourceRoots = @($sourceRoots).Count
  SourceSkillCopies = 0
  SourceSkillNames = 0
  CanonicalFiles = 0
  ConflictingFiles = 0
  Added = 0
  Updated = 0
  Unchanged = 0
  VariantFiles = 0
  Mirrored = 0
  TargetOnlySkills = @()
}

if (@($candidates).Count -eq 0) {
  if ($Json) {
    $summary | ConvertTo-Json -Depth 6
  } else {
    Write-Host "No source skills found."
  }
  exit 0
}

$summary.SourceSkillCopies = @(($candidates | Group-Object Skill, Source)).Count
$skillNames = @($candidates | Select-Object -ExpandProperty Skill -Unique | Sort-Object)
$summary.SourceSkillNames = $skillNames.Count

if ($Apply) {
  New-Item -ItemType Directory -Force -Path $targetAgents | Out-Null
  if (-not $NoMirror) {
    foreach ($mirror in $targetMirrors.Values) {
      New-Item -ItemType Directory -Force -Path $mirror | Out-Null
    }
  }
  if (-not $NoVariants) {
    New-Item -ItemType Directory -Force -Path $variantsRoot | Out-Null
  }
}

$manifest = [ordered]@{
  generatedAt = (Get-Date).ToString('o')
  workspace = $WorkspaceRoot
  target = $TargetRoot
  canonicalSkills = '.agents/skills'
  mirrorSkills = if ($NoMirror) { $null } else { @($targetMirrors.Keys) }
  sourceRoots = @($sourceRoots | ForEach-Object { $_.FullName })
  sourceSkillCount = $skillNames.Count
  targetOnlySkills = @()
  conflictCount = 0
  skills = @()
}

foreach ($skillName in $skillNames) {
  $skillFiles = @($candidates | Where-Object Skill -eq $skillName)
  $skillEntry = [ordered]@{
    name = $skillName
    sourceCount = @(($skillFiles | Group-Object Source)).Count
    files = @()
  }

  foreach ($rel in @($skillFiles | Select-Object -ExpandProperty Rel -Unique | Sort-Object)) {
    $relCandidates = @($skillFiles | Where-Object Rel -eq $rel)
    $hashGroups = @($relCandidates | Group-Object Hash)
    $groupChoices = @()

    foreach ($group in $hashGroups) {
      $bestCandidate = $null
      $bestRank = $null
      foreach ($candidate in @($group.Group)) {
        $rank = Get-VariantRank $candidate $group.Count
        if (Is-RankBetter $rank $bestRank) {
          $bestCandidate = $candidate
          $bestRank = $rank
        }
      }
      $groupChoices += [pscustomobject]@{
        Hash = $group.Name
        Count = $group.Count
        Candidate = $bestCandidate
        Rank = $bestRank
        Sources = @($group.Group | Select-Object -ExpandProperty Source -Unique | Sort-Object)
      }
    }

    $chosen = $null
    foreach ($choice in $groupChoices) {
      if ($null -eq $chosen -or (Is-RankBetter $choice.Rank $chosen.Rank)) {
        $chosen = $choice
      }
    }

    $targetFile = Join-Path (Join-Path $targetAgents $skillName) $rel
    $currentHash = Get-HashOrNull $targetFile
    if ($null -eq $currentHash) {
      $summary.Added += 1
    } elseif ($currentHash -ne $chosen.Hash) {
      $summary.Updated += 1
    } else {
      $summary.Unchanged += 1
    }

    if ($Apply -and $currentHash -ne $chosen.Hash) {
      Ensure-Parent $targetFile
      Copy-Item -LiteralPath $chosen.Candidate.Path -Destination $targetFile -Force
    }

    $variantEntries = @()
    foreach ($choice in @($groupChoices | Where-Object { $_.Hash -ne $chosen.Hash })) {
      $variantTarget = Join-Path (Join-Path (Join-Path $variantsRoot $skillName) $choice.Hash.Substring(0, 12)) $rel
      if (-not $NoVariants) {
        $summary.VariantFiles += 1
        if ($Apply) {
          Ensure-Parent $variantTarget
          Copy-Item -LiteralPath $choice.Candidate.Path -Destination $variantTarget -Force
        }
      }
      $variantEntries += [ordered]@{
        hash = $choice.Hash
        representative = $choice.Candidate.Path
        sources = @($choice.Sources)
        storedAt = if ($NoVariants) { $null } else { $variantTarget.Substring($TargetRoot.Length + 1) }
      }
    }

    if ($hashGroups.Count -gt 1) {
      $summary.ConflictingFiles += 1
      $manifest.conflictCount += 1
    }

    $summary.CanonicalFiles += 1
    $skillEntry.files += [ordered]@{
      path = $rel.Replace('\', '/')
      chosenHash = $chosen.Hash
      chosenSource = $chosen.Candidate.Source
      chosenPath = $chosen.Candidate.Path
      chosenGitDate = if ($chosen.Candidate.GitDate -eq [DateTimeOffset]::MinValue) { $null } else { $chosen.Candidate.GitDate.ToString('o') }
      variants = $variantEntries
    }
  }

  $manifest.skills += $skillEntry
}

if (Test-Path -LiteralPath $targetAgents -PathType Container) {
  $targetSkillNames = @(Get-ChildItem -Path $targetAgents -Directory -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
  $summary.TargetOnlySkills = @($targetSkillNames | Where-Object { $skillNames -notcontains $_ } | Sort-Object)
  $manifest.targetOnlySkills = $summary.TargetOnlySkills
}

if ($Apply -and -not $NoMirror) {
  foreach ($file in Get-ChildItem -Path $targetAgents -File -Recurse -Force -ErrorAction SilentlyContinue) {
    $rel = $file.FullName.Substring($targetAgents.Length + 1)
    $agentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    foreach ($mirror in $targetMirrors.Values) {
      $mirrorFile = Join-Path $mirror $rel
      $mirrorHash = Get-HashOrNull $mirrorFile
      if ($mirrorHash -ne $agentHash) {
        Ensure-Parent $mirrorFile
        Copy-Item -LiteralPath $file.FullName -Destination $mirrorFile -Force
        $summary.Mirrored += 1
      }
    }
  }
}

if ($Apply) {
  $manifestPath = Join-Path $TargetRoot '.skills-aggregation-manifest.json'
  # Write UTF-8 without BOM so the JSON parses cleanly (a leading BOM breaks JSON.parse).
  $manifestJson = $manifest | ConvertTo-Json -Depth 30
  [System.IO.File]::WriteAllText($manifestPath, $manifestJson, (New-Object System.Text.UTF8Encoding($false)))
}

if ($Json) {
  $summary | ConvertTo-Json -Depth 8
} else {
  Write-Host "Skill update summary:"
  foreach ($key in $summary.Keys) {
    $value = $summary[$key]
    if ($value -is [array]) {
      $value = if ($value.Count -eq 0) { '[]' } else { $value -join ', ' }
    }
    Write-Host ("  {0}: {1}" -f $key, $value)
  }
  if (-not $Apply) {
    Write-Host "Dry run only. Re-run with -Apply to update turtle-skills-neo."
  }
}
