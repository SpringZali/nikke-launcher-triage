<#
.SYNOPSIS
  Read-only check of the official NIKKE PC launcher script files on Level Infinite's CDN.

.DESCRIPTION
  Part 1 compares the four files that were modified on 2026-09-27 with the known-clean and
  known-modified versions listed in MotherSphere's write-up
  (https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5), on both CDN hosts.

  Part 2 looks at the front-end the launcher loads since Nov 4 (a rebuilt set of files). It reads
  the main script and every script file that the main script names, and searches them for the
  loader patterns described in the write-up. There are no reference copies of these files, so
  Part 2 is a PATTERN CHECK ONLY: "no pattern found" is not proof that a file is clean, and it
  says nothing about other weaknesses of the launcher.

    - Each file is read into memory, hashed and thrown away. Nothing is saved or executed.
    - Only the two OFFICIAL CDN host names below are contacted. Redirects are not followed.
      It never contacts the attacker's servers.
    - It is a snapshot from YOUR location, right now. Other CDN servers can differ.
    - "CHANGED" means the file is not on the list. The publisher may have updated it legitimately
      after this list was made. Check the README for newer information.
    - The main script's name changes when the publisher rebuilds the launcher's front-end. If it
      is not found, Part 2 cannot run until the new name is known (pass it with -MainScript).
      Which files the launcher loads was reported by the write-up's author from a fresh install;
      this script cannot discover that list by itself.

  Please READ this file before you run it. Do not run scripts you have not read.

.PARAMETER MainScript
  File name of the launcher front-end's main script. Default: the one in use since Nov 4, 2026.

.PARAMETER SelfTest
  Runs the built-in tests of the verdict and pattern logic on harmless sample text and exits.
  Makes no network request.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Check-OfficialCdn.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Check-OfficialCdn.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [string]$MainScript = 'nikke.c2f24fe0.js',
    [switch]$SelfTest
)

$hosts     = 'sg-gpts.playerinfinite.com', 'na-webassets.playerinfinite.com'
$assetHost = 'na-webassets.playerinfinite.com'
$assetPath = '/comm/nikke_launcher/assets/'
$maxBytes  = 8MB      # no launcher script is near this size; a larger answer is treated as a failure
$maxFiles  = 200      # upper bound for the files read in Part 2

# MD5 values are the ETags the CDN reports (the ETag is the MD5 of the file).
$files = @(
    @{ Name = 'aegis-fix.min.js';     Path = '/comm/assets/lib/aegis-fix.min.js';                Clean = '44c576454a5b0b4ed60e1a983aa4e782'; Bad = '50d1861152ea7f6875ffceb7d08445b5'; Note = '' },
    @{ Name = 'vue-bucket.min.js';    Path = '/comm/assets/lib/vue-bucket.min.js';               Clean = '63bc3a47b35b80a5d200dc5624d7126e'; Bad = 'dd06875637a29cddd3bae2ba84142c78'; Note = '' },
    @{ Name = 'FeedList.feb647c9.js'; Path = '/comm/nikke_launcher/assets/FeedList.feb647c9.js'; Clean = '04ee9800128396ba26f10ca70f170967'; Bad = 'b7d842200372ad0d9a84ef4cc8511311'; Note = '' },
    @{ Name = 'images.7fec4c32.js';   Path = '/comm/nikke_launcher/assets/images.7fec4c32.js';   Clean = '6e5f79cf9b7c364249f9de83ba7fa59e'; Bad = '481e9b5ab8fb93406bf31980b53e0578'; Note = 'no longer loaded by the current front-end' },
    # The current front-end asks for these two with a query string, and a CDN can cache each query string separately.
    @{ Name = 'aegis-fix.min.js?t=20261104';  Path = '/comm/assets/lib/aegis-fix.min.js?t=20261104';  Clean = '44c576454a5b0b4ed60e1a983aa4e782'; Bad = '50d1861152ea7f6875ffceb7d08445b5'; Note = '' },
    @{ Name = 'vue-bucket.min.js?v=20261104'; Path = '/comm/assets/lib/vue-bucket.min.js?v=20261104'; Clean = '63bc3a47b35b80a5d200dc5624d7126e'; Bad = 'dd06875637a29cddd3bae2ba84142c78'; Note = '' }
)

