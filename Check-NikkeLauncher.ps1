<#
.SYNOPSIS
  Read-only self-check for the NIKKE PC launcher incident (November 2026).

.DESCRIPTION
  Looks for the indicators in the publisher's manual check guide for the PC launcher
  (README.md, section 3): the "k2f_chan" line in debug.log, the HKCU registry key, the
  Chrome-folder DLL and the 205,135-byte tinyget log. It also looks for a few extras from
  MotherSphere's community report (https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5).
  It prints a plain-language result that uses the rows of README.md, section 4.

  What this script does NOT do:
    - It never connects to the internet.
    - It never changes, deletes, moves or uploads anything. It only reads, so it does not
      remove anything either: use the official scan or README.md, section 3, step 3.
    - It never prints file contents, passwords, your computer name or the agent ID.
      It prints yes/no results, counts, dates and paths (your user name is hidden).
    - It cannot prove that a PC is clean. Missing evidence is not proof.

  Please READ this file before you run it. Do not run scripts you have not read.

.PARAMETER InstallPath
  Optional. The NIKKE folder that contains "Launcher". If left out, the script looks for it.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Check-NikkeLauncher.ps1
#>
[CmdletBinding()]
param([string]$InstallPath)

$ErrorActionPreference = 'SilentlyContinue'

$found  = New-Object System.Collections.Generic.List[string]   # signs that the malicious program ran or left something behind
$extras = New-Object System.Collections.Generic.List[string]   # first-stage traces from the community report, not in the official guide
$notes  = New-Object System.Collections.Generic.List[string]   # context

function Say([string]$Text, [string]$Color = 'Gray') { Write-Host $Text -ForegroundColor $Color }

function Hide-Identity([string]$Text) {
    if (-not $Text) { return $Text }
    $t = $Text -replace [regex]::Escape($env:USERNAME), '<user>'
    return ($t -replace [regex]::Escape($env:COMPUTERNAME), '<pc>')
}

# Returns which of $Needles occur in the file. Reads in chunks with shared access. Never writes.
function Find-InFile([string]$Path, [string[]]$Needles) {
    $found = @()
    try {
        $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
        try {
            $latin1 = [System.Text.Encoding]::GetEncoding(28591)
            $chunk = 4MB; $overlap = 64
            $buf = New-Object byte[] ($chunk + $overlap)
            $carry = 0
            while ($true) {
                $n = $fs.Read($buf, $carry, $chunk)
                if ($n -le 0) { break }
                $total = $carry + $n
                $text = $latin1.GetString($buf, 0, $total)
                foreach ($needle in $Needles) {
                    if ($text.Contains($needle) -and ($found -notcontains $needle)) { $found += $needle }
                }
                $keep = [Math]::Min($overlap, $total)
                [Array]::Copy($buf, $total - $keep, $buf, 0, $keep)
                $carry = $keep
            }
        } finally { $fs.Dispose() }
    } catch { }
    return ,$found
}

function Read-TextShared([string]$Path) {
    try {
        $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        try { return $sr.ReadToEnd() } finally { $sr.Dispose() }
    } catch { return '' }
}

Say ''
Say 'NIKKE launcher self-check (read-only, offline)' 'Cyan'
Say ('Run on ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') + ' local time.')
Say ''

if (Get-Process | Where-Object { $_.Name -match '^(nikke_launcher|tbs_browser)' }) {
    $notes.Add('The launcher is running right now. Close it, the game and Chrome first, as the publisher''s guide asks.')
}

