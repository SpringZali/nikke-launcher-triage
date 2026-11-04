# NIKKE PC launcher incident: a calm triage guide

> Community guide. **Not an official statement.** Not affiliated with SHIFT UP, Level Infinite or Tencent. Not professional incident-response advice.
> Last checked: **2026-11-04 09:15 GMT**. This is still developing, so look at the date.

This guide **builds on** [MotherSphere's technical report](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5). Almost every technical finding comes from that report and from the people who posted their logs in its comments. This guide does not replace it. It adds three things:

1. A decision path for the question everyone keeps asking: **"do I have to wipe Windows?"**
2. A self-check you can read before you run it, plus a manual version that needs no download.
3. A record of what was independently verified and what was not: [ANALYSIS.md](ANALYSIS.md).

## The short version

- **Something real happened.** SHIFT UP's own notice (official NIKKE Japan account, Nov 4) says the PC launcher's script files *may have been tampered with by a third party*, that a client fix went out at about 02:30 JST on Nov 4, and that the scope is still being checked. A separate notice about what players should do has been promised. I could not find it when this was written.
- **Being exposed is not the same as being infected.** According to the report the attack code was delivered on only some launches (one machine got it on 3 of about 19). Several people in the comments show loader traces and no sign the agent ever ran.
- **Check before you delete.** Uninstalling or reinstalling NIKKE deletes `debug.log` and the agent's saved state. That is your evidence. If you wipe first, you can never find out.
- **If your log contains `k2f_chan registered`, treat it as a compromise.** It is not a harmless log line. Use the RED row below.
- **If you find nothing, the evidence so far does not justify wiping Windows.** Do the cheap precautions and wait for the official guidance.
- **No check can prove a PC is clean**, and nobody has solid numbers for how many players were hit. This guide claims neither "hoax" nor "you are safe".

## Who was exposed

Anyone who started the PC launcher between **Sep 27** (when four official script files were modified) and the fix on **Nov 3, about 17:04 to 17:21 GMT**, and anyone whose launcher kept using cached old files or a stale CDN server afterwards. The remote-control stage (the "agent") is first reported on **Oct 23**. The report covers the PC launcher on Windows and on Linux / Steam Deck (Proton). Mobile was not analysed.

## Self-check (5 minutes, nothing to download)

Do this **before** you uninstall, delete or reinstall anything. Close the launcher first: the agent only works while it is open.

1. Open `NIKKE\Launcher\intl_service\debug.log` in Notepad and search for `k2f_chan`.
   - Found: **RED**.
   - Not found: look at the first date in the file. The log has no year, and lines look like `[1031/211231.145:...]`, which is Oct 31. If it starts after your first launch in the window, it does not cover everything. If the file does not exist, see **GREY**.
2. In `regedit`, look for `HKEY_CURRENT_USER\Software\Classes\CLSID\{E77CC89B-7401-4C04-8CED-149DB35ADD04}`. If it exists, even with an empty value: **RED**. (The same CLSID under `HKEY_LOCAL_MACHINE` is normal Windows. Ignore that one.)
3. In File Explorer open `%LOCALAPPDATA%\Google\Chrome\User Data\PlatformExperienceHelper\`. A subfolder named with 64 hex characters that contains `platform_experience_helper.dll`: **RED**. (The folder itself is normal Chrome. The report says the DLL can be installed even without Chrome.)
4. Search the files in `%APPDATA%\nikke_launcher\tbs_cache\Local Storage\leveldb\` for the text `k2f.agent`. Found: **RED**.
5. If you run Pi-hole, NextDNS or look at router logs: a lookup of `insightjs.com` means the loader ran (**YELLOW**). A lookup of `analytics.insightjs.com` suggests the agent stage was reached. A DNS log can miss lookups, so a clean log is not proof.

Prefer a script? [`Check-NikkeLauncher.ps1`](Check-NikkeLauncher.ps1) does steps 1 to 4 and a few extras. It is plain PowerShell, offline and read-only, and short enough to read in five minutes. Read it first. Do not run scripts you have not read, including this one.

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\Check-NikkeLauncher.ps1
```

## Triage: what to do with the result

| Result | What it means | What to do |
|---|---|---|
| **RED**: `k2f_chan` in the log, `k2f.agent` in storage, or the registry key / DLL folder exists | The agent ran. The operator could run any command and read your files. The logs cannot show which. | 1. Close the launcher or disconnect from the internet. 2. **From a different device**, change passwords (NIKKE / Level Infinite, email, Discord, Steam, banking, everything saved in your browsers), sign out of all sessions and turn on 2FA. 3. Revoke API tokens and SSH keys. Move crypto funds to a new wallet. 4. Remove the persistence: delete the HKCU key, restart Windows, then delete the 64-hex folder. 5. **Reinstalling Windows is the only way to be certain**, because nothing logs what an attacker ran. Whether you do it depends on what the PC holds (wallets, keys, work access). Keep other drives, but check programs and scripts changed since Oct 23 before running them. |
| **YELLOW**: loader traces (`insightjs` in cache, DNS or the launcher's download logs) but no sign of the agent | The first stage ran. Nothing shows the agent did. | Delete `%APPDATA%\nikke_launcher\tbs_cache`, do the precautions below, keep watching your accounts. A wipe is not warranted by this alone. |
| **GREY**: no log and no launcher data left (uninstalled or reinstalled), but you launched in the window | You cannot tell. | Treat it as "possibly exposed": do the precautions below. Absence of evidence alone does not justify a wipe, but reconsider if the PC holds high-value secrets. Evidence that survives an uninstall: Windows' SRUM network records (see below). |
| **GREEN**: log present, covers your launches, no hits anywhere | No sign the agent ran. | Delete `tbs_cache` before the next launch and wait for the official all-clear. |
| You never started the PC launcher between Sep 27 and Nov 3 | Not exposed. | Nothing to do. |

**SRUM** (`C:\Windows\System32\sru\SRUDB.dat`) keeps hours of data sent per program, usually about a month back, and it survives uninstalling. Open it as administrator with NirSoft NetworkUsageView or SrumECmd and look at `tbs_browser.exe` in the hours you launched. People in the report's comments show anything from about 0.4 MB to over 100 MB sent in the hour an agent started, and one agent start shows only 12 KB, so an ordinary hour **lowers** your concern but does not clear you.

## Cheap precautions (10 minutes, for anyone who launched in the window)

- From another device, change your NIKKE / Level Infinite password and use "sign out of all sessions".
- Do the same for email, Discord, Steam and Google / Microsoft. Look at their "recent activity" pages for logins you do not recognise. Make sure 2FA is on.
- If you saved passwords in a browser on that PC, change the important ones (email, banking, crypto).
- Delete `%APPDATA%\nikke_launcher\tbs_cache` before the launcher is opened again, and do not open it until Level Infinite confirms the fix. They have not said "all clear" yet.
- Optional, as the report suggests: block `insightjs.com`, `analytics.insightjs.com`, `insightjs.org`, `89.127.233.127` and `89.126.250.172` in your router or firewall.

## What not to do

- Do not uninstall or wipe **before** checking. It destroys the evidence.
- Do not run "removal tools" or scripts from strangers. Fake "NIKKE fix" repositories are an obvious next scam. This repo has no binaries, only text you can read.
- Do not tell people it is a hoax, and do not tell them "you are safe". Neither is established. Do not tell them everything is destroyed either.

## Is the official CDN clean now?

Between 09:00 and 09:15 GMT on 2026-11-04 all four files served by the official CDN were byte-identical to the known-clean versions, from the default servers and from the two servers that had still served the modified file hours after the fix. [`Check-OfficialCdn.ps1`](Check-OfficialCdn.ps1) repeats that check from your location (four requests to the official hosts, nothing saved). It is a snapshot, not a guarantee for every server. Details: [ANALYSIS.md](ANALYSIS.md).

## FAQ

- **"I already uninstalled. Am I safe?"** You cannot tell from logs, because the uninstaller erased them. Check the persistence items (steps 2 and 3), do the cheap precautions, and consider the SRUM check.
- **"Is changing my passwords enough?"** If the agent ran: it protects your accounts, but not the PC, because the operator could have started other programs. Only a reinstall gives certainty.
- **"Is it a hoax?"** No. The publisher confirms the tampering concern, and the registry, certificate and CDN details in the report match independent checks. The details of the payload rest on one researcher plus community reports, and have not been confirmed by SHIFT UP or a security vendor.
- **"Why not just say wipe everything?"** Because for people with no sign of the agent, the evidence does not support it, and wiping first erases the evidence. For confirmed cases the report's author, and this guide, say a reinstall is the only certain fix.

## Still unknown

- How the attacker got write access to the CDN, and whether other files were modified.
- How many players actually received the agent.
- What SHIFT UP / Level Infinite will recommend (a separate notice is promised).
- Whether every CDN server worldwide is clean.

## Sources and credit

- [SHIFT UP notice, official NIKKE Japan account](https://x.com/NIKKE_japan/status/2117817740555956289) (Nov 4, JST)
- [MotherSphere's report](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5) and the players who shared their logs in its comments
- [Inven Global](https://www.invenglobal.com/articles/28112/goddess-of-victory-nikke-pc-launcher-allegedly-compromised) and Japanese coverage ([Inside Games](https://www.inside-games.jp/article/2026/11/04/190338.html), [Mynavi](https://news.mynavi.jp/article/20261104-5254830/), [Automaton](https://automaton-media.com/articles/newsjp/20261104-477333/))

Maintained by @SpringZ_FSG. Corrections are welcome: open an issue and include a source. Prepared with AI assistance (Claude); nothing here depends on trusting that, because [ANALYSIS.md](ANALYSIS.md) says how to reproduce every check.
