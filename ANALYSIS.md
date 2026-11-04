# Analysis: what the report says, and how far it checks out

Checked on **2026-11-04 between about 09:00 and 09:15 GMT** against [MotherSphere's report](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5) (12 revisions, 126 comments by 61 people, last comment 08:00 GMT).

## Method and limits

- Read the report, all 12 revisions and the comments.
- Re-checked what can be re-checked from public sources: domain registries, certificate logs, public DNS, and the official CDN.
- **Did not** contact the attacker's servers, fetch the payload, or run anything from the report. Claims that need that are marked NOT VERIFIED on purpose.
- Did not examine victims' raw data. Comment-based claims are only as good as the comments.

Labels: **VERIFIED** = I reproduced it from a public source. **CORROBORATED** = several independent reports agree, not reproduced by me. **REPORTED** = one source. **NOT VERIFIED** = could not or chose not to check. **OUTDATED** = was right when written, no longer is. **DERIVED** = computed from other rows.

## About the author and the report

- GitHub account created 2025-10-02, 70 public repositories, 21 followers, 2 public gists. Not a throwaway account.
- 12 public revisions with visible corrections (for example the withdrawn `onominan.tmp` marker and the `creds` correction). The "Reinstalling Windows is the safest option" line is identical in all 12 revisions, and sits under "If you are infected".
- Several commenters say they used AI assistants to analyse their own machines. That does not change whether a claim is true. Hashes, timestamps and log lines can be checked either way.

## Claim by claim

| # | Claim in the report | Status | Evidence |
|---|---|---|---|
| 1 | The publisher acknowledges a problem | **VERIFIED** | Official notice (NIKKE Japan account, Nov 4 JST): script files "may have been tampered with by a third party", client fix around 02:30, scope under investigation, guidance to follow separately. Reported by Automaton (I read it in full) and, from headlines and excerpts, Inside Games, Mynavi and Dengeki Online. It does **not** mention malware, a remote-access tool, victims or passwords. |
| 2 | `insightjs.com` was registered 2026-09-27 01:59 GMT, name servers at 1984 | **VERIFIED** | RDAP (Verisign): registration 2026-09-27T01:59:19Z, last changed 2026-10-12T12:00:03Z, name servers NS0/NS1.1984.IS and NS2.1984HOSTING.COM. Observation, not a conclusion: crt.sh also lists certificates for `cdn.` and `api.insightjs.com` from 2019 to 2021, so the name existed before this registration. |
| 3 | `insightjs.org` was registered 2026-11-03 17:55 GMT and is behind Cloudflare | **VERIFIED** | RDAP (PIR): registration 2026-11-03T17:55:42Z. Public DNS: 172.67.178.16 and 104.21.35.173 (Cloudflare ranges). |
| 4 | Four certificates: Sep 27 03:00:24, Oct 6 00:55:00, Oct 23 15:37:09, Oct 24 21:15:14 | **VERIFIED** | Cert Spotter API returns exactly these four 2026 issuances, names as listed. crt.sh showed only the Oct 6 one, so it has gaps. The report cites Cert Spotter, not crt.sh. |
| 5 | `insightjs.com` and `analytics.insightjs.com` resolve to 89.127.233.127 | **VERIFIED** (DNS only) | Cloudflare DNS-over-HTTPS, 2026-11-04 ~09:00 GMT. The record is unchanged, even though the server is reported shut down. Whether the server answers: **NOT VERIFIED** (not contacted). |
| 6 | Three files were replaced on Nov 3 at 17:04, 17:13 and 17:21 GMT | **VERIFIED** | Current `Last-Modified` headers: `aegis-fix.min.js` 17:04:28, `vue-bucket.min.js` 17:13:36, `images.7fec4c32.js` 17:21:31 (Nov 3 GMT). |
| 7 | The files now served are the clean ones listed in the report | **VERIFIED** | MD5 of each downloaded body equals its ETag, and equals the "clean" ETag in the report: `44c57645...` (aegis), `6e5f79cf...` (images), `04ee9800...` (FeedList), `63bc3a47...` (vue). No `insightjs` reference. Checked from the default servers (43.159.79.120 by curl, 43.168.117.35 and .131 by PowerShell) and from 43.152.43.115, 43.175.144.148 and 43.175.145.181. |
| 8 | Some CDN servers kept serving the modified `FeedList.feb647c9.js` for hours after the fix | **CORROBORATED**, no longer reproducible | The report (until 22:26 GMT) and Inven Global (7:26 KST, the same moment) agree. At 09:00 GMT on Nov 4 the two servers the report names (43.175.144.148 and 43.175.145.181) served the clean file. So the problem was real and appears to have been fixed at the servers I could test. |
| 9 | The report's table gives `FeedList.feb647c9.js` clean `Last-Modified` as Oct 28 15:46:09 | **OUTDATED** | Same clean ETag, but all servers I tested now report Last-Modified Nov 3 20:19:00 GMT. The identical file was re-published at 20:19 GMT. |
| 10 | "No official statement yet" | **OUTDATED** | The notice in row 1 was posted 2026-11-04 03:14 GMT (12:14 JST), decoded from the post's ID. That is about 75 minutes after the report's last text update (02:00 GMT). |
| 11 | Four official files modified from Sep 27, loading `insightjs.com/l.js` | **CORROBORATED** | Publisher's wording in row 1, plus players' cache entries and ETags matching the report (several commenters). I cannot fetch the old modified files any more. The registry facts in rows 2 to 4 fit the timeline. |
| 12 | A remote-control agent was delivered to some launches; indicator `k2f_chan registered` in `debug.log` | **CORROBORATED** | Many independent commenters report the same log lines, the same payload ETags and matching timings. Not confirmed by the publisher or a security vendor. Not examined by me beyond reading the comments. |
| 13 | The payload's capabilities: run commands, read files, screenshots, steal browser passwords, cookies, SSH keys, wallets | **REPORTED** | Static analysis by one researcher (payload never executed). Commenters' network records (large uploads in the hour an agent started) are consistent with it. NOT VERIFIED by me, on purpose. |
| 14 | Persistence through an HKCU CLSID key and a Chrome-folder DLL | **REPORTED**, not universal | Several victims report it. Others have `k2f_chan` and neither artifact. Absence of the key and DLL does **not** rule out the agent. |
| 15 | The payload was served on only some launches (3 of about 19 on one machine) | **REPORTED** | One machine's data. Commenters also report loader traces with no agent. Overall prevalence is unknown. |
| 16 | The attacker's server at 89.127.233.127 was shut down | **REPORTED** | Hosting provider's reply, relayed by a commenter, and the server timing out from the researcher's machine. NOT VERIFIED by me. |
| 17 | `nikke_launcher.exe` requests administrator rights by default | **REPORTED** | A commenter read the PE manifest of version 0.0.6.841. NOT VERIFIED by me. |
| 18 | "Reinstalling Windows is the safest option" | **Accurate, but conditional** | The report puts it under "If you are infected". In the comments its author is more nuanced: it is the only *certain* fix after a confirmed agent run (nothing logs what `exec` ran), "your call" for some, and "I wouldn't reinstall" for a case that showed no sign of the agent. |
| 19 | Absence of `k2f_chan` is not proof of safety | **Accurate** | The log is deleted by an uninstall or reinstall, and DNS logs can miss lookups (reported). |
| 20 | How fast the publisher responded (not a claim in the report) | **DERIVED** | From the report's timeline (first public warning 16:11 GMT on Nov 3), the verified file times (first file replaced 17:04 GMT) and the decoded notice time (03:14 GMT on Nov 4): the fix came about 53 minutes after the first public warning, and the first official statement about 11 hours after it. A fast fix, a late and thin statement. |

## Where the report is strong

- It separates what it checked from what was reported by others ("reported" is used consistently).
- It corrects itself in public and keeps the revision history.
- Every checkable fact I tested matched, with two small exceptions (rows 9 and 10), both of which came from events after it was written.

## What a better guide should do differently

These are suggestions for the report, not criticism of the analysis:

1. **Put the decision path first.** One line under "If you are infected" gets quoted without its condition. People who never had the agent are wiping their PCs, and several commenters say they nuked everything before checking the log.
2. **Say "check before you uninstall" as step 0.** The report notes that the log is gone after a reinstall, but only in a status paragraph, not in "What to do".
3. **Separate four things:** exposed, loader ran, agent ran, data was taken. Right now "who is at risk" covers everyone who launched, while the report itself says the payload came on only some launches.
4. **Move the changelog out of the header.** The paragraph under the title has seven "earlier" notes before the reader gets to the advice.
5. **Update the two outdated lines** (rows 9 and 10).

## Reproduce it

Use `curl.exe` (Windows 10/11) or any HTTP client. **Do not open `insightjs` addresses in a browser**: use DNS-over-HTTPS and registries only.

```
curl.exe -s https://rdap.verisign.com/com/v1/domain/insightjs.com
curl.exe -s https://rdap.publicinterestregistry.org/rdap/domain/insightjs.org
curl.exe -s "https://api.certspotter.com/v1/issuances?domain=insightjs.com&include_subdomains=true&expand=dns_names&expand=issuer"
curl.exe -s -H "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=insightjs.com&type=A"
```

Pin one CDN server and read the headers (change the IP to test another server). Expected clean `ETag` for this file: `04ee9800128396ba26f10ca70f170967`. The modified version had `b7d842200372ad0d9a84ef4cc8511311`.

```
curl.exe -s -D - -o NUL --resolve na-webassets.playerinfinite.com:443:43.175.144.148 https://na-webassets.playerinfinite.com/comm/nikke_launcher/assets/FeedList.feb647c9.js
```

Or run [`Check-OfficialCdn.ps1`](Check-OfficialCdn.ps1) for all four files.