# ---- 1. launcher folders and logs ---------------------------------------------------------
Say '1/5  Looking for NIKKE launcher folders (this can take a minute)...'
$roots = New-Object System.Collections.Generic.List[string]
if ($InstallPath) {
    $roots.Add($InstallPath.TrimEnd('\'))
} else {
    $keys = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    foreach ($e in (Get-ItemProperty $keys)) {
        if ($e.DisplayName -match 'NIKKE|Level Infinite' -and $e.InstallLocation) { $roots.Add($e.InstallLocation.TrimEnd('\')) }
    }
    foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
        if ($drive.DriveType -eq 'Fixed' -and $drive.IsReady) {
            foreach ($d in (Get-ChildItem -Path $drive.RootDirectory.FullName -Directory -Recurse -Depth 3 -Filter '*NIKKE*')) { $roots.Add($d.FullName) }
        }
    }
}
$launcherDirs = New-Object System.Collections.Generic.List[string]
foreach ($r in ($roots | Sort-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $r)) { continue }
    if (Test-Path -LiteralPath (Join-Path $r 'Launcher\intl_service')) { $launcherDirs.Add((Join-Path $r 'Launcher')) }
    foreach ($d in (Get-ChildItem -LiteralPath $r -Directory -Recurse -Depth 3 -Filter 'intl_service')) {
        if ($d.Parent.Name -eq 'Launcher') { $launcherDirs.Add($d.Parent.FullName) }
    }
}
$launcherDirs = @($launcherDirs | Sort-Object -Unique)

$logFound = $false
$coverage = 'n/a'
$logStartsLate = $false
$k2fHits = 0; $agentStateHits = 0; $loaderHits = 0; $tinygetHits = 0
$skipExt = '.dll', '.exe', '.png', '.jpg', '.jpeg', '.ttf', '.pak', '.mp4'
foreach ($ld in $launcherDirs) {
    Say ('     launcher folder: ' + (Hide-Identity $ld))
    $log = Join-Path $ld 'intl_service\debug.log'
    if (Test-Path -LiteralPath $log) {
        $logFound = $true
        $txt = Read-TextShared $log
        $m = [regex]::Matches($txt, '(?m)^\[(\d{4})/\d{6}\.\d+:')
        if ($m.Count -gt 0) {
            $a = $m[0].Groups[1].Value
            $b = $m[$m.Count - 1].Groups[1].Value
            $coverage = '{0}-{1} to {2}-{3} (month-day, the log has no year)' -f $a.Substring(0, 2), $a.Substring(2, 2), $b.Substring(0, 2), $b.Substring(2, 2)
            if ([int]$a -gt 1023 -and [int]$a -le 1104) { $logStartsLate = $true }
        }
    }
    # The publisher's guide: a tinyget log of exactly 205,135 bytes is the downloaded file.
    foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $ld 'log\tinyget') -File -Filter 'tinyget.*.log')) {
        if ($f.Length -eq 205135) { $tinygetHits++ }
    }
    # Scan every file in the Launcher folder, so other log layouts are covered too.
    foreach ($f in (Get-ChildItem -LiteralPath $ld -Recurse -File -Force | Where-Object { $_.Length -lt 300MB -and $skipExt -notcontains $_.Extension.ToLower() })) {
        $hit = Find-InFile $f.FullName @('k2f_chan', 'k2f.agent', 'insightjs')
        if ($hit -contains 'k2f_chan')  { $k2fHits++ }
        if ($hit -contains 'k2f.agent') { $agentStateHits++ }
        if ($hit -contains 'insightjs') { $loaderHits++ }
    }
}
if ($launcherDirs.Count -eq 0) { Say '     no launcher folder found' }

# ---- 2. launcher data in the user profile -----------------------------------------------------
Say '2/5  Checking the launcher data in your user profile...'
$stateDirs = @()
foreach ($base in $env:APPDATA, $env:LOCALAPPDATA) { $stateDirs += @(Get-ChildItem -LiteralPath $base -Directory -Filter 'nikke_launcher*') }
$stateAgentHits = 0; $stateLoaderHits = 0
foreach ($sd in $stateDirs) {
    Say ('     data folder: ' + (Hide-Identity $sd.FullName))
    $tbs = Join-Path $sd.FullName 'tbs_cache'
    foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $tbs 'Local Storage\leveldb') -File)) {
        if ((Find-InFile $f.FullName @('k2f.agent', 'k2f_chan')).Count -gt 0) { $stateAgentHits++ }
    }
    foreach ($f in (Get-ChildItem -LiteralPath $tbs -Recurse -File | Where-Object { $_.Length -lt 300MB })) {
        if ((Find-InFile $f.FullName @('insightjs')).Count -gt 0) { $stateLoaderHits++ }
    }
}
if ($stateDirs.Count -eq 0) { Say '     no nikke_launcher data folder found' }

# ---- 3. registry key and DLL folder from the publisher's guide -------------------------------------
Say '3/5  Checking the registry key and the DLL folder from the publisher''s guide...'
$clsidPresent = Test-Path 'HKCU:\Software\Classes\CLSID\{E77CC89B-7401-4C04-8CED-149DB35ADD04}'
$peh = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\PlatformExperienceHelper'
$dllFolders = @(Get-ChildItem -LiteralPath $peh -Directory | Where-Object {
        $_.Name -match '^[0-9a-fA-F]{64}$' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'platform_experience_helper.dll'))
    })

# ---- 4. live network state ---------------------------------------------------------------------
Say '4/5  Checking live network state on this PC...'
$badIps = '89.127.233.127', '89.126.250.172'
$conns = @(Get-NetTCPConnection | Where-Object { $badIps -contains $_.RemoteAddress })
$dnsHits = @(Get-DnsClientCache | Where-Object { $_.Entry -match 'insightjs' })
$hostsHits = @(Select-String -Path (Join-Path $env:SystemRoot 'System32\drivers\etc\hosts') -Pattern 'insightjs')

