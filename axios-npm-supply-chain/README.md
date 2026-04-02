# Axios npm Supply Chain Compromise — Caldera Emulation Plan

> **MITRE Caldera ID:** G1015 (Scattered Spider overlap via TeamPCP) | **Platform:** Windows | **Type:** Supply Chain / RAT

Emulates the Axios npm supply chain compromise (March 30-31, 2026) conducted by **BlueNoroff** (Lazarus subgroup / DPRK). Threat actors compromised the npm account of axios lead maintainer `jasonsaayman` via a long-lived access token, then published malicious versions `axios@1.14.1` (latest) and `axios@0.30.4` (legacy) that introduced a malicious transitive dependency — `plain-crypto-js@4.2.1` — serving as a cross-platform Remote Access Trojan (RAT) dropper.

This emulation plan reproduces the Windows RAT delivery and C2 phases as safe, non-destructive Caldera ability simulations.

**Attribution:** BlueNoroff / Lazarus Group (DPRK)
**Initial Access Broker:** TeamPCP

---

## Attack Chain

```
Phase 1         Phase 2           Phase 3           Phase 4           Phase 5        Phase 6
───────────────────────────────────────────────────────────────────────────────────────────────────
Supply Chain    RAT Download      RAT Execution     Persistence      Obfuscation    C2 Beacon
Discovery       (C2 Ingress)      (wt.exe)         (Registry)       / Cleanup      + Exfil
                                                                                   Staging
T1195.002       T1105             T1059.001         T1547.001        T1027/T1070.004 T1104/T1005
npm package     sfrclak.com:8000  cmd.exe hollowing MicrosoftUpdate  XOR/Obfusc    60s beacon
enumeration     /6202033         + VBS launcher    Run key          self-delete    sfrclak.com
```

---

## MITRE ATT&CK Coverage

| Phase | TTP ID | Technique | Ability |
|-------|--------|-----------|---------|
| Supply Chain | T1195.002 | Software Supply Chain | `axios-npm-package-discovery` |
| Discovery | T1083 | File and Directory Discovery | `axios-postinstall-script-detection` |
| Command & Control | T1105 | Ingress Tool Transfer | `axios-windows-rat-download` |
| Execution | T1059.001 | PowerShell | `axios-windows-rat-execution` |
| Persistence | T1547.001 | Registry Run Keys | `axios-windows-persistence` |
| Defense Evasion | T1027 | Obfuscated Files or Information | `axios-obfuscation-patterns` |
| Defense Evasion | T1070.004 | Indicator Removal | `axios-artifact-deletion` |
| Command & Control | T1104 | Multi-Stage Channels | `axios-c2-beacon-simulation` |
| Collection | T1005 | Data from Local System | `axios-exfil-staging` |

---

## Affected Versions (IoC)

| Package | Version | Status |
|---------|---------|--------|
| axios | 1.14.1 | Compromised — unpublished |
| axios | 0.30.4 | Compromised — unpublished |
| plain-crypto-js | 4.2.1 | Malicious payload carrier — security hold |
| plain-crypto-js | 4.2.0 | Clean decoy (reputation-seeding) |

**Safe versions to pin:** `axios@1.14.0` (1.x) or `axios@0.30.3` (0.x)

---

## C2 Infrastructure

| Indicator | Value |
|-----------|-------|
| Primary Domain | `sfrclak.com` |
| Backup Domain | `callnrwise.com` (same IP) |
| IP | `142.11.206.73` (AS54290 — Hostwinds LLC) |
| Port | 8000 (HTTP, cleartext) |
| User-Agent | `mozilla/4.0 (compatible; msie 8.0; windows nt 5.1; trident/4.0)` |
| Beacon Interval | 60 seconds |
| JARM | `28d28d28d00028d00028d28d28d28d96d86b34e11c2d3d5508f7111adf9d91` |
| Payload Path (Windows) | `/6202033` |
| Payload Path (macOS) | `/product0` |
| Payload Path (Linux) | `/product2` |

---

## Windows RAT IoCs

