# NIKKE PC launcher compromise: redacted incident and forensic report

> **Incident dates supported by local evidence:** 2026-11-01 through 2026-11-03  
> **Investigation and cleanup date:** 2026-11-04  
> **Affected platform:** Windows 10  
> **Publication status:** Public-safe, identifying information redacted  
> **Overall finding:** Strong evidence that a malicious remote-access agent was downloaded, initialized and resumed across multiple NIKKE launcher sessions.

## Executive summary

The preserved evidence strongly supports that the affected NIKKE PC launcher downloaded and executed a malicious agent on three separate dates: November 1, November 2 and November 3, 2026. The evidence includes successful downloads of `insight.bundle` from `analytics.insightjs.com`, messages showing a Lua payload being downloaded, registration of `k2f_chan`, creation and reuse of a persistent agent identity, and saved `k2f.agent.state` in the launcher's browser-storage data.

These facts establish agent execution. They do **not** establish:

- That a human operator interacted with the computer.
- Which commands, if any, were issued.
- That a specific password, cookie, token, wallet, SSH key or file was stolen.
- That the attacker modified or deleted a particular log.
- Who operated the remote infrastructure.

Known NIKKE installation, launcher-cache, state and registry artifacts were removed during authorized cleanup. Three related domains were blocked in the hosts file, and two IP indicators were blocked inbound and outbound in Windows Firewall. A post-cleanup run of the audited scanner reported `NIKKE NOT FOUND`; Microsoft Defender completed an updated Quick Scan without a detection.

Those results show that the **known artifacts checked by the scanner and cleanup scripts** were no longer present. They cannot exclude an unknown secondary payload or persistence method. A clean Windows installation remains the highest-confidence recovery option.

## Key assessment

| Question | Assessment | Confidence |
|---|---|---|
| Did the launcher request the malicious object? | Yes; logs record `insight.bundle` from `analytics.insightjs.com` and a successful 205,135-byte transfer. | High |
| Did the agent initialize? | Yes; `lua downloaded`, `k2f_chan registered`, `adopted`/`resuming`, and `agent started as` were recorded. | High |
| Did activity recur? | Yes; correlated entries exist for November 1, 2 and 3. | High |
| Was a persistent agent identity saved? | Yes; later runs resumed the same redacted agent ID, and `k2f.agent.state` was found in LevelDB. | High |
| Did a human attacker connect interactively? | Not established. No command-and-control transcript or packet capture was preserved. | Unknown |
| Were credentials or files stolen? | Not established. Relevant data locations were potentially accessible, but no upload proof was preserved. | Unknown |
| Did the attacker clear Windows event logs? | No surviving Event ID 1102 or 104 evidence was found. | Moderate for surviving logs; not absolute |
| Did the attacker alter individual NIKKE logs? | No surviving evidence was found, but auditing and journal retention were insufficient to rule it out. | Unknown |
| Are known NIKKE artifacts still present? | Post-cleanup checks found none of the known artifacts that were tested. | High for tested indicators |
| Can these checks establish that the entire system is clean? | No. | Not applicable |

## Scope and privacy controls

This report describes one Windows endpoint. It intentionally omits or replaces:

- Windows username and domain.
- Computer/host name.
- NIKKE agent identifier.
- User-specific absolute paths.
- Public and private IP addresses belonging to the affected user.
- Account identifiers, credentials, tokens and recovery data.

Placeholders used in excerpts:

| Placeholder | Meaning |
|---|---|
| `<USER_PROFILE>` | The affected user's Windows profile |
| `<NIKKE_INSTALL_DIR>` | The removed NIKKE installation directory |
| `<LAUNCHER_DATA_DIR>` | The removed launcher-data directory under `%APPDATA%` |
| `<COMPUTER_NAME>` | The redacted Windows host name |
| `<AGENT_ID>` | The redacted persistent NIKKE agent identity |
| `[REDACTED]` | Sensitive value intentionally withheld |

Public malicious-infrastructure indicators remain visible because defenders may need them for detection and blocking. Listing an IP address here does not prove ownership, operator identity or the exact connection made by this endpoint.

## Evidence register

