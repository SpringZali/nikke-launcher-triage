<#
.SYNOPSIS
  Checks the four official NIKKE PC launcher script files on Level Infinite's CDN.

.DESCRIPTION
  Makes four HTTPS GET requests to the OFFICIAL CDN host names and compares each file with the
  known-clean and known-modified versions listed in MotherSphere's report
  (https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5).

    - Each file is read into memory, hashed and thrown away. Nothing is saved or executed.
    - It never contacts the attacker's servers.
    - It is a snapshot from YOUR location, right now. Other CDN servers can differ, so a clean
      result here does not prove that every server in the world is clean.
    - "CHANGED" means the file is not on the list. SHIFT UP / Level Infinite may have updated it
      legitimately after this list was made. Check the README for newer information.

  Please READ this file before you run it. Do not run scripts you have not read.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Check-OfficialCdn.ps1
#>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# MD5 values are the ETags the CDN reports (the ETag is the MD5 of the file).
$files = @(
    @{ Name = 'aegis-fix.min.js';     Url = 'https://sg-gpts.playerinfinite.com/comm/assets/lib/aegis-fix.min.js';                    Clean = '44c576454a5b0b4ed60e1a983aa4e782'; Bad = '50d1861152ea7f6875ffceb7d08445b5' },
    @{ Name = 'images.7fec4c32.js';   Url = 'https://na-webassets.playerinfinite.com/comm/nikke_launcher/assets/images.7fec4c32.js';   Clean = '6e5f79cf9b7c364249f9de83ba7fa59e'; Bad = '481e9b5ab8fb93406bf31980b53e0578' },
    @{ Name = 'FeedList.feb647c9.js'; Url = 'https://na-webassets.playerinfinite.com/comm/nikke_launcher/assets/FeedList.feb647c9.js'; Clean = '04ee9800128396ba26f10ca70f170967'; Bad = 'b7d842200372ad0d9a84ef4cc8511311' },
    @{ Name = 'vue-bucket.min.js';    Url = 'https://na-webassets.playerinfinite.com/comm/assets/lib/vue-bucket.min.js';              Clean = '63bc3a47b35b80a5d200dc5624d7126e'; Bad = 'dd06875637a29cddd3bae2ba84142c78' }
)

function Get-Remote([string]$Url) {
    $req = [Net.HttpWebRequest][Net.WebRequest]::Create($Url)
    $req.UserAgent = 'nikke-launcher-triage-check'
    $req.Timeout = 25000
    $req.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate
    $resp = $req.GetResponse()
    try {
        $ms = New-Object System.IO.MemoryStream
        $resp.GetResponseStream().CopyTo($ms)
        return [pscustomobject]@{
            Bytes        = $ms.ToArray()
            ETag         = ($resp.Headers['ETag'] -replace '"', '')
            LastModified = $resp.Headers['Last-Modified']
        }
    } finally { $resp.Close() }
}

Write-Host ''
Write-Host 'Official NIKKE launcher script files (snapshot from your location)' -ForegroundColor Cyan
Write-Host ('Checked at ' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' GMT')
foreach ($h in 'sg-gpts.playerinfinite.com', 'na-webassets.playerinfinite.com') {
    $ips = try { ([Net.Dns]::GetHostAddresses($h) | ForEach-Object { $_.IPAddressToString }) -join ', ' } catch { 'lookup failed' }
    Write-Host ('  {0} resolves to {1}' -f $h, $ips) -ForegroundColor DarkGray
}
Write-Host ''

$md5 = [System.Security.Cryptography.MD5]::Create()
$problems = 0
foreach ($f in $files) {
    try {
        $r = Get-Remote $f.Url
        $hash = ([BitConverter]::ToString($md5.ComputeHash($r.Bytes)) -replace '-', '').ToLower()
        $text = [Text.Encoding]::UTF8.GetString($r.Bytes)
        $mentionsLoader = $text -match 'insightjs'
        $loaderLike = $text -match 'new Uint32Array\(\[[0-9, ]{40,}'
        if ($hash -eq $f.Bad -or $r.ETag -eq $f.Bad) { $verdict = 'MODIFIED (identical to the attacker version)'; $color = 'Red'; $problems++ }
        elseif ($mentionsLoader)                     { $verdict = 'SUSPICIOUS (mentions insightjs)';                $color = 'Red'; $problems++ }
        elseif ($hash -eq $f.Clean)                  { $verdict = 'CLEAN (identical to the known-clean file)';      $color = 'Green' }
        elseif ($loaderLike)                         { $verdict = 'CHANGED, with loader-like code: treat as suspicious'; $color = 'Red'; $problems++ }
        else                                         { $verdict = 'CHANGED (not on the list; not necessarily bad)'; $color = 'Yellow' }
        Write-Host ('{0,-22} {1}' -f $f.Name, $verdict) -ForegroundColor $color
        Write-Host ('{0,-22} md5 {1} | {2} bytes | Last-Modified {3}' -f '', $hash, $r.Bytes.Length, $r.LastModified) -ForegroundColor DarkGray
    } catch {
        Write-Host ('{0,-22} request failed: {1}' -f $f.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
}
Write-Host ''
if ($problems -gt 0) { Write-Host 'At least one file looks modified. Do not open the launcher, and tell the maintainers (open an issue).' -ForegroundColor Red }
Write-Host 'A clean result is a snapshot from your location, not a guarantee for every CDN server.' -ForegroundColor DarkGray
Write-Host ''
