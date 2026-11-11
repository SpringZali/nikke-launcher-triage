<#
.SYNOPSIS
  RETIRED on 2026-11-11. This script no longer checks anything.

.DESCRIPTION
  Until guide v3.7 this file was a read-only self-check for the NIKKE PC launcher incident.

  The author of the community write-up reviewed it and found that it could mislead:
    - it could print "NOT FOUND" although it had not read debug.log at all;
    - its size rule did not count the Oct 23 build of the malicious program
      (Launcher\log\tinyget\k2f.lua, a different size and name);
    - it described a trace of the program's download as a milder "first stage" trace.
  Details: https://github.com/SpringZali/nikke-launcher-triage/issues/1

  We cannot test a checker against files from infected PCs, so we retired it instead of
  patching it.

  IF AN OLDER COPY TOLD YOU "NOT FOUND", DO NOT RELY ON THAT RESULT.
  Use the publisher's official scan, or the manual steps in README.md, section 3:
  https://github.com/SpringZali/nikke-launcher-triage#3-check-your-pc-by-hand-official-steps

  This file only prints the notice below. It reads nothing and changes nothing.
#>
Write-Host ''
Write-Host 'Check-NikkeLauncher.ps1 was retired on 2026-11-11. It checks nothing.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Why: a review by the author of the community write-up found cases where it could print'
Write-Host '"NOT FOUND" without having read debug.log, leave an early build of the malicious program'
Write-Host 'out of its count, or describe a trace of its download as a milder one.'
Write-Host ''
Write-Host 'If an older copy of this script told you "NOT FOUND", do not rely on that result.' -ForegroundColor Yellow
Write-Host 'Use the publisher''s official scan, or the manual steps in section 3 of the guide:'
Write-Host '  https://github.com/SpringZali/nikke-launcher-triage#3-check-your-pc-by-hand-official-steps' -ForegroundColor Cyan
Write-Host ''