# Loader patterns from the write-up: the attacker's domain, the URL hidden in an integer array,
# and the ".org" fallback built from character codes.
$patterns = [ordered]@{
    'mentions insightjs'             = 'insightjs'
    'URL hidden in an integer array' = 'new Uint32Array\(\[[0-9, ]{40,}'
    '".org" fallback'                = 'fromCharCode\(111,\s*114,\s*103\)'
}

function Find-Patterns([string]$Text) {
    $hits = @()
    foreach ($k in $patterns.Keys) { if ($Text -match $patterns[$k]) { $hits += $k } }
    return ,$hits
}

# Works out the verdict for one file of Part 1. Returns the text, the colour and whether it is a problem.
function Get-Verdict([string]$Hash, [string]$ETag, [string]$Text, [string]$Clean, [string]$Bad) {
    $hits = Find-Patterns $Text
    if ($Hash -eq $Bad -or $ETag -eq $Bad) { return [pscustomobject]@{ Text = 'MODIFIED (identical to the attacker version)'; Color = 'Red'; Problem = $true } }
    if ($hits.Count -gt 0)                 { return [pscustomobject]@{ Text = 'SUSPICIOUS (' + ($hits -join '; ') + ')';       Color = 'Red'; Problem = $true } }
    if ($Hash -eq $Clean)                  { return [pscustomobject]@{ Text = 'CLEAN (identical to the known-clean file)';     Color = 'Green'; Problem = $false } }
    return [pscustomobject]@{ Text = 'CHANGED (not on the list; not necessarily bad)'; Color = 'Yellow'; Problem = $false }
}

# Every hashed script file name that the main script mentions, plus the main script itself.
function Get-ScriptNames([string]$MainText, [string]$MainName) {
    $found = @([regex]::Matches($MainText, '[A-Za-z0-9_-][A-Za-z0-9_.-]*\.[0-9a-f]{8}\.js') | ForEach-Object { $_.Value })
    return @(($found + $MainName) | Sort-Object -Unique)
}