The following evidence files were preserved before or during cleanup. Hashes below were recalculated on 2026-11-04 from the current preserved copies.

Only files explicitly marked **public-safe** should be uploaded unchanged. Private support files contain local paths or system details and must be redacted before public release.

| ID | File | Purpose | Publication status | SHA-256 |
|---|---|---|---|---|
| E1 | `scan-report-redacted.txt` | Initial scanner findings, redacted | Private; identifiers are redacted, but it exposes security-profile details | `28cceee34a7369a5f6593e93d01f70aa3672d9d63cb60e65faafefe046897ff7` |
| E2 | `cleanup-log.txt` | User-context cleanup actions | Private; contains local paths | `6bd0e28b1beac5fd4dbff2af03f76e6f03930a883be514cbe54f5e5a99de3deb` |
| E3 | `admin-cleanup-log.txt` | Elevated blocking and cleanup actions | Private; contains a local path | `39477e7aaada140147addd0ed6d76931137b50f0edf22670c221b4ff5426f100` |
| E4 | `post-cleanup-scan.txt` | Post-cleanup scanner result | Public-safe after final human review | `4349ae47452d7101d2c2b11a3ead7573b44b6fa9994fe1fc0734880914177ccd` |
| E5 | `windows-log-forensics.txt` | Event Log, audit-policy and USN-journal review | Private; contains raw system records | `15ad2bafc7ebf9a9585297a08932f0c4e565bd4d58f64f72073b076f74a0cba8` |
| E6 | `hosts-before-cleanup.txt` | Backup of the pre-cleanup hosts file | Private; may expose local configuration | `75ca0fcf03a4c4053ec00e462dfbe161d7cccd85785f00652435d25f667b6e18` |
| E7 | `windows-log-forensics-supplement.txt` | Sanitized Sysmon check and oldest retained USN record | Private; contains volume-specific journal metadata | `ad9f57d468f4bbda307b1a22bc807bc22675930e60527b8030d089db3e18f493` |

