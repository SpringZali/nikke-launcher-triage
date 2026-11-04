# NIKKE PC launcher incident: what to do, and what not to do

> [!IMPORTANT]
> **Don't panic. Don't wipe, uninstall or reinstall anything yet.** Close the NIKKE launcher and leave it closed until you have read the official guidance below (Level Infinite now says the current version is safe). Then spend five minutes checking your PC ([section 3](#3-check-your-pc-5-minutes)) **before** you decide anything. What you need to do depends on what the check finds. For people whose check finds nothing, it is very little.

> [!NOTE]
> Community guide. **Not an official statement.** Not affiliated with SHIFT UP, Level Infinite or Tencent, and not professional incident-response advice. It builds on [MotherSphere's technical report](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5), the source for almost every technical detail here. Prepared with AI assistance. Every check is reproducible: see [ANALYSIS.md](ANALYSIS.md).

> [!IMPORTANT]
> **Official guidance is out (Nov 4, 23:00 to 23:07 GMT).** Level Infinite confirms that a third party tampered with launcher files, says the current launcher version is safe, and says that from Nov 5, 08:00 JST (Nov 4, 23:00 GMT) the official PC client scans for the malware and offers to remove it. The publisher's manual check guide is out too (23:10 GMT). Details: [section 2](#official-guidance-nov-4-2300-gmt). The official scan removes the malware's logs, DLLs and registry data, so if you want to keep your evidence, **copy `debug.log` first** (our suggestion, not an official step).

**Last updated: 2026-11-04, 23:32 GMT**. Things are still changing, so look at the date. Changes are listed in the [changelog](#changelog).

| Status board | Now | Checked (GMT) |
|---|---|---|
| Official CDN files | All four byte-identical to the known-clean versions, on every server tested | Nov 4, 23:07 |
| Publisher statements | Nov 4, 23:00 to 23:07: Level Infinite apologises and posts a follow-up measures notice. It confirms that a third party tampered with launcher files, says PCs and account data may have been exposed and the scope is still being investigated, calls the current launcher version safe, and announces compensation. At 23:10 it also published a manual check guide, and at 23:11 to 23:13 Kim Hyung-tae said the launcher was updated with a scanning tool that runs at launch. Earlier: first notice 03:14, Kim Hyung-tae 08:07 | Nov 4, 23:20 |
| Official removal tool | From Nov 5, 08:00 JST (Nov 4, 23:00 GMT) the official PC client scans for the malware and offers to remove it. Announced, not tested here | Nov 4, 23:10 |
| Technical report | Newest revision Nov 4, 22:20 (19 revisions, the last only fixes translation links). 177 comments. It links its author's scanner at the top, which this guide has not reviewed, and is translated into 15 languages, including Russian | Nov 4, 23:07 |
| Stolen data being misused | No such report found in the report's comments (absence of reports, not proof). The publisher says only that PCs and accounts may have been exposed | Nov 4, 23:07 |
| Attacker's server | Reported offline since Nov 3, 18:31 (not verified here). Its host says the server is shut down, but the domain's DNS still points to it and is not suspended yet. Abuse reports to the host and the registrar are filed (ANALYSIS row 31) | Nov 4, 23:07 |

## Contents

1. [Start here](#1-start-here)
2. [What everyone can do right now](#2-what-everyone-can-do-right-now)
3. [Check your PC (5 minutes)](#3-check-your-pc-5-minutes)
4. [What to do with the result](#4-what-to-do-with-the-result)
5. [Myths and facts](#5-myths-and-facts)
6. [What is known, and how well](#6-what-is-known-and-how-well)
7. [Timeline (GMT)](#7-timeline-gmt)
8. [Do not get scammed](#8-do-not-get-scammed)
9. [What players still need from SHIFT UP and Level Infinite](#9-what-players-still-need-from-shift-up-and-level-infinite)
10. [Changelog](#changelog)
11. [Sources and credit](#sources-and-credit)

## 1. Start here

```mermaid
flowchart TD
    A["Did you start the PC launcher between Sep 27 and Nov 4, 03:20 GMT?"] -->|"No, or mobile only"| Z["Not exposed. Nothing to do."]
    A -->|"Yes"| B["Close the launcher. Do not open it. Do not uninstall yet."]
    B --> C["Run the 5-minute check (section 3)"]
    C --> D{"What did it find?"}
    D -->|"k2f_chan, agent state, or persistence"| R["RED: serious steps"]
    D -->|"Loader traces only"| Y["YELLOW: precautions"]
    D -->|"Logs gone, cannot tell"| G["GREY: precautions"]
    D -->|"Nothing found"| N["GREEN: wait for the all-clear"]
```

Why Sep 27? Four official launcher script files were modified that day, so the first stage (the "loader") was in place from then. The second stage, a remote-control program called the "agent", is first reported on Oct 23 by commenters in the report. The publisher says distribution to PCs began on Oct 29, 18:52 GMT (Oct 30, 03:52 JST). The report covers the PC launcher on Windows and on Linux / Steam Deck (Proton). Mobile was not analysed. Why Nov 4, 03:20 GMT? The report says some CDN servers kept serving the modified `FeedList` file until Nov 4 between 03:12 and 03:21 GMT. That covers the four servers it checked, and others were not checked. So a launch in the early hours of Nov 4 GMT, which is already the morning of Nov 4 in Japan and Korea, still counts.

**Being exposed is not the same as being infected.** According to the report, the attack code was delivered on only some launches (one machine got it on 3 of about 19). That is why the check matters.

## 2. What everyone can do right now

These work whatever the result is.

- **Close the launcher and leave it closed.** According to the report, the agent only receives commands while the launcher is open.
- **Check before you uninstall, reinstall or wipe.** Uninstalling deletes `debug.log`, and the launcher's own uninstaller can remove its saved data too. That is your evidence. If you already uninstalled, it is not a disaster: see GREY in section 4.
- **You do not need to switch your PC off or cut your internet.** Closing the launcher is what stops the known attack path. The one reported exception is a Chrome helper DLL, which section 3 checks for.
- **Do not run "fix" tools from anyone**, including strangers on social media (section 8).
- **If you launched in the window, do the 10-minute precautions** in section 4.

### Official guidance (Nov 4, 23:00 GMT)

From Level Infinite's follow-up notice (read in the Korean original, the wording below is ours) and its English apology:

- **Who should check:** anyone who started the PC launcher at least once after Sep 27, 06:41 GMT (15:41 JST).
- **PC check:** from Nov 5, 08:00 JST (Nov 4, 23:00 GMT) the official PC client scans for the malware and removes it. Close Chrome and other browsers first, then start the client. If something is found, a popup asks whether to remove the malware's logs, DLLs and registry data, and agreeing deletes them. If a browser was still open, some DLL files may stay, but they no longer run. No popup means nothing was found. The publisher admits the popup is not polished yet.
- **Manual check, no launcher installed or you prefer to check by hand:** the publisher's manual guide is out (Nov 4, 23:10 to 23:11 GMT, [English post](https://x.com/NIKKE_en/status/2118118928631451774) with the steps on the official site). It says the incident was limited to the PC launcher, so players who only played on mobile need to do nothing. Its steps match section 3 here: disconnect from the network and close the game, the launcher and Chrome; search `Launcher\intl_service\debug.log` for `k2f_chan registered`; if it is found, delete the `HKEY_CURRENT_USER\Software\Classes\CLSID\{E77CC89B-7401-4C04-8CED-149DB35ADD04}` key and restart Windows, delete the 64-hex folder with `platform_experience_helper.dll` under `PlatformExperienceHelper`, delete a `tinyget.<date>-<time>.log` file of exactly 205,135 bytes in `Launcher\log\tinyget`, and delete `%APPDATA%\nikke_launcher\tbs_cache`. It adds an antivirus update with a full scan and a Windows Security Offline Scan, and says that not finding the string does not completely rule out risk. For Google Play Games installs it gives the example path `C:\NIKKE_GOOGLE\Launcher\intl_service\debug.log`.
- **Account protection** (from another device, or after the PC check): change the passwords of accounts you used on that PC, and revoke and reissue any API keys and access tokens you used or stored on it.
- **Losses outside the game** (accounts, money): contact the official in-game Customer Support, which promises to review each case.
- **The launcher:** the apology says the currently distributed version is safe to use. Our own checks agree that the official files are clean (section 6).
- **Our note:** the official scan deletes what it finds. If you want a record of the evidence first, copy `Launcher\intl_service\debug.log` before you run it. That is our suggestion, not an official step.

Sources: [English apology](https://x.com/NIKKE_en/status/2118116340225732677), [Korean follow-up measures notice](https://x.com/NIKKE_kr/status/2118117786568560774) (links to the official page on nikke-kr.com).

## 3. Check your PC (5 minutes)

Do this **before** you uninstall, delete or reinstall anything, and with the launcher closed.

<details>
<summary><b>Manual check, nothing to download</b></summary>

1. Open `NIKKE\Launcher\intl_service\debug.log` in Notepad and search for `k2f_chan`.
   - Found: **RED**. Not found proves little: LevelDB can move old records into compressed files that a text search cannot read.
   - Not found: look at the first date in the file. The log has no year, and lines look like `[1031/211231.145:...]`, which is Oct 31. If it starts after your first launch in the window, it does not cover everything. If the file does not exist, see **GREY**.
2. In `regedit`, look for `HKEY_CURRENT_USER\Software\Classes\CLSID\{E77CC89B-7401-4C04-8CED-149DB35ADD04}`. If it exists, even with an empty value: **RED**. The same CLSID under `HKEY_LOCAL_MACHINE` is normal Windows. Ignore that one. The report's author says the agent's own uninstall clears only the key's value and leaves the key, so no key means the Chrome DLL was never installed, unless someone deleted the key by hand.
3. In File Explorer open `%LOCALAPPDATA%\Google\Chrome\User Data\PlatformExperienceHelper\`. A subfolder named with 64 hex characters that contains `platform_experience_helper.dll`: **RED**. The folder itself is normal Chrome. The report says the DLL can be installed even without Chrome. Its author adds that it only ever goes into this Chrome folder, never into Edge or Brave folders.
4. Search the files in `%APPDATA%\nikke_launcher\tbs_cache\Local Storage\leveldb\` for the text `k2f.agent`. Found: **RED**. Not found proves little: LevelDB can move old records into compressed files that a text search cannot read.
5. If you run Pi-hole, NextDNS or look at router logs: a lookup of `insightjs.com` means the loader ran (**YELLOW**). A lookup of `analytics.insightjs.com` suggests the agent stage was reached. A DNS log can miss lookups, so a clean DNS log is not proof.
6. Did the launcher itself show a security warning? That is the loader's fallback page, not proof of infection (see the myths in section 5). It counts as **YELLOW**: the modified script loaded. It says nothing about whether the agent ran, and not seeing it proves nothing either.
7. Do you play through Google Play Games on PC? The publisher's manual guide gives `C:\NIKKE_GOOGLE\Launcher\intl_service\debug.log` as an example path, and one user reports finding `k2f_chan` there. Its launcher data folder is named `nikke_launcher_google`. Run steps 1 to 4 on that install, with its own folder names.

</details>

**Prefer a script?** [`Check-NikkeLauncher.ps1`](Check-NikkeLauncher.ps1) does steps 1 to 4 plus a few extras. It is plain PowerShell, offline and read-only, and short enough to read in five minutes. Read it first. Do not run scripts you have not read, including this one. The report now also links its author's scanner, [NIKKE Launcher Check](https://github.com/MotherSphere/NIKKE-Launcher-Check), with a download. This guide has not reviewed its current release (v0.5.1 at 16:03 GMT), and the only review published here covers v0.4.0 ([community/](community/README.md)). The manual check above needs no download.

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\Check-NikkeLauncher.ps1
```

> [!NOTE]
> **A clean log is evidence, not proof.** The agent can run any command your Windows user can run, which in principle includes editing or deleting files. The report documents cleanup commands that delete the agent's *own* download logs and payload files, and says that missing files prove nothing. No report of `debug.log` itself being edited was found in the report's comments (keyword scan, see [ANALYSIS.md](ANALYSIS.md)), but you cannot rule it out from the log alone. That is why the check looks in several places.

## 4. What to do with the result

| Result | What it means | What to do |
|---|---|---|
| **RED**: `k2f_chan` in the log, `k2f.agent` in storage, or the registry key / DLL folder exists | The agent ran. The operator could run any command and read your files. The logs cannot show which. | Follow [RED in detail](#red-in-detail) below. |
| **YELLOW**: loader traces (`insightjs` in cache, DNS or the launcher's download logs, or a security warning shown inside the launcher) but no sign of the agent | The first stage ran. Nothing shows the agent did. | Delete `%APPDATA%\nikke_launcher\tbs_cache`, do the [precautions](#precautions-10-minutes), keep watching your accounts. A wipe is not warranted by this alone. |
| **GREY**: no log and no launcher data left (uninstalled or reinstalled), but you launched in the window | You cannot tell. | Treat it as "possibly exposed": do the [precautions](#precautions-10-minutes). Absence of evidence alone does not justify a wipe, but reconsider if the PC holds high-value secrets. Evidence that survives an uninstall: Windows' SRUM network records (below). |
| **GREEN**: log present, covers your launches, no hits anywhere | No sign the agent ran. | Delete `tbs_cache` before the next launch. The publisher now calls the current launcher version safe (section 2). |
| You never started the PC launcher between Sep 27 and Nov 4, 03:20 GMT | Not exposed. | Nothing to do. |

### RED in detail

1. Close the launcher, or disconnect from the internet, so the operator loses access.
2. **From a different device**, change passwords: NIKKE / Level Infinite first, then email, Discord, Steam, banking and everything saved in your browsers. Turn on 2FA.
3. Sign out of **all sessions** everywhere. Stolen browser cookies work without your password.
4. Revoke and regenerate API tokens and SSH keys. Move crypto funds to a new wallet with a new seed phrase.
5. Remove the persistence: delete the HKCU registry key, restart Windows, then delete the 64-hex folder. Do not delete the whole `PlatformExperienceHelper` folder, which is normal Chrome.
6. **Reinstalling Windows is the only way to be certain**, because nothing logs what an operator ran. Whether you do it depends on what the PC holds (wallets, keys, work access). Keep your other drives, but check programs and scripts changed since Oct 23 before running them. A System Restore point is not a clean state. A clean install and Reset this PC with "Remove everything" both count. "Keep my files" does not, because it keeps your user folders, where the Chrome DLL lives. Do not restore a full backup of that PC made after Sep 27. This is the advice of the report's author in its comments, not an official source.

### Precautions (10 minutes)

For anyone who launched in the window and is not sure.

- From another device, change your NIKKE / Level Infinite password and use "sign out of all sessions".
- Do the same for email, Discord, Steam and Google / Microsoft. Look at their "recent activity" pages for logins you do not recognise. Make sure 2FA is on.
- If you saved passwords in a browser on that PC, change the important ones (email, banking, crypto).
- Delete `%APPDATA%\nikke_launcher\tbs_cache` before the launcher is opened again. Level Infinite now says the current launcher version is safe and offers its own scan (section 2).
- Blocking the attacker's domains or IPs (the report lists them) is optional and of limited value. It only stops the current server, and the attacker could switch to a new one. Do not rely on it: closing the launcher and the steps above matter more.

<details>
<summary><b>If you already uninstalled: SRUM can still tell you something</b></summary>

SRUM (`C:\Windows\System32\sru\SRUDB.dat`) keeps hours of data sent per program, usually about a month back, and it survives uninstalling. Open it as administrator with NirSoft NetworkUsageView or SrumECmd and look at `tbs_browser.exe` in the hours you launched.

People in the report's comments show anything from about 0.4 MB to over 100 MB sent in the hour an agent started, and one agent start shows only 12 KB. So an ordinary hour **lowers** your concern but does not clear you.

</details>

## 5. Myths and facts

| You may hear | What the evidence says |
|---|---|
| "It's a hoax." | SHIFT UP's own notice reports an anomaly consistent with tampering, and the registry, certificate and CDN details in the report match independent checks. The details of the payload rest on one researcher plus community reports. |
| "It's just one person's PC, a minor local issue." | No. Many independent players report the same traces, the publisher replaced the official files at the times the report gave, and files on two different CDN host names (`na-webassets` and `sg-gpts`) were involved. |
| "Everything on every PC was stolen." | Only if the agent ran, and the report says the attack code was served on only some launches, and several players in its comments found no sign of the agent. Exposure is not infection. |
| "The attacker had no time, nothing was stolen." | Nobody can say that for a specific PC. The report says a first collection starts within seconds of the agent starting (reported). On the other side, no misuse of stolen data has been reported in the report's comments so far. Both are true: it is unknown, and there is no sign of misuse yet. |
| "A clean log means I'm safe." | It is good evidence, not proof (see the note in section 3). |
| "The launcher showed a security warning, so I'm infected." | Not by itself. The warning comes from a page on `insightjs.org`, registered on Nov 3 after the incident became public. By the report's description, the modified script falls back to that address when it cannot reach the attacker's server, for example because the address was blocked or the server went offline. So the warning means the modified script loaded (YELLOW), not that the agent ran. Seeing no warning proves nothing either. The log decides. |
| "I have to wipe Windows." | Only the RED result calls for it, and even then it is the way to be *certain*. For YELLOW, GREY and GREEN the evidence so far does not justify it. |
| "I have to switch off my PC and cut the internet." | No. Close the launcher. If you find RED, disconnect while you sort out your passwords from another device. |
| "Uninstalling the launcher fixes it." | It stops new exposure but undoes nothing, and it erases your evidence. |
| "Blocking the attacker's IP or domain protects me." | It only stops one server. The report notes the attacker could try again with a new domain, because how they got write access to the CDN is still unknown. It does not replace closing the launcher and checking your PC. |
| "Changing my NIKKE password is enough." | It is the first step, not the only one. Saved browser passwords, cookies and tokens can be targeted if the agent ran. |
| "Only Windows is affected." | The report also covers Linux and Steam Deck (Proton), where an agent start is reported. |

### Short answers you can copy

Short replies for people asking in threads and chats. Each one fits in a post.

- **"Do I need to wipe Windows?"** Not automatically. Close the launcher, don't uninstall yet, and check `debug.log` for `k2f_chan` first. A hit means the agent ran, and then a reinstall is the only way to be certain. https://github.com/SpringZali/nikke-launcher-triage
- **"I already uninstalled it. Am I fine?"** You can't tell from logs, because uninstalling deletes them. Do the 10-minute precautions (change passwords from another device, sign out of all sessions) and don't panic-wipe. https://github.com/SpringZali/nikke-launcher-triage
- **"Is it a hoax?"** No. SHIFT UP's own notice reports an anomaly consistent with tampering, and the domain, certificate and CDN details check out. What is not confirmed yet is how many players got the second stage. https://github.com/SpringZali/nikke-launcher-triage
- **"I saw a security warning in the launcher. Am I hacked?"** Not necessarily. The warning means the modified script loaded, not that the remote-control program ran. Check ``debug.log`` for ``k2f_chan`` before you uninstall anything. https://github.com/SpringZali/nikke-launcher-triage
- **"Is the launcher safe to open now?"** Level Infinite now says the current launcher version is safe, and our checks agree that the official files are clean. Delete `tbs_cache` first, and use the official client's new scan (from Nov 4, 23:00 GMT). https://github.com/SpringZali/nikke-launcher-triage
## 6. What is known, and how well

**VERIFIED** = reproduced from a public source. **CORROBORATED** = several independent reports agree. **REPORTED** = one source. Full table with 36 claims and how to reproduce each: [ANALYSIS.md](ANALYSIS.md).

| Fact | How well established | Source |
|---|---|---|
| The publisher reports an anomaly consistent with tampering and applied a client fix | **VERIFIED** | [Official notice, Nov 4](https://x.com/NIKKE_japan/status/2117817740555956289) |
| The official files were replaced on Nov 3 between 17:04 and 17:21 GMT | **VERIFIED** | Current `Last-Modified` headers on the CDN |
| The files served now are the clean versions | **VERIFIED** | [`Check-OfficialCdn.ps1`](Check-OfficialCdn.ps1) |
| `insightjs.com` was registered Sep 27 and `insightjs.org` Nov 3 | **VERIFIED** | Domain registry records |
| Certificates were issued for the attacker's domain on Sep 27, Oct 6, Oct 23 and Oct 24 | **VERIFIED** | Certificate transparency log |
| A remote-control agent was delivered to some launches (`k2f_chan` in the log) | **CORROBORATED** | MotherSphere's report and many independent comments |
| What the agent can do: run commands, read files, take screenshots, collect saved credentials | **REPORTED** | Static analysis by one researcher |
| Chrome-helper persistence | **REPORTED**, not universal | Several victims. Others with the agent have none |
| Stolen data is being misused | **NO REPORTS FOUND** | Keyword scan of 149 comments |
| One detailed community case study (the agent ran on three days) also found no proof of theft or misuse | **REPORTED** | [Community report](community/INCIDENT_FORENSIC_REPORT_PUBLIC.md) |
| A third party tampered with launcher files, and PCs and accounts may have been exposed | **VERIFIED** (read at the source) | Level Infinite's [apology](https://x.com/NIKKE_en/status/2118116340225732677) and [follow-up notice](https://x.com/NIKKE_kr/status/2118117786568560774), Nov 4 |
| Publisher's timeline: `insightjs.com` taken over Sep 27, malware distributed to PCs from Oct 29, 18:52 GMT | **REPORTED** by the publisher | The notice. The dates fit our registry and file checks. The report's earliest agent start (Oct 23) is earlier |
| The official PC client scans for and removes the malware from Nov 4, 23:00 GMT | **REPORTED** by the publisher | The notice. Not tested here, on purpose |
| The publisher's manual check guide matches this guide's manual check | **VERIFIED** (read at the source) | The [English post](https://x.com/NIKKE_en/status/2118118928631451774) and the official page it links. Same log string, registry key, DLL folder and `tbs_cache`, plus a 205,135-byte `tinyget` log and an antivirus scan |
| How the attacker got write access to the CDN | **UNKNOWN** | Not yet explained |

## 7. Timeline (GMT)

| When | What | Status |
|---|---|---|
| Sep 27, 01:59 | `insightjs.com` registered | verified |
| Sep 27, 06:41 to 06:42 | Four official launcher script files modified (15:41 to 15:42 JST) | official |
| Oct 6, 00:55 | Certificate for `analytics.insightjs.com` | verified |
| Oct 23, 15:37 | New certificate for the apex, `analytics.`, `portal.` and `www.` | verified |
| Oct 23, 16:40 | Earliest agent start reported | reported |
| Oct 28, 15:46 | One file (`FeedList`) cleaned at the origin. Some CDN servers keep the old copy | reported |
| Oct 29, 18:52 | Publisher: distribution of the malware to PCs begins (Oct 30, 03:52 JST) | official, the report's earliest agent start is Oct 23 |
| Nov 3, 16:11 | First public warning (community Discord) | reported |
| Nov 3, 17:04 / 17:13 / 17:21 | Three files replaced with clean versions | verified |
| Nov 3, about 17:30 | Publisher's client fix (02:30 JST on Nov 4), per its notice | official |
| Nov 3, 18:31 | Attacker's server stops answering | reported |
| Nov 3, 20:19 | `FeedList` re-published | verified |
| Nov 3, up to 22:26 | Two CDN servers still serve the modified `FeedList` | reported, matches [Inven Global](https://www.invenglobal.com/articles/28112/goddess-of-victory-nikke-pc-launcher-allegedly-compromised) |
| Nov 4, 00:48 | One CDN server (`43.175.139.78`, `na-webassets`) still serves the modified `FeedList`, seen in a public urlscan.io scan | reported |
| Nov 4, 03:09 | Publisher: the last modified file replaced and the CDN cache refreshed (12:09 JST) | official |
| Nov 4, 03:12 to 03:21 | The four servers the report checked take the clean `FeedList`, most likely a purge | reported |
| Nov 4, 03:14 | Publisher's first public statement | verified |
| Nov 4, 08:07 | SHIFT UP's Kim Hyung-tae apologises: working with Level Infinite on a fundamental solution, preparing follow-up measures | verified |
| Nov 4, 09:56 | All four files clean on every server tested | verified |
| Nov 4, 23:00 to 23:07 | Level Infinite posts an apology and a follow-up measures notice with guidance for players | official |
| Nov 4, 23:00 | The official PC client starts scanning for and removing the malware (Nov 5, 08:00 JST) | official, announced |
| Nov 4, 23:10 to 23:11 | Level Infinite posts the manual security check guide (English, Korean, Japanese) | official |
| Nov 4, 23:11 to 23:13 | SHIFT UP's Kim Hyung-tae: the PC launcher is updated and runs a security check at launch | official |

## 8. Do not get scammed

A "NIKKE virus remover", a "launcher fixer", an `.exe` or `.zip` "cleanup tool", a Discord DM, or a "paste this into PowerShell" one-liner is a likely next wave. A few rules:

- **Never run executables or installers** offered as a fix.
- **Read every script** before you run it. This repository contains only plain text files.
- **Take guidance only from official accounts** and from sources that show how to check them.
- **Never type a password into a "checker".** Nothing here needs one.
- A GitHub link proves nothing by itself. Anyone can publish one in thirty seconds, and that includes this one. What counts is that you can reproduce the claims: [ANALYSIS.md](ANALYSIS.md) shows how.

## 9. What players still need from SHIFT UP and Level Infinite

Level Infinite's apology and follow-up notice (Nov 4, 23:00 to 23:11 GMT) answer several earlier points: the current launcher version is called safe, there is an official scan and a manual check guide, and there is advice on passwords, API keys and tokens. Still open:

1. **Scope:** the notice says the scope of damage is still being investigated. Which launches, regions and dates were affected is not stated, and neither is whether player credentials were actually taken.
2. **How the CDN was accessed**, and confirmation that other files and buckets were checked. The notice says the network security environment, including the CDN, is being reviewed.
3. **What the official scan does and does not remove.** The notice names logs, DLL files and registry data. It does not say how it treats the agent's saved state in the launcher's storage.
4. **A forced cache reset** in the launcher update is not mentioned, but the manual guide tells you to delete `tbs_cache` yourself.
5. **A way to tell** whether an account's sessions were used abnormally.
## Changelog

- **2026-11-04, 23:32, v2.9.** Correction of v2.8: the publisher's manual check guide was already out (Nov 4, 23:10 to 23:11 GMT) and v2.8 wrongly said it was still promised. Added its steps in section 2 (they match section 3), confirmed the Google Play Games path in step 7, added a timeline row, a row in section 6 and the sources, and removed it from the open points in section 9.
- **2026-11-04, 23:13, v2.8.** Level Infinite published an apology and a follow-up notice with guidance. Added an "Official guidance" subsection in section 2 and a note at the top, updated the status board, the GREEN row, precaution 4, the "Is the launcher safe to open now?" answer, the table in section 6, the timeline and section 9, and added the publisher's timeline. Notes: the official scan deletes what it finds, so copy `debug.log` first if you want a record (our suggestion). Read from the Korean original, translations are ours.

- **2026-11-04, 22:41, v2.7.** Added a note for people who play through Google Play Games on PC (manual check step 7 and ANALYSIS row 32, both reported, not verified here). Also added the infrastructure facts of ANALYSIS row 31. The status board was not refreshed in this update.
- **2026-11-04, 16:10, v2.6.** The report's newest revision now recommends its author's scanner at the top. Added a note that this guide has not reviewed its current release, what the author says about the registry key and the DLL folder, a link to the report's Russian translation, and refreshed the status board and the counts.
- **2026-11-04, 12:50, v2.5.** The exposure window now ends on Nov 4 at 03:20 GMT instead of Nov 3: the report's newest revision says some CDN servers served the modified `FeedList` until then. Added the reset advice of the report's author (a reset with "Remove everything" counts, "Keep my files" does not), two timeline rows, and refreshed the status board and the counts. Removed the "SENDING" section from the community notes file, because it does not apply to a public repository.
- **2026-11-04, 11:42, v2.4.** Added the [community reports](community/README.md) (published unchanged) with a credit, a row in the table of what is known, and a caveat on the LevelDB search in step 4.
- **2026-11-04, 11:13, v2.3.** Added SHIFT UP's second statement (Kim Hyung-tae, 08:07 GMT) to the status board, timeline and sources.
- **2026-11-04, 11:00, v2.2.** Added the security-warning nuance: a YELLOW example, manual check step 6, a myth row and a short answer.
- **2026-11-04, 10:28, v2.1.** Added short copy-paste answers and a credit for community review.
- **2026-11-04, 10:11, v2.** Restyled. Added the status board, decision flow, myths and facts, timeline, scam warning and the list of what players still need. Added "a clean log is evidence, not proof" and "no misuse reports found" (keyword scan). Clarified that uninstalling deletes `debug.log` and can remove the saved data too. Clarified that blocking the attacker's IPs is of limited value.
- **2026-11-04, 09:35, v1.** Guide, analysis and two read-only checkers.

## Sources and credit

- [MotherSphere's report](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5) and the players who shared their logs and network records in its comments. This guide would not exist without them. The report is also available in 15 languages, including [Russian](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5#file-nikke-pc-launcher-compromise_ru-md). We have not checked the translations.
- Official notices, Nov 4: [NIKKE English account](https://x.com/NIKKE_en/status/2117817602659770434) (03:13 GMT) and [NIKKE Japan account](https://x.com/NIKKE_japan/status/2117817740555956289) (03:14 GMT)
- Level Infinite's apology and follow-up measures notice, Nov 4: [English apology](https://x.com/NIKKE_en/status/2118116340225732677) (23:01 GMT), [Korean follow-up measures notice](https://x.com/NIKKE_kr/status/2118117786568560774) (23:06 GMT), which links to the official page on nikke-kr.com
- Level Infinite's manual security check guide, Nov 4: [English post](https://x.com/NIKKE_en/status/2118118928631451774) (23:11 GMT, steps on nikke-en.com) and the [Korean post](https://x.com/NIKKE_kr/status/2118118725518086221) (23:10 GMT). SHIFT UP's Kim Hyung-tae on the launcher update: [post](https://x.com/jamm3rd/status/2118119533282279671) (23:13 GMT)
- [Kim Hyung-tae of SHIFT UP, statement of Nov 4](https://x.com/jamm3rd/status/2117891546322252242) (08:07 GMT)
- [Inven Global](https://www.invenglobal.com/articles/28112/goddess-of-victory-nikke-pc-launcher-allegedly-compromised) and Japanese coverage: [Inside Games](https://www.inside-games.jp/article/2026/11/04/190338.html), [Mynavi](https://news.mynavi.jp/article/20261104-5254830/), [Automaton](https://automaton-media.com/articles/newsjp/20261104-477333/)
- **Review, feedback and community reports:** [Necromancer](https://github.com/necromancer124), a community member who is learning IT, reviewed the draft, suggested the log-tampering caveat and contributed two reports, published unchanged in [community/](community/README.md) (not verified here).

Maintained by @SpringZ_FSG. Corrections are welcome: open an issue and include a source.