| Indicator | Value |
|-----------|-------|
| Staged Binary | `%PROGRAMDATA%\wt.exe` |
| VBS Launcher | `%TEMP%\6202033.vbs` |
| PowerShell Stage 2 | `%TEMP%\6202033.ps1` |
| Persistence Key | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MicrosoftUpdate` |
| RAT Commands | `kill`, `peinject`, `runscript`, `rundir` |

---

## Prerequisites

- [MITRE Caldera](https://github.com/mitre/caldera) 5.x (self-hosted or Docker)
- A Windows target VM with a Caldera Sandcat agent deployed
- PowerShell 5.1+ on the target

---

## Deployment

**Option A — Direct (non-Docker)**

```bash
cd axios-npm-supply-chain
cp .env.example .env
# Edit .env: set CALDERA_HOME=/path/to/caldera
chmod +x deploy_to_caldera.sh
./deploy_to_caldera.sh
# Restart Caldera to load new abilities
```

**Option B — Docker**

```bash
cp .env.example .env
# Edit .env: set DOCKER_MODE=true and DOCKER_CONTAINER=<your-container-name>
chmod +x deploy_to_caldera.sh
./deploy_to_caldera.sh
docker restart <your-container-name>
```

---

## Running the Emulation

1. Open the Caldera web UI
2. Go to **Agents** → deploy a Sandcat agent on a Windows target
3. Go to **Operations** → Create new operation
4. Select **Axios npm Supply Chain Compromise** adversary profile
5. Click **Start**

---

## Detection Rules

Sigma rules are provided in `detection_rules/axios_sigma_rules.yml`:

| Rule | Level | TTP |
|------|-------|-----|
| Suspicious npm postinstall Script Execution | High | T1195.002 |
| Compromised axios npm Package Version Detected | Critical | T1195.002 |
| RAT Binary Dropped to ProgramData (wt.exe) | High | T1105 / T1059.001 |
| MicrosoftUpdate Registry Run Key Persistence | High | T1547.001 |
| XOR Obfuscation Pattern (OrDeR_7077) | High | T1027 |
| C2 Contact to sfrclak.com on Port 8000 | Critical | T1104 / T1571 |
| Suspicious IE8 User-Agent on Non-Standard Port | High | T1071.001 |
| RAT Artifact Deletion (fs.unlinkSync / self-delete) | Medium | T1070.004 |

Import into your SIEM: Splunk, Elastic, Microsoft Sentinel, QRadar, Chronicle.

---

## Targeted Applications

| Application | Context |
|------------|---------|
| npm / Node.js | Package manager used to install malicious axios |
| Windows PowerShell | RAT execution surface |
| Windows Registry | Persistence via Run keys |
| Browser profile data | Collected by RAT's `rundir` command |
| Environment variables | Exfiltrated via C2 beacon |

---

## Attribution

- **BlueNoroff** (Lazarus Group / DPRK) — NukeSped AV classification, `macWebT` project path linking to RustBucket `webT` module, consistent IE8/WinXP User-Agent across 3+ years of campaigns, Hostwinds AS54290 infrastructure overlap
- **TeamPCP** (Initial Access Broker) — same actor group previously compromised Trivy, KICS, LiteLLM (PyPI), and Telnyx in March 2026

---

## References

- [SANS ISC — Axios NPM Supply Chain Compromise](https://www.sans.org/blog/axios-npm-supply-chain-compromise-malicious-packages-remote-access-trojan)
- [Strobes Security — Axios npm Supply Chain Attack](https://strobes.co/blog/axios-npm-supply-chain-attack-compromised-rat-2026/)
- [GitHub Gist — Full IOC Set + Reverse Engineering](https://gist.github.com/N3mes1s/0c0fc7a0c23cdb5e1c8f66b208053ed6)
- [Picus Security — Axios RAT Delivery Analysis](https://www.picussecurity.com/resource/blog/axios-npm-supply-chain-attack-cross-platform-rat-delivery-via-compromised-maintainer-credentials)
- [MITRE ATT&CK — Supply Chain Compromise](https://attack.mitre.org/tactics/T1195/)