Original NIKKE logs and cache were removed during authorized cleanup. The redacted report and relevant excerpts had already been preserved and independently reviewed, but a complete forensic image and hash set for every original artifact were not created first. See [Evidence-preservation limitations](#evidence-preservation-limitations).

The two Markdown reports are the intended public artifacts. Supporting evidence files should remain private unless separately redacted and reviewed.

## Methodology

1. Audit the scanner's source and release provenance before executing it.
2. Run the exact audited v0.4.0 executable with `--cli --redact`.
3. Independently inspect the original NIKKE debug, tinyget/download and launcher-cache evidence.
4. Correlate download, initialization and persistent-state records across dates.
5. Preserve a redacted report and calculate a hash.
6. Run Defender scans of the affected folders.
7. Remove known NIKKE files, cache, protocol/uninstall registry entries and temporary indicators after authorization.
8. Add domain and IP blocks.
9. Update Defender and run a Quick Scan.
10. Rerun the audited scanner and execute focused cleanup-verification checks.
11. Collect Windows event-log, audit-policy and NTFS USN-journal data with administrative privileges.
12. Separate confirmed facts, reasonable inference and unknowns.

## Confirmed compromise evidence

### 1. Successful payload requests

Three launcher download logs recorded the same remote object and successful transfer. Safe normalized excerpt:

```text
url=https://analytics.insightjs.com/comm/assets/insight.bundle
curl perform success
total=205135
```

What this establishes:

- The launcher requested `/comm/assets/insight.bundle` from `analytics.insightjs.com`.
- The transfer routine reported success.
- The logged transfer size was 205,135 bytes.

What it does not establish by itself:

- The exact payload bytes, because the downloaded object was not preserved as a standalone forensic sample.
- Which IP address was selected by DNS at that moment.
- The packet-level destination port.
- What happened after execution.

### 2. Agent initialization in `debug.log`

The original `<NIKKE_INSTALL_DIR>\Launcher\intl_service\debug.log` contained correlated messages on three dates. The personal values are replaced below.

First confirmed sequence:

```text
lua downloaded to log\tinyget\...
k2f_chan registered
adopted <AGENT_ID>
agent started as <COMPUTER_NAME>
```

Later sequences:

```text
lua downloaded to log\tinyget\...
k2f_chan registered
resuming <AGENT_ID>
agent started as <COMPUTER_NAME>
```

Correlated debug entries were found across November 1, 2 and 3. The switch from `adopted` on the first run to `resuming` on later runs supports continuity of the same saved agent identity.

### 3. Persistent state

The key `k2f.agent.state` was found in the launcher's LevelDB data at the normalized location:

```text
<LAUNCHER_DATA_DIR>\tbs_cache\Local Storage\leveldb\000003.log
```

The audited scanner source describes this key as the agent's saved identity state. It deliberately clips the evidence before the `agent_pass` field so a report does not disclose the saved secret.[2]

This state, combined with the same `<AGENT_ID>` being resumed on later dates, is strong evidence that the agent ran and retained continuity between launcher sessions.

### 4. Launcher browser/network state

The launcher cache also contained records for:

- `analytics.insightjs.com` in network state.
- `insightjs.com` in cache and reporting state.
- HSTS/network metadata related to the observed host.

The scanner source distinguishes a general `insightjs.com` loader trace from the more specific `analytics.insightjs.com`/`insight.bundle` agent-server evidence.[2]

## Timeline

Times below are derived from preserved redacted scanner output and the independently reviewed local logs. They are endpoint-local log times unless marked UTC.

| Date/time | Event | Evidence | Interpretation |
|---|---|---|---|
| 2026-11-01 20:38 | Successful `insight.bundle` download recorded | E1 and original tinyget log review | Payload requested and transferred |
| 2026-11-01, immediately afterward | Lua download, `k2f_chan` registration, identity `adopted`, agent start | E1 and original `debug.log` review | First confirmed agent initialization |
| 2026-11-02 22:19 | Successful `insight.bundle` download recorded | E1 and original tinyget log review | Payload requested again |
| 2026-11-02, immediately afterward | `k2f_chan` registration, same identity `resuming`, agent start | E1 | Persistent identity reused |
| 2026-11-03 approximately 17:02–17:03 | Successful download and third initialization sequence | E1 | Final confirmed execution in preserved logs |
| 2026-11-03 20:25:58 | Oldest retained NTFS USN record | E7 | Journal retained no earlier compromise-period history |
| 2026-11-04 | Initial audited scanner run | E1 | `VERDICT: INFECTED`, exit code `2` |
| 2026-11-04 11:28:27–11:28:28 | NIKKE files/cache deleted | E5; E2; E3 | Authorized cleanup, not demonstrated attacker action |
| 2026-11-04 | Defender definitions updated and Quick Scan completed | Cleanup verification | No Defender detection reported |
| 2026-11-04 | Audited scanner rerun | E4 | `VERDICT: NIKKE NOT FOUND`, exit code `3` |

## What `k2f` means in this evidence

`k2f` appears to be the agent's internal name or protocol prefix:

- `k2f_chan registered` records initialization of the agent's bridge or communication channel.
- `k2f.agent.state` is persistent state used to retain the agent identity and related session data.
- `adopted <AGENT_ID>` marks the first saved identity observed locally.
- `resuming <AGENT_ID>` shows later sessions loading that identity again.

This supports an initialized, persistent agent. It does not, by itself, identify the operator or disclose what remote commands were sent.

## Indicators of compromise

### Network indicators

| Indicator | Type | Local status | Evidentiary meaning | Action |
|---|---|---|---|---|
| `analytics.insightjs.com` | Domain | Directly observed | Host in the successful `insight.bundle` request and launcher state | Blocked |
| `/comm/assets/insight.bundle` | HTTPS resource | Directly observed | Requested object; transfer logged as successful, 205,135 bytes | Documented |
| `insightjs.com` | Domain | Directly observed in launcher cache/state | Associated loader domain | Blocked |
| `insightjs.org` | Domain | Project/related IOC; not established as a successful local connection in the preserved excerpts | Related fallback/defensive block indicator | Blocked |
| `89.127.233.127` | IPv4 | Project IOC; not tied to a specific preserved local flow | Listed by the audited scanner project as the payload IP | Blocked inbound and outbound |
| `89.126.250.172` | IPv4 | Project IOC; not tied to a specific preserved local flow | Listed by the audited scanner project as an earlier related server | Blocked inbound and outbound |

The project source labels these addresses as attacker infrastructure, but the preserved endpoint excerpts do not show which exact connection, protocol or port used either address.[2] The addresses therefore remain **block-list indicators**, not proof of operator identity or attribution.

### Ports and protocols

| Port/protocol | Status | Explanation |
|---|---|---|
| TCP/443 | Inferred, not packet-confirmed | The observed URL uses `https://` without an explicit port, for which TCP/443 is the conventional default. |
| UDP/443 | Possible, not established | Launcher network state advertised HTTP/3 (`h3`), which commonly uses QUIC over UDP/443. An advertisement is not proof that this endpoint used it. |
| Other ports | Unknown | No packet capture, proxy log or preserved numeric destination-port field was available. |

No report should claim a confirmed numeric attacker port from this endpoint. The Windows Firewall rules applied during cleanup block both IP indicators on all ports in both directions.

### File and state indicators

| Artifact | Category | Status on affected endpoint | Meaning |
|---|---|---|---|
| `insight.bundle` | Malicious payload object | Download confirmed by logs; standalone bytes not preserved | Remote agent object requested from observed domain |
| `k2f.agent.state` | Agent state key | Confirmed in launcher LevelDB before cleanup | Persistent agent identity/state |
| `k2f_chan` | Agent string/state marker | Confirmed in `debug.log` and launcher data | Agent channel initialized |
| Lua content saved under a tinyget log-style name | Malicious payload behavior | Referenced in logs; original cache later removed | Downloaded Lua/LuaJIT agent material |
| `debug.log` | Evidence file, not malware | Contained initialization records; deleted during authorized cleanup | Primary local execution evidence |
| Tinyget/download logs | Evidence files, not malware | Contained successful transfer records; deleted during authorized cleanup | Primary local download evidence |
| `tbs_cache` and LevelDB | Compromise-bearing launcher data | Confirmed before cleanup; removed | Held loader/network and persistent-state traces |
| `onominan.tmp` | Low-specificity temporary indicator | Removed during cleanup | 22-character hex marker; scanner notes similar files can be created by other Tencent software |
| `platform_experience_helper.dll` | Known persistence indicator | Not found | No surviving evidence of this DLL persistence method |
| HKCU CLSID `{E77CC89B-7401-4C04-8CED-149DB35ADD04}` | Known COM persistence indicator | Absent during verification | No surviving evidence of this registry persistence method |
| `k2f-bcreds-*` | Possible credential-collection output naming pattern | Not reported as found | No local artifact proving browser credential collection |
| `k2f_screen_*.jpg` | Possible screenshot output naming pattern | Not reported as found | No local artifact proving screenshot collection |

### Files that should not be mislabeled as malware

The following are ordinary launcher or evidence components. Their presence alone does not make them malicious:

- `NIKKE.exe`
- `nikke_launcher.exe`
- `tinyget.dll`
- Ordinary launcher log files
- Browser credential databases
- SSH keys
- GitHub CLI, Docker or cloud-client configuration files

The malicious operation used the launcher's download and embedded-browser facilities. That does not prove every launcher component was malicious or modified.

## Potentially exposed data

The agent ran with the permissions of the logged-in user. Files readable by that user should therefore be treated as potentially exposed. The audited scanner checks for the **existence** of relevant locations without opening their secret contents.[3]

Potentially exposed categories include:

- Browser password stores and session data.
- Browser extension and cryptocurrency-wallet data.
- GitHub CLI tokens and Git credential files.
- Docker registry credentials.
- SSH private keys.
- Cloud CLI credentials.
- Package-registry tokens.
- `.env` and other developer configuration files.

Presence is not proof of access or theft. No preserved local message explicitly states that any password database, cookie, token, wallet, SSH key or personal file was uploaded.

## Interactive access and exfiltration: what is not proven

The evidence shows an agent capable of communication initialized on the endpoint. The scanner project's incident description says the agent family can run commands, read files, take screenshots and collect browser data.[1], [4]

However, capability is not equivalent to observed use. This endpoint had no preserved:

- Command transcript.
- Command-and-control packet capture.
- Proxy or router log showing command traffic.
- Upload receipt naming stolen files.
- Screenshot output file.
- Credential-collection output file.
- Server-side log.

The defensible statement is:

> The endpoint was placed at risk of remote command execution and data access. Specific operator interaction and specific exfiltration were not established by the retained evidence.

## Windows log and file-tampering review

### Audit policy

Elevated `auditpol` output showed `No Auditing` for:

- File System.
- Registry.
- Handle Manipulation.
- Other Object Access Events.

Consequently, Security Event IDs such as 4656, 4660, 4663 and 4670 were not expected for individual NIKKE file activity.

The Security log used circular retention. Its oldest retained event was dated 2026-10-31 22:43:15, so retained-event searches do not establish what may have existed before that boundary.

### Event logs checked

No surviving matches were found for:

| Event ID | Log | Meaning checked |
|---|---|---|
| 1102 | Security | Security audit log cleared |
| 104 | System | Event log cleared |
| 4719 | Security | System audit policy changed |

This means no surviving evidence of whole-log clearing or an audit-policy change was found. It is not mathematical proof that no event or individual file was changed.

### Sysmon

The Sysmon Operational log was absent; this was rechecked and preserved in E7:

```text
SYSMON_LOG_NOT_PRESENT
```

Therefore, Sysmon process, file-create and file-delete telemetry was unavailable.

### NTFS USN Journal

The separately preserved oldest-record capture in E7 reported:

```text
2026-11-03 20:25:58
```

The final confirmed malicious execution was approximately three hours earlier, around 17:02–17:03. Earlier journal history had already wrapped. The retained journal therefore cannot answer what happened during most of the confirmed compromise period.

USN deletion records at approximately 2026-11-04 11:28:27–11:28:28 included `debug.log`, tinyget logs, launcher logs, `tbs_cache`, the launcher-data directory, `onominan.tmp` and `<NIKKE_INSTALL_DIR>`. Those timestamps align with the authorized cleanup performed during this investigation.

### Tampering conclusion

> No surviving Windows record was found showing attacker modification or deletion of the NIKKE evidence. Because detailed Object Access auditing was disabled, Sysmon was absent and the relevant USN history had wrapped, tampering during the compromise cannot be ruled out.

## Microsoft Defender findings

Before cleanup, Defender custom scans of the NIKKE installation and launcher-data folders reported no detections. After cleanup:

- Defender signatures were updated to version `1.463.119.0`.
- Real-time protection was enabled.
- A Quick Scan completed normally.
- `Get-MpThreatDetection` returned no detection record.

These Defender results were observed during the live response but were not preserved as a standalone Defender transcript in E1–E7. They should therefore be treated as investigator-recorded observations rather than independently re-verifiable evidence files.

This does not contradict the execution evidence. Antivirus products are not complete forensic timeline systems. Relevant possibilities include:

- Dynamically delivered or in-process code may not exist as a normal standalone executable.
- Signatures may not cover a new supply-chain payload.
- Log and cache files containing evidence are not themselves necessarily detected as malware.
- The known launcher artifacts had been removed before the final Quick Scan.

The accurate conclusion is **"Defender reported no detection,"** not **"the malicious code never executed."**

## Cleanup and containment

Authorized cleanup performed on 2026-11-04 included:

- Stopping accessible NIKKE processes.
- Removing the NIKKE installation directory.
- Removing `%APPDATA%` launcher data and `tbs_cache`.
- Removing LevelDB data containing `k2f.agent.state`.
- Removing the NIKKE protocol and uninstall registry entries.
- Removing `onominan.tmp`.
- Verifying the known malware-specific COM key was absent.
- Verifying `platform_experience_helper.dll` was absent.
- Adding hosts-file blocks for:
  - `insightjs.com`
  - `analytics.insightjs.com`
  - `insightjs.org`
- Flushing the DNS cache.
- Adding enabled inbound and outbound Windows Firewall blocks for:
  - `89.127.233.127`
  - `89.126.250.172`
- Updating Defender definitions and running a Quick Scan.

The scanner itself did not perform these changes; separate user-authorized cleanup scripts did. The audited scanner is read-only except for a report the user explicitly saves.[1], [2]

## Post-cleanup verification

The preserved post-cleanup scan reported:

```text
VERDICT: NIKKE NOT FOUND

Is anything still active? No.
Is there something to clean up? No.
Are you protected for next time? Yes.
```

The scanner returned exit code `3`, which corresponds to `NIKKE NOT FOUND`.[2]

Additional live-response verification confirmed:

- No NIKKE process remained.
- `<NIKKE_INSTALL_DIR>` no longer existed.
- `<LAUNCHER_DATA_DIR>` no longer existed.
- `tbs_cache` no longer existed.
- Known registry indicators were absent.
- Hosts entries were present.
- Firewall rules for both IP indicators were enabled inbound and outbound.
- Defender real-time protection was enabled.
- The Quick Scan had completed.
- Preserved reports remained available.

The one-time verification output was not retained as a separate public evidence file. The post-cleanup scanner also reported 43 permission errors during its quick scan. Its statements therefore refer only to known indicators in readable, searched locations; they are not proof that no unknown persistence or secondary payload exists.

## Evidence-preservation limitations

The response prioritized containment after the initial redacted report and independent log review. At the user's direction, the original NIKKE installation, cache and logs were deleted.

What was preserved:

- Redacted scanner output.
- Safe excerpts independently reviewed before deletion.
- Cleanup records.
- Post-cleanup scanner output.
- Hosts-file backup.
- Windows log/audit/USN findings.
- SHA-256 hashes of the preserved evidence copies.

What was not preserved:

- A full disk image.
- A complete raw copy of every original NIKKE file.
- Original hashes for every raw log before deletion.
- The standalone `insight.bundle` payload bytes.
- Volatile-memory capture.
- Packet capture or server-side command logs.

A hash of the current preserved report proves the current file's identity from the point it was hashed; it does not retroactively prove the exact bytes of every source log on November 1–3.

## Recommended follow-up

Because agent execution is confirmed and data access cannot be excluded:

1. Change important passwords from a separate clean device.
2. Revoke active sessions and remembered devices.
3. Review and revoke OAuth applications and personal access tokens.
4. Replace development tokens, API keys and SSH keys that existed during the incident.
5. Review email, GitHub, cloud, banking and social-account login histories.
6. If cryptocurrency wallets were present, consider moving assets to a new wallet created on a clean device.
7. Keep an encrypted offline copy of this evidence set.
8. Monitor the listed domains and IP indicators at the DNS, firewall and endpoint layers.
9. Consider a clean Windows reinstall for maximum confidence.

A reinstall should be performed only after preserving needed evidence and backing up known-safe personal data. Executables and scripts from the affected environment should not be blindly restored.

## Reproducibility notes

The scanner used for this incident was NIKKE Launcher Check v0.4.0 at commit:

```text
0bc79c96f3ee2a229b02474c2e48aa6f41074eff
```

Windows executable SHA-256:

```text
152199a0afaa483e1a6b9b27a6568731760867022078aa85a075064a7f1d314f
```

A separate companion report, `REPOSITORY_SECURITY_REVIEW_PUBLIC.md`, documents the source, release provenance, signature status and limitations. Future investigators should pin the exact commit and verify the executable hash before comparing results.

## Final conclusion

The available artifacts provide strong forensic evidence that a malicious NIKKE launcher agent was downloaded, initialized and resumed across multiple launcher sessions on November 1–3, 2026. The evidence does not establish which commands were issued, whether a human operator connected interactively or whether any particular credentials or files were exfiltrated.

Cleanup removed the known NIKKE installation, cache, state and registry traces checked by the scripts, and network blocks were added for the documented indicators. Post-cleanup scanning found no remaining known NIKKE artifact. Unknown secondary persistence cannot be excluded without stronger telemetry or a clean reinstall.

## Sources

[1] [NIKKE Launcher Check README at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/README.md)  
[2] [Scanner implementation at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/src/scan.rs)  
[3] [Exposure checks at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/src/exposure.rs)  
[4] [MotherSphere incident write-up](https://gist.github.com/MotherSphere/d6c049a09ba8ac3085c51ee9df24a4e5)