# ---- 5. result -----------------------------------------------------------------------------------
Say '5/5  Working out the result...'
# Indicators from the publisher's manual check guide
if ($k2fHits -gt 0)                     { $found.Add("'k2f_chan' found in $k2fHits launcher file(s). The publisher's guide says a malicious program may have run.") }
if ($clsidPresent)                      { $found.Add('The HKCU registry key {E77CC89B-7401-4C04-8CED-149DB35ADD04} exists. (Only the HKCU copy counts; the HKLM copy is normal Windows.)') }
if ($dllFolders.Count -gt 0)            { $found.Add("$($dllFolders.Count) folder(s) with platform_experience_helper.dll under Chrome's PlatformExperienceHelper.") }
if ($tinygetHits -gt 0)                 { $found.Add("$tinygetHits file(s) of exactly 205,135 bytes in Launcher\log\tinyget.") }
# Extras from the community report that also mean the program ran
if (($agentStateHits + $stateAgentHits) -gt 0) { $found.Add("The program's saved state ('k2f.agent' or 'k2f_chan') in launcher files or saved data ($($agentStateHits + $stateAgentHits) file(s)). From the community report, not in the official guide.") }
if ($conns.Count -gt 0)                 { $found.Add('This PC has a live connection to a known attacker IP address right now.') }
# First-stage traces (community report)
if (($loaderHits + $stateLoaderHits) -gt 0) { $extras.Add("'insightjs' in launcher files or cache ($($loaderHits + $stateLoaderHits) file(s)): the modified script was loaded (first stage).") }
if ($dnsHits.Count -gt 0)               { $extras.Add("This PC looked up 'insightjs' recently ($($dnsHits.Count) DNS cache entries).") }
if ($hostsHits.Count -gt 0)             { $notes.Add('Your hosts file mentions insightjs (expected if you blocked it yourself).') }
if ($logFound -and $logStartsLate)      { $notes.Add("Your debug.log starts after Oct 23 ($coverage), so earlier launches are not covered by it.") }

$noEvidence = (-not $logFound) -and ($stateDirs.Count -eq 0)

Say ''
Say '==================== RESULT ====================' 'Cyan'
if ($found.Count -gt 0) {
    Say 'FOUND - signs that the malicious program ran or left something behind' 'Red'
    $found | ForEach-Object { Say ('  - ' + $_) 'Red' }
    Say ''
    Say 'Follow the "Found" row in README.md, section 4:' 'Yellow'
    Say '  1. If you want a record, copy Launcher\intl_service\debug.log first and keep the copy private.' 'Yellow'
    Say '  2. Remove it: accept the removal the official scan offers, or follow section 3, step 3.' 'Yellow'
    Say '  3. From another device, change your passwords and revoke API keys and tokens (section 4).' 'Yellow'
    Say '  4. Update your antivirus, then run a full scan and a Windows Security Offline Scan (section 3, step 5).' 'Yellow'
} elseif ($noEvidence) {
    Say 'CANNOT CHECK - the files this check relies on are not here' 'DarkYellow'
    Say '  The launcher data and debug.log are missing. That is what you see after an uninstall or reinstall'
    Say '  (the uninstaller deletes them), or if the launcher was never installed for this Windows user.'
    Say '  No registry key, DLL folder or live connection was found either, which is good, but it is not proof.'
    Say ''
    Say '  If you started the PC launcher after Sep 27, 06:41 GMT, follow the "Cannot check" row in README.md, section 4.'
} else {
    Say 'NOT FOUND - none of the official indicators is on this PC' 'Green'
    Say '  The publisher says that not finding the string does not completely rule out risk. Update your antivirus,'
    Say '  run a full scan and a Windows Security Offline Scan, and protect your accounts if you started the PC'
    Say '  launcher after Sep 27, 06:41 GMT (the "Not found" row in README.md, section 4).'
    Say '  Look at the log coverage below and compare it with the days you played.'
}
if ($extras.Count -gt 0) {
    Say ''
    Say 'Also seen (community report, not in the official guide):' 'Yellow'
    $extras | ForEach-Object { Say ('  - ' + $_) 'Yellow' }
}
if ($notes.Count -gt 0) { Say ''; $notes | ForEach-Object { Say ('Note: ' + $_) } }

Say ''
Say 'Summary you can paste when you ask for help (it contains no personal data):' 'Cyan'
$rows = @(
    @('launcher folder found',            $(if ($launcherDirs.Count -gt 0) { 'yes' } else { 'no' })),
    @('debug.log found',                  $(if ($logFound) { 'yes' } else { 'no' })),
    @('debug.log coverage',               $coverage),
    @("'k2f_chan' file hits",             ($k2fHits + $stateAgentHits)),
    @('205,135-byte tinyget logs',        $tinygetHits),
    @("'k2f.agent' file hits",            $agentStateHits),
    @("'insightjs' file hits",            ($loaderHits + $stateLoaderHits)),
    @('nikke_launcher data folder',       $(if ($stateDirs.Count -gt 0) { 'yes' } else { 'no' })),
    @('HKCU CLSID persistence key',       $(if ($clsidPresent) { 'YES' } else { 'no' })),
    @('Chrome helper DLL folder',         $(if ($dllFolders.Count -gt 0) { 'YES' } else { 'no' })),
    @('connections to attacker IPs',      $conns.Count),
    @('insightjs entries in DNS cache',   $dnsHits.Count)
)
foreach ($row in $rows) { Say ('  {0,-34} {1}' -f $row[0], $row[1]) }
Say ''
Say 'Reminder: no check can prove a PC is clean. Nothing was changed on your PC.' 'DarkGray'
Say ''