if ($SelfTest) {
    $fail = 0
    function Test-Case([string]$Name, [bool]$Ok) {
        if ($Ok) { Write-Host ('PASS  ' + $Name) -ForegroundColor Green } else { Write-Host ('FAIL  ' + $Name) -ForegroundColor Red; $script:fail++ }
    }
    $cleanText  = 'function hello(){ console.log("plain launcher code"); }'
    $arrayText  = 'x=new TextDecoder().decode(new Uint8Array(new Uint32Array([1953719668, 1953719668, 1953719668, 1953719668, 1953719668, 1953719668]).buffer));'
    $orgText    = 'var t=String.fromCharCode(111,114,103);'
    $domainText = 'var u="https://insightjs.example-not-real/l.js";'
    Test-Case 'plain code has no pattern'                 ((Find-Patterns $cleanText).Count -eq 0)
    Test-Case 'integer-array URL is recognised'           ((Find-Patterns $arrayText) -contains 'URL hidden in an integer array')
    Test-Case '".org" fallback is recognised'             ((Find-Patterns $orgText) -contains '".org" fallback')
    Test-Case 'the domain name is recognised'             ((Find-Patterns $domainText) -contains 'mentions insightjs')
    Test-Case 'known-modified hash gives MODIFIED'        ((Get-Verdict 'bbbb' '' $cleanText 'aaaa' 'bbbb').Text -like 'MODIFIED*')
    Test-Case 'known-modified ETag gives MODIFIED'        ((Get-Verdict 'cccc' 'bbbb' $cleanText 'aaaa' 'bbbb').Text -like 'MODIFIED*')
    Test-Case 'known-clean hash gives CLEAN'              ((Get-Verdict 'aaaa' 'aaaa' $cleanText 'aaaa' 'bbbb').Text -like 'CLEAN*')
    Test-Case 'unknown hash without pattern gives CHANGED' ((Get-Verdict 'cccc' 'cccc' $cleanText 'aaaa' 'bbbb').Text -like 'CHANGED*')
    Test-Case 'unknown hash with a pattern gives SUSPICIOUS' ((Get-Verdict 'cccc' 'cccc' $orgText 'aaaa' 'bbbb').Text -like 'SUSPICIOUS*')
    Test-Case 'CHANGED is not counted as a problem'       (-not (Get-Verdict 'cccc' 'cccc' $cleanText 'aaaa' 'bbbb').Problem)
    Test-Case 'SUSPICIOUS is counted as a problem'        ((Get-Verdict 'cccc' 'cccc' $arrayText 'aaaa' 'bbbb').Problem)
    $names = Get-ScriptNames 'import("./images.64d80e3e.js");import("./video-js.c239e58d.js");a="x.css";b="../evil.js";c="FeedList.feb647c9.js"' 'nikke.c2f24fe0.js'
    Test-Case 'script names are taken from the main script' (($names -join ',') -eq 'FeedList.feb647c9.js,images.64d80e3e.js,nikke.c2f24fe0.js,video-js.c239e58d.js')
    Test-Case 'a name cannot contain a path'              (@($names | Where-Object { $_ -match '[\\/]' }).Count -eq 0)
    Write-Host ''
    if ($fail -gt 0) { Write-Host "$fail self-test(s) failed." -ForegroundColor Red; exit 1 }
    Write-Host 'All self-tests passed. No network request was made.' -ForegroundColor Green
    exit 0
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# One GET to an official host. Redirects are not followed and the answer size is bounded.
function Get-Remote([string]$HostName, [string]$PathAndQuery) {
    if ($hosts -notcontains $HostName) { throw "host not on the list: $HostName" }
    $req = [Net.HttpWebRequest][Net.WebRequest]::Create('https://' + $HostName + $PathAndQuery)
    $req.UserAgent = 'nikke-launcher-triage-check'
    $req.Timeout = 30000
    $req.ReadWriteTimeout = 30000
    $req.AllowAutoRedirect = $false
    $req.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
    $resp = $req.GetResponse()
    try {
        if ([int]$resp.StatusCode -ne 200) { throw ('unexpected HTTP status ' + [int]$resp.StatusCode + ' (redirects are not followed)') }
        $ms = New-Object System.IO.MemoryStream
        $stream = $resp.GetResponseStream()
        $buf = New-Object byte[] 65536
        while ($true) {
            $n = $stream.Read($buf, 0, $buf.Length)
            if ($n -le 0) { break }
            $ms.Write($buf, 0, $n)
            if ($ms.Length -gt $maxBytes) { throw 'the answer is larger than the size limit' }
        }
        return [pscustomobject]@{
            Bytes        = $ms.ToArray()
            ETag         = ($resp.Headers['ETag'] -replace '"', '')
            LastModified = $resp.Headers['Last-Modified']
        }
    } finally { $resp.Close() }
}

$md5 = [System.Security.Cryptography.MD5]::Create()
function Get-Md5([byte[]]$Bytes) { return ([BitConverter]::ToString($md5.ComputeHash($Bytes)) -replace '-', '').ToLower() }

Write-Host ''
Write-Host 'Official NIKKE launcher script files (snapshot from your location)' -ForegroundColor Cyan
Write-Host ('Checked at ' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' GMT')
foreach ($h in $hosts) {
    $ips = try { ([Net.Dns]::GetHostAddresses($h) | ForEach-Object { $_.IPAddressToString }) -join ', ' } catch { 'lookup failed' }
    Write-Host ('  {0} resolves to {1}' -f $h, $ips) -ForegroundColor DarkGray
}

$problems = 0
$failed = 0

# ---- Part 1: the four files that were modified on Sep 27 -------------------------------------
Write-Host ''
Write-Host 'Part 1. The four files that were modified on Sep 27, on both hosts' -ForegroundColor Cyan
foreach ($f in $files) {
    foreach ($h in $hosts) {
        $label = '{0} @ {1}' -f $f.Name, ($h -replace '\.playerinfinite\.com$', '')
        try {
            $r = Get-Remote $h $f.Path
            $hash = Get-Md5 $r.Bytes
            $v = Get-Verdict $hash $r.ETag ([Text.Encoding]::UTF8.GetString($r.Bytes)) $f.Clean $f.Bad
            if ($v.Problem) { $problems++ }
            $text = $v.Text
            if ($f.Note) { $text += ' [' + $f.Note + ']' }
            Write-Host ('{0,-44} {1}' -f $label, $text) -ForegroundColor $v.Color
            Write-Host ('{0,-44} md5 {1} | {2} bytes | Last-Modified {3}' -f '', $hash, $r.Bytes.Length, $r.LastModified) -ForegroundColor DarkGray
        } catch {
            $failed++
            Write-Host ('{0,-44} request failed: {1}' -f $label, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

# ---- Part 2: the front-end the launcher loads now ---------------------------------------------
Write-Host ''
Write-Host 'Part 2. The current launcher front-end (pattern check only, no reference copies exist)' -ForegroundColor Cyan
$scanned = 0
$suspicious = New-Object System.Collections.Generic.List[string]
$newest = $null
$part2Ran = $false
try {
    $main = Get-Remote $assetHost ($assetPath + $MainScript)
    $part2Ran = $true
    Write-Host ('{0,-44} md5 {1} | {2} bytes | Last-Modified {3}' -f $MainScript, (Get-Md5 $main.Bytes), $main.Bytes.Length, $main.LastModified) -ForegroundColor DarkGray
    $names = Get-ScriptNames ([Text.Encoding]::UTF8.GetString($main.Bytes)) $MainScript
    if ($names -contains 'images.7fec4c32.js') { Write-Host '  note: the main script still names images.7fec4c32.js' -ForegroundColor Yellow }
    if ($names.Count -gt $maxFiles) {
        Write-Host ("  the main script names $($names.Count) files; only the first $maxFiles are read, so this part is incomplete") -ForegroundColor Yellow
        $failed++
        $names = @($names | Select-Object -First $maxFiles)
    }
    foreach ($n in $names) {
        try {
            $r = Get-Remote $assetHost ($assetPath + $n)
        } catch {
            $failed++
            Write-Host ('  {0}: request failed: {1}' -f $n, $_.Exception.Message) -ForegroundColor Yellow
            continue
        }
        $scanned++
        $hits = Find-Patterns ([Text.Encoding]::UTF8.GetString($r.Bytes))
        if ($hits.Count -gt 0) { $suspicious.Add(('{0}: {1}' -f $n, ($hits -join '; '))); $problems++ }
        $lm = [DateTime]::MinValue
        if ($r.LastModified -and [DateTime]::TryParse([string]$r.LastModified, [ref]$lm)) {
            if (-not $newest -or $lm -gt $newest) { $newest = $lm }
        }
    }
    if ($suspicious.Count -gt 0) {
        Write-Host ('{0} of {1} script files contain a loader pattern:' -f $suspicious.Count, $scanned) -ForegroundColor Red
        $suspicious | ForEach-Object { Write-Host ('  - ' + $_) -ForegroundColor Red }
    } else {
        Write-Host ('{0} of {1} script files named in the main script were read: no loader pattern found.' -f $scanned, $names.Count) -ForegroundColor Green
    }
    if ($newest) { Write-Host ('Newest Last-Modified among them: ' + $newest.ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' GMT') -ForegroundColor DarkGray }
} catch {
    $failed++
    Write-Host ('{0}: request failed: {1}' -f $MainScript, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host '  If the publisher rebuilt the front-end, the main script has a new name. Part 2 did NOT run.' -ForegroundColor Yellow
}

Write-Host ''
if ($problems -gt 0) { Write-Host 'At least one file looks modified. Do not open the launcher, and tell the maintainers (open an issue).' -ForegroundColor Red }
if ($failed -gt 0)   { Write-Host "$failed request(s) or step(s) failed, so this check is INCOMPLETE." -ForegroundColor Yellow }
if (-not $part2Ran)  { Write-Host 'The current front-end was not checked.' -ForegroundColor Yellow }
Write-Host 'Part 1 compares with known copies. Part 2 is a pattern check only and cannot prove that a file is clean.' -ForegroundColor DarkGray
Write-Host 'This is a snapshot from your location, not a guarantee for every CDN server.' -ForegroundColor DarkGray
Write-Host ''
if ($problems -gt 0) { exit 2 }
if ($failed -gt 0 -or -not $part2Ran) { exit 3 }
exit 0
