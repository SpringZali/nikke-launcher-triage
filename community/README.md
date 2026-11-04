# Community reports

Two reports prepared by a community member, [Necromancer](https://github.com/necromancer124), who is learning IT and shared them for public use. They are published here **unchanged**, so the SHA-256 values in [`SHA256_PUBLIC.txt`](SHA256_PUBLIC.txt) still match.

> [!NOTE]
> Community contributions. **Not verified by this guide's maintainers** except where stated below. Not an official statement and not professional incident-response advice.

| File | What it is |
|---|---|
| [`INCIDENT_FORENSIC_REPORT_PUBLIC.md`](INCIDENT_FORENSIC_REPORT_PUBLIC.md) | A redacted case study of one Windows 10 PC on which the agent ran: what the logs show and what they cannot show |
| [`REPOSITORY_SECURITY_REVIEW_PUBLIC.md`](REPOSITORY_SECURITY_REVIEW_PUBLIC.md) | A bounded review of MotherSphere's scanner "NIKKE Launcher Check" v0.4.0. The author found no malicious behaviour in that exact version and lists the review's own limits |
| [`READ_ME_BEFORE_SHARING.txt`](READ_ME_BEFORE_SHARING.txt) | The author's notes on scope and limitations. Read it first |
| [`SHA256_PUBLIC.txt`](SHA256_PUBLIC.txt) | SHA-256 of the two reports |

## What the case study adds

- **A worked example of a RED result.** The agent ran on three separate days (Nov 1 to 3). The logged payload transfer was 205,135 bytes, the same size as in MotherSphere's report.
- **Theft or misuse is not established, and the author says so.** The retained evidence shows the agent ran. It does not show which commands were sent or that any password, key or file was taken. That matches this guide: exposure is serious, misuse is unproven.
- **Evidence was lost to the cleanup.** The original logs and cache were deleted before a full forensic copy was made. This is why the guide says to check before you uninstall.
- **The author's own recommendation** is that a clean Windows reinstall is the highest-confidence recovery. That matches step 6 of the RED steps in the guide.

## What the scanner review adds, and its limits

The review concludes that v0.4.0 of the scanner is a genuine local scanner with no malicious behaviour found, with "moderately high" confidence for that exact version. It lists its own negatives: the executable is unsigned, the repository was new, and the build could not be reproduced.

**This guide does not ask you to run any executable.** If you choose to use any tool, verify its hash against the publisher's, read the source if you can, and treat a clean result as limited.

## What we checked here

We checked only public metadata through the GitHub API on 2026-11-04. We did not download or run the scanner, and we did not see the case study's evidence files (the author kept them private).

- The repository `MotherSphere/NIKKE-Launcher-Check` exists, was created on Nov 3 (very new) and is licensed GPL-3.0.
- Release v0.4.0 points at commit `0bc79c9`, which GitHub marks as signature-verified. The tag points at the same commit.
- GitHub lists the Windows asset's SHA-256 digest as `152199a0afaa483e1a6b9b27a6568731760867022078aa85a075064a7f1d314f`, which equals the value the review gives.
- The repository has **newer commits than v0.4.0** (Nov 4, 11:26 GMT). According to their commit messages, they change how the scanner reads compressed LevelDB data and which downloads it counts. The review does not cover them.
- The files in this folder match the manifest.

Found a problem? Open an issue with a source.