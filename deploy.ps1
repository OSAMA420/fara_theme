<#
.SYNOPSIS
    Deploys theme changes to GitHub and the live Shopify theme.

.DESCRIPTION
    Always pulls before pushing, in both directions:

      1. Commits any pending local work.
      2. Pulls from GitHub (rebase) so local has any remote commits.
      3. Pulls merchant-owned files from the LIVE theme (theme editor
         settings and template JSON), so a deploy can never overwrite
         work done in the Shopify theme editor.
      4. Pushes to GitHub.
      5. Pushes only the changed code files to the LIVE theme.
      6. Moves the "last-deploy" tag so the next run knows what changed.

    Code files (sections, snippets, assets, layout, blocks, locales) are
    owned by this repo and get pushed up.
    Merchant files (config/settings_data.json, templates/*.json) are owned
    by the Shopify theme editor and only get pulled down.

.PARAMETER Message
    Commit message for any pending local changes.

.PARAMETER DryRun
    Show what would happen without pushing anything.

.EXAMPLE
    .\deploy.ps1 -Message "Update feature highlight colors"

.EXAMPLE
    .\deploy.ps1 -Message "Tweak spacing" -DryRun
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$Store     = 'faralondon.myshopify.com'
$LiveTheme = '144548528304'
$Branch    = 'main'
$DeployTag = 'last-deploy'

# Directories this repo owns and pushes to Shopify.
$CodePaths = @('sections/', 'snippets/', 'assets/', 'layout/', 'blocks/', 'locales/')

# Files the Shopify theme editor owns. Pulled down, never pushed up.
$MerchantOnly = @(
    'config/settings_data.json',
    'templates/*.json',
    'templates/customers/*.json'
)

function Write-Step($n, $text) {
    Write-Host ""
    Write-Host "[$n] $text" -ForegroundColor Cyan
}

function Fail($text) {
    Write-Host ""
    Write-Host "FAILED: $text" -ForegroundColor Red
    exit 1
}

Set-Location $PSScriptRoot

if (-not (Test-Path '.git')) { Fail "Not a git repository: $PSScriptRoot" }
if (-not (Get-Command shopify -ErrorAction SilentlyContinue)) { Fail "Shopify CLI not found on PATH." }

$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne $Branch) { Fail "On branch '$current', expected '$Branch'. Switch branches first." }

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN - nothing will be pushed." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
Write-Step 1 "Committing pending local changes"

$dirty = git status --porcelain
if ($dirty) {
    Write-Host $dirty
    if ($DryRun) {
        Write-Host "  would commit: $Message" -ForegroundColor Yellow
    } else {
        git add -A
        if (-not $?) { Fail "git add failed." }
        git commit -m $Message
        if (-not $?) { Fail "git commit failed." }
    }
} else {
    Write-Host "  nothing to commit."
}

# ---------------------------------------------------------------------------
Write-Step 2 "Pulling from GitHub"

git pull --rebase origin $Branch
if (-not $?) { Fail "git pull failed. Resolve conflicts, then run again." }

# ---------------------------------------------------------------------------
Write-Step 3 "Pulling theme-editor files from the LIVE theme"

if ($DryRun) {
    Write-Host "  skipped - a pull would overwrite local files, so it is not run in a dry run." -ForegroundColor Yellow
    Write-Host "  would pull: $($MerchantOnly -join ', ')" -ForegroundColor Yellow
    $merchantChanged = $null
} else {
    $pullArgs = @('theme', 'pull', "--store=$Store", "--theme=$LiveTheme", '--nodelete')
    foreach ($f in $MerchantOnly) { $pullArgs += '--only'; $pullArgs += $f }

    & shopify @pullArgs
    if (-not $?) { Fail "shopify theme pull failed." }

    $merchantChanged = git status --porcelain
}

if ($merchantChanged) {
    Write-Host ""
    Write-Host "  Theme editor changes came down from live:" -ForegroundColor Yellow
    Write-Host $merchantChanged
    if ($DryRun) {
        Write-Host "  would commit these." -ForegroundColor Yellow
    } else {
        git add -A
        git commit -m "Sync theme editor changes from live theme"
        if (-not $?) { Fail "Failed to commit theme editor changes." }
    }
} else {
    Write-Host "  live theme editor matches local - nothing new."
}

# ---------------------------------------------------------------------------
Write-Step 4 "Working out which code files to deploy"

$hasTag = git rev-parse --verify --quiet "refs/tags/$DeployTag"
if ($hasTag) {
    $changed = git diff --name-only "$DeployTag..HEAD"
} else {
    Write-Host "  No '$DeployTag' tag yet - using the last commit as the baseline."
    $changed = git diff --name-only 'HEAD~1..HEAD'
}

$toDeploy = @()
foreach ($file in $changed) {
    foreach ($dir in $CodePaths) {
        if ($file.StartsWith($dir)) {
            $toDeploy += $file
            break
        }
    }
}
$toDeploy = $toDeploy | Select-Object -Unique

if ($toDeploy.Count -eq 0) {
    Write-Host "  No code changes to deploy."
} else {
    Write-Host "  These files will go to the LIVE theme:"
    foreach ($f in $toDeploy) { Write-Host "    $f" -ForegroundColor Green }
}

# ---------------------------------------------------------------------------
Write-Step 5 "Pushing to GitHub"

if ($DryRun) {
    Write-Host "  would run: git push origin $Branch" -ForegroundColor Yellow
} else {
    git push origin $Branch
    if (-not $?) { Fail "git push failed." }
}

# ---------------------------------------------------------------------------
Write-Step 6 "Pushing code to the LIVE Shopify theme"

if ($toDeploy.Count -eq 0) {
    Write-Host "  Skipped - nothing to deploy."
} elseif ($DryRun) {
    Write-Host "  would push $($toDeploy.Count) file(s) to live theme $LiveTheme." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "  This updates the LIVE store: $Store" -ForegroundColor Yellow
    $answer = Read-Host "  Type 'yes' to continue"
    if ($answer -ne 'yes') {
        Write-Host ""
        Write-Host "Stopped. GitHub is updated; the live theme was not touched." -ForegroundColor Yellow
        exit 0
    }

    $pushArgs = @('theme', 'push', "--store=$Store", "--theme=$LiveTheme", '--allow-live', '--nodelete')
    foreach ($f in $toDeploy) { $pushArgs += '--only'; $pushArgs += $f }

    & shopify @pushArgs
    if (-not $?) { Fail "shopify theme push failed. GitHub is updated; live may be unchanged." }

    git tag -f $DeployTag HEAD
    git push origin $DeployTag --force
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  GitHub : github.com/OSAMA420/fara_theme ($Branch)"
Write-Host "  Live    : https://$Store/admin/themes/$LiveTheme/editor"
