# Independent security review of NIKKE Launcher Check v0.4.0

> **Review date:** 2026-11-04  
> **Repository:** [`MotherSphere/NIKKE-Launcher-Check`](https://github.com/MotherSphere/NIKKE-Launcher-Check)  
> **Audited commit:** [`0bc79c96f3ee2a229b02474c2e48aa6f41074eff`](https://github.com/MotherSphere/NIKKE-Launcher-Check/commit/0bc79c96f3ee2a229b02474c2e48aa6f41074eff)  
> **Audited release:** [`v0.4.0`](https://github.com/MotherSphere/NIKKE-Launcher-Check/releases/tag/v0.4.0)  
> **Platform examined:** Windows x86-64  
> **Assessment:** No malicious behavior found in the audited source or inspected release artifact. Residual risk remains.

## Executive conclusion

This review found no evidence that NIKKE Launcher Check v0.4.0 is malware. The audited source implements a local incident-response scanner. Its production scanning logic reads files, processes, loaded modules, selected registry locations and the Windows hosts file. The source contains no scanner telemetry, upload client, command-and-control connection, persistence installer, registry writer, service installer or automatic cleanup routine.[6]

The only normal production file write identified is the report file that the user explicitly selects through the interface. The program can open Explorer, Task Manager, Registry Editor and documentation links after a user action; those operations are visible in `src/open.rs`.[8]

The downloaded Windows executable matched the SHA-256 digest published for the GitHub release. The associated GitHub Actions release run built and tested commit `0bc79c9` successfully before publishing the release assets.[1], [2], [3]

This does **not** prove that every future version, fork or replacement binary is safe. The reviewed Windows binary is unsigned, the repository was new at the time of review, local source tests could not be repeated because Rust/Cargo was unavailable, and no usable independent multi-engine antivirus consensus was obtained. The correct conclusion is therefore:

> **The exact v0.4.0 artifact reviewed here appears to be a legitimate incident-response utility, with no malicious implementation found. This is a bounded technical assessment, not an absolute guarantee.**

## Scope

### Included

- Full local clone at the exact audited commit.
- Rust package manifest and lockfile.
- Scanner, discovery, exposure, report, UI and external-program-opening logic.
- Windows-specific process, loaded-module and registry checks.
- GitHub Actions build and release workflows.
- Git tag and release metadata.
- Windows release executable identity, hash, Authenticode status and basic PE structure.
- Static searches for networking, upload, telemetry, shell execution, persistence, registry modification and deletion behavior.
- A controlled local run using `--cli --redact`.

### Not included

- A formal third-party security audit.
- Complete reverse engineering of every machine-code instruction.
- Reproducible local compilation from source.
- A sandbox with packet capture and kernel telemetry.
- A usable VirusTotal or MalwareBazaar consensus.
- Any commit published after `0bc79c96f3ee2a229b02474c2e48aa6f41074eff`.

## Artifact identity

| Property | Observed value |
|---|---|
| Git commit | `0bc79c96f3ee2a229b02474c2e48aa6f41074eff` |
| Git tag | `v0.4.0` |
| Commit verification | GitHub API reported a valid signature for the merge commit |
| Windows asset | `nikke-check-windows-x86_64.exe` |
| Local file size | 12,268,544 bytes |
| Local SHA-256 | `152199a0afaa483e1a6b9b27a6568731760867022078aa85a075064a7f1d314f` |
| GitHub release digest | `sha256:152199a0afaa483e1a6b9b27a6568731760867022078aa85a075064a7f1d314f` |
| PE type | PE32+ Windows GUI executable, x86-64, six sections |
| Authenticode | Not signed; no publisher certificate |
| Package version | `0.4.0` |
| License declared by project | GPL-3.0-or-later |

The matching local and release hashes establish that the executable examined locally is byte-for-byte identical to the asset represented by GitHub's release metadata.[2]

## Methodology

1. Clone the repository without recursively initializing submodules.
2. Pin the review to the v0.4.0 commit and confirm the tag points to that commit.
3. Read the package manifest, lockfile, Rust modules and CI workflows.
4. Search all Rust source files for networking clients, telemetry, upload logic, persistence, registry writes, service/task creation, deletion and shell execution.
5. Compare every write-like call with its build configuration and call site.
6. Inspect the Windows executable's hash, signature status and PE type.
7. Compare the hash with the GitHub release digest.
8. Inspect the GitHub Actions release run and individual build/test jobs.
9. Run the exact artifact locally with redaction enabled.
10. Record limitations separately from positive findings.

## Source-code findings

### Scanner purpose and dependencies

`Cargo.toml` describes the package as a "Read-only check for traces of the November 2026 NIKKE PC launcher compromise." Its direct dependencies provide the GUI, file dialog, directory walking, process enumeration and Windows APIs. No HTTP client is declared.[5]

Relevant dependency roles:

| Dependency | Observed role |
|---|---|
| `iced` | Desktop interface |
| `image` | PNG decoding for interface imagery |
| `rfd` | Native file dialog for saving a report |
| `walkdir` | Local filesystem traversal |
| `sysinfo` | Process enumeration |
| `windows-sys` | Windows filesystem, process/module, registry and shell APIs |

A dependency list alone cannot prove behavior, so the implementation and call sites were reviewed as well.

### Local scanning behavior

`src/scan.rs` describes its core checks as reading files without writing or using the network. The implementation searches for:

- NIKKE installation and launcher-data locations.
- Compromise strings such as `k2f_chan`, `k2f.agent.state`, `insight.bundle` and `analytics.insightjs.com`.
- Browser-cache and network-state traces.
- Known DLL and COM persistence indicators.
- Running launcher processes and loaded modules.
- Hosts-file protection entries.
- Relevant temporary-file naming patterns.

The verdict is derived from local findings: critical findings produce `Infected`, warnings produce `Exposed`, and the absence of located NIKKE data produces `NotFound`.[6]

### No scanner network client found

The source review and pattern scan found no implementation using:

- `TcpStream` or `UdpSocket`.
- WinHTTP, WinINet or Winsock clients.
- `reqwest` or another HTTP client dependency.
- Webhooks, telemetry endpoints or upload routines.
- Background update checks.

Occurrences of `curl`, HTTP paths and upload timestamps are parsers and test fixtures for **existing NIKKE log lines**. They are not network calls made by the scanner.[6]

### File-writing behavior

Production source contained one direct user-data write:

```rust
std::fs::write(&path, text)
```

This is the GUI's explicit "Save report" action. The destination comes from the user-selected file dialog.

Other `fs::write` and `remove_dir_all` calls found in the source are inside Rust test modules that create and remove temporary fixtures. They are not compiled as normal scanner cleanup behavior.

No production implementation was found that automatically:

- Deletes NIKKE files.
- Moves or quarantines evidence.
- Modifies the hosts file.
- Adds firewall rules.
- Removes a DLL.
- Deletes a registry key.

The project's README also states that the tool does not change, move or delete files and only writes a report selected by the user.[4]

### Registry and persistence behavior

The Windows implementation reads selected registry locations to discover NIKKE installation paths and check the known per-user CLSID indicator. No `RegSetValue`, `RegDeleteKey`, service creation, scheduled-task creation, startup-folder installation or autorun modification was found.

The known CLSID checked by the scanner is:

```text
{E77CC89B-7401-4C04-8CED-149DB35ADD04}
```

Detection strings are evidence rules, not persistence created by the scanner.[6]

### Credential-exposure checks

`src/exposure.rs` checks whether browser password-store files, wallet-extension folders and known secret-file paths exist. Its module comment and implementation show existence/name checks; it does not open or parse the credential-bearing files.[7]

This distinction matters. A report saying that a GitHub token file, browser database or SSH private key exists does not mean the scanner read or uploaded its contents.

### External programs and links

`src/open.rs` contains the program-launching logic. On Windows it can:

- Reveal a selected file or folder in Explorer.
- Open Task Manager.
- Open Registry Editor.
- Open a documentation URL in the default browser.

The implementation uses full Windows-system paths where appropriate and only runs in response to an explicit UI target. No arbitrary command shell or hidden PowerShell execution was found.[8]

### Sensitive-data redaction

The tool supports redacted reports through the GUI's "Hide my info" option and the `--redact` CLI flag. The controlled run used `--cli --redact`, replacing the machine name, usernames, agent identifier and home path with placeholders before the output was preserved.[4]

Redaction is best-effort, not a guarantee of anonymity. Even a redacted report can reveal installed browsers, credential-file categories, timestamps or other details about a user's security posture. Every report should receive a human privacy review before publication.

### Scanner coverage limits

The quick computer scan opens folders only to a depth of five unless a known install or launcher-data location is discovered. Network drives are skipped, unreadable locations remain unchecked, individual files larger than 64 MiB are not read, long log lines are clipped and the discovery walk has a high but finite entry cap.[6]

These controls bound runtime and memory use, but they also mean that a clean result applies only to readable, searched locations and known indicators. The tool is not a general antivirus or a complete forensic acquisition system.

## Build and release provenance

### Build workflow

The build workflow:

- Pins Rust to version `1.99.1`.
- Builds with `cargo build --release --locked`.
- Tests with `cargo test --release --locked`.
- Builds Windows, Linux and macOS artifacts.
- Pins GitHub Actions dependencies to full commit hashes.
- Disables persisted checkout credentials.
- Uploads named artifacts for release packaging.[9]

### Release workflow

The release workflow:

- Creates a release through `release-please`.
- Temporarily holds the release as a draft.
- Calls the reusable build workflow using the release tag.
- Downloads the artifacts from that workflow run.
- Generates `SHA256SUMS.txt`.
- Uploads the binaries and publishes the release.[10]

### Observed v0.4.0 run

GitHub Actions run `41756579517` completed successfully for commit `0bc79c9`. The Windows job reported successful checkout, pinned-toolchain installation, release build, Rust tests and artifact upload. The publish job then generated checksums and attached the artifacts.[3]

The workflow skips its separate CLI smoke test on Windows, while Linux and macOS run that step. The Windows build and Rust test steps still passed.

## Binary inspection

The inspected executable was a normal PE32+ x86-64 Windows GUI application. Basic inspection found:

- No Authenticode publisher signature.
- No appended executable overlay in the earlier PE inspection.
- Ordinary PE sections rather than an obvious packed single-section payload.
- No obvious WinHTTP, WinINet or Winsock import set.
- A hash exactly matching the GitHub release digest.

These observations reduce concern but do not replace source reproducibility or dynamic sandbox analysis.

## Controlled execution

The audited binary was run as:

```powershell
.\nikke-check-windows-x86_64.exe --cli --redact
```

It completed in approximately 16.3 seconds, returned exit code `2` and reported `VERDICT: INFECTED`. Independent inspection of the original NIKKE logs corroborated the scanner's principal findings. The local verdict concerns the NIKKE launcher compromise; it is not evidence that the scanner itself is malicious.

The post-cleanup run returned exit code `3` and reported `NIKKE NOT FOUND`, consistent with the documented deletion of the NIKKE installation and launcher data.

## Antivirus and reputation checks

The review did not obtain an independent multi-engine consensus:

- VirusTotal automation/UI access was blocked by authentication, rate limiting or reCAPTCHA.
- MalwareBazaar returned an authorization error.
- A local Defender scan attempt against the scanner binary did not provide a reliable clean/malicious conclusion during the initial review.
- Later Defender custom and quick scans produced no detections, but an antivirus non-detection is not proof of safety.

No numerical all-clean antivirus claim should be inferred from these results.

## Risk assessment

| Area | Finding | Effect on confidence |
|---|---|---|
| Source behavior | No telemetry, upload, persistence or automatic cleanup found | Positive |
| Credential handling | Existence checks only; no credential-content reads found | Positive |
| Release hash | Local hash matched GitHub release digest | Positive |
| CI provenance | Exact commit built and tested in a successful public run | Positive |
| Actions pinning | Third-party actions pinned to full commits | Positive |
| Code signing | Windows binary unsigned | Negative |
| Repository maturity | Repository was recent at review time | Negative |
| Reproducible local build | Not completed because Cargo was unavailable | Negative |
| Independent artifact attestation | No reproducible-build comparison or separate binary attestation was obtained | Negative |
| Build environment | Hosted runners, package registries and runner images were not hermetically reproduced | Negative |
| Independent AV consensus | Unavailable | Negative |
| Future updates | Outside the reviewed commit | Unknown |

## Final assessment

**Confidence: moderately high for the exact reviewed v0.4.0 artifact.**

The source, release metadata, CI run, binary hash and controlled behavior all support the conclusion that NIKKE Launcher Check v0.4.0 is a genuine local incident-response scanner. No implementation for exfiltration, persistence or destructive cleanup was found.

The assessment intentionally stops short of declaring the repository conclusively safe. Users should verify the hash of the exact binary they run, review changes after the audited commit, and prefer a locally reproduced build or signed release if one becomes available.

## Reproduction checklist

```powershell
# Confirm the downloaded Windows asset.
Get-FileHash .\nikke-check-windows-x86_64.exe -Algorithm SHA256

# Expected for v0.4.0:
# 152199a0afaa483e1a6b9b27a6568731760867022078aa85a075064a7f1d314f

# Confirm Authenticode status.
Get-AuthenticodeSignature .\nikke-check-windows-x86_64.exe | Format-List

# Run with personal information redacted.
.\nikke-check-windows-x86_64.exe --cli --redact
```

For a source build:

```bash
git clone https://github.com/MotherSphere/NIKKE-Launcher-Check.git
cd NIKKE-Launcher-Check
git checkout 0bc79c96f3ee2a229b02474c2e48aa6f41074eff
cargo test --release --locked
cargo build --release --locked
```

A locally compiled binary is not guaranteed to match the GitHub asset byte-for-byte because compiler, linker and environment details can affect reproducibility. Successful source tests still provide useful independent assurance.

## Sources

[1] [Audited v0.4.0 commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/commit/0bc79c96f3ee2a229b02474c2e48aa6f41074eff)  
[2] [NIKKE Launcher Check v0.4.0 release](https://github.com/MotherSphere/NIKKE-Launcher-Check/releases/tag/v0.4.0)  
[3] [v0.4.0 GitHub Actions release run](https://github.com/MotherSphere/NIKKE-Launcher-Check/actions/runs/41756579517)  
[4] [README at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/README.md)  
[5] [Cargo manifest at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/Cargo.toml)  
[6] [Scanner implementation at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/src/scan.rs)  
[7] [Exposure checks at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/src/exposure.rs)  
[8] [External-program opening logic at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/src/open.rs)  
[9] [Build workflow at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/.github/workflows/build.yml)  
[10] [Release workflow at the audited commit](https://github.com/MotherSphere/NIKKE-Launcher-Check/blob/0bc79c96f3ee2a229b02474c2e48aa6f41074eff/.github/workflows/release.yml)
