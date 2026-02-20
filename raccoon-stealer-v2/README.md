# Raccoon Stealer v2 — Caldera Emulation Plan

> **MITRE ATT&CK ID:** S1148 | **Platform:** Windows | **Type:** Infostealer / MaaS

Raccoon Stealer is an information-stealing malware-as-a-service (MaaS) active since 2019 and sold in underground forums. This emulation plan reproduces the TTPs observed in Raccoon Stealer v2 (RecordBreaker) campaigns, covering system discovery, browser credential theft, cryptocurrency wallet targeting, and data exfiltration — all implemented as safe, non-destructive PowerShell simulations.

**Associated Groups:** Scattered Spider (G1015)

---

## Contents

```
raccoon-stealer-v2/
├── README.md
├── .env.example                  # Config template — copy to .env and fill in values
├── deploy_to_caldera.sh          # Automated deployment script (reads .env)
├── adversaries/
│   └── raccoon_stealer.yml       # Caldera adversary profile (20 abilities)
├── abilities/
│   ├── raccoon_system_info_discovery.yml
│   ├── raccoon_registry_query.yml
│   ├── raccoon_user_discovery.yml
│   ├── raccoon_process_discovery.yml
│   ├── raccoon_software_discovery.yml
│   ├── raccoon_browser_discovery.yml
│   ├── raccoon_browser_harvesting.yml
│   ├── raccoon_wallet_discovery.yml
│   ├── raccoon_collection.yml
│   └── raccoon_staging_exfil.yml
└── detection_rules/
    └── raccoon_sigma_rules.yml   # 7 Sigma detection rules
```

---

## Threat Profile

| Attribute | Value |
|-----------|-------|
| Malware | Raccoon Stealer v2 (RecordBreaker) |
| MITRE ID | S1148 |
| Type | Information Stealer |
| Platform | Windows |
| First Seen | 2019 |
| Active Variants | v1 (2019–March 2022), v2 (June 2022–present) |
| Associated Groups | Scattered Spider (G1015) |
| Distribution | Cracked software sites, malvertising, phishing |
| Language | C/C++ + ASM |
| C2 Protocol | HTTP POST (unencrypted) |

---

## MITRE ATT&CK Coverage

### Discovery

| ID | Technique | Raccoon Behavior |
|----|-----------|-----------------|
| T1082 | System Information Discovery | Collects OS, CPU, RAM, display info |
| T1012 | Query Registry | Reads `HKLM:\SOFTWARE\Microsoft\Cryptography\MachineGuid` |
| T1033 | System Owner/User Discovery | Gathers username via Advapi32 |
| T1087.001 | Local Account Discovery | Checks if running as NT AUTHORITY\SYSTEM |
| T1057 | Process Discovery | Enumerates running processes |
| T1083 | File and Directory Discovery | Searches for wallet files and browser data |
| T1518 | Software Discovery | Queries installed applications from registry |
| T1124 | System Time Discovery | Collects timezone via `GetUserDefaultLocaleName` |
| T1614 | System Location Discovery | Checks locale for "ru" string |

### Credential Access

| ID | Technique | Raccoon Behavior |
|----|-----------|-----------------|
| T1539 | Steal Web Session Cookie | Harvests cookies from Chrome, Firefox, Edge |
| T1555.003 | Credentials from Web Browsers | Steals passwords, autofill, credit card data |

### Collection

| ID | Technique | Raccoon Behavior |
|----|-----------|-----------------|
| T1005 | Data from Local System | Steals crypto wallet files |
| T1113 | Screen Capture | Takes desktop screenshot via BitBlt |
| T1119 | Automated Collection | File grabber based on C2 config patterns |
| T1213 | Data from Information Repositories | Investigates Telegram Desktop `tdata` cache |
| T1560 | Archive Collected Data | Stages data into `System info.txt` |

### Defense Evasion

| ID | Technique | Raccoon Behavior |
|----|-----------|-----------------|
| T1027.007 | Dynamic API Resolution | Dynamically links WinAPI functions at runtime |
| T1027.013 | Encrypted/Encoded File | RC4 + Base64 string obfuscation |
| T1140 | Deobfuscate/Decode Files | Decrypts C2 URLs and strings at runtime |
| T1070.004 | Indicator Removal: File Deletion | Removes files post-exfiltration |

### Command and Control / Exfiltration

| ID | Technique | Raccoon Behavior |
|----|-----------|-----------------|
| T1071.001 | Web Protocols | HTTP POST for all C2 communications |
| T1105 | Ingress Tool Transfer | Downloads sqlite3.dll, nss3.dll, mozglue.dll |
| T1041 | Exfiltration Over C2 Channel | Exfiltrates stolen data over HTTP |

---

## Attack Chain

```
Phase 1 — Discovery
  ├── System fingerprinting (OS, CPU, RAM, MachineGuid)
  ├── User & privilege enumeration
  ├── Process enumeration
  ├── Installed software discovery
  └── Timezone / locale check

Phase 2 — Browser Credential Harvesting
  ├── Chrome profile & Login Data discovery
  ├── Firefox logins.json & cookies.sqlite discovery
  ├── Edge profile discovery
  ├── Cookie theft (sqlite3 queries)
  ├── Saved password theft
  └── Autofill / credit card data

Phase 3 — Cryptocurrency Targeting
  ├── wallet.dat file search (Bitcoin)
  ├── Wallet application discovery (Exodus, Atomic, Electrum, Monero, etc.)
  └── Browser extension wallet discovery (MetaMask, Phantom, Coinbase, etc.)

Phase 4 — Additional Collection
  ├── Telegram Desktop tdata investigation
  ├── Screenshot capture
  └── File grabber (Desktop / Documents)

Phase 5 — Staging & Exfiltration
  ├── Create System info.txt
  └── HTTP POST exfiltration (simulated)
```

---

## Prerequisites

### Caldera Server
- Caldera 5.x (self-hosted or Docker)

### Windows Target VM
- Windows 10 / 11
- PowerShell 5.1+
- Caldera Sandcat agent deployed
- Network access to Caldera server port 8888

**Optional** (for realistic browser/wallet testing):
- Google Chrome, Mozilla Firefox, Microsoft Edge
- Exodus, Atomic Wallet, Electrum
- Telegram Desktop

---

## Deployment

All deployment configuration lives in a `.env` file — no hardcoded paths, no editing the script.

### Step 1 — Clone and configure

```bash
git clone https://github.com/sakshamtushar/caldera-threat-emulations.git
cd caldera-threat-emulations/raccoon-stealer-v2

# Create your local config from the template
cp .env.example .env
```

Edit `.env` with your values. See `.env.example` for full documentation of every variable.

> `.env` is gitignored and will never be committed.

### Option A — Standard (non-Docker)

```ini
# .env
CALDERA_HOME=/opt/caldera
DOCKER_MODE=false
```

```bash
chmod +x deploy_to_caldera.sh
./deploy_to_caldera.sh
# Script will remind you to restart Caldera after copying files
```

### Option B — Docker

```ini
# .env
DOCKER_MODE=true
DOCKER_CONTAINER=caldera-caldera-1
DOCKER_CALDERA_WORKDIR=/usr/src/app
```

```bash
chmod +x deploy_to_caldera.sh
./deploy_to_caldera.sh
# Script automatically runs docker cp, docker exec mkdir, and docker restart
```

### Override without .env

Exported environment variables take precedence over `.env`:

```bash
export CALDERA_HOME=/opt/caldera
./deploy_to_caldera.sh
```

---

## Running the Emulation

1. **Open Caldera** web UI
2. **Deploy agent** — Agents tab → Deploy Sandcat on your Windows VM
3. **Create operation** — Operations tab → New Operation
   - **Adversary:** `Raccoon Stealer v2`
   - **Planner:** `atomic`
   - **Autonomous:** Yes
4. **Click Start** and monitor execution

---

## Detection Rules

Seven Sigma rules are included in `detection_rules/raccoon_sigma_rules.yml` covering:

| Rule | Technique | Level |
|------|-----------|-------|
| MachineGuid Registry Access | T1012 | Medium |
| Browser Credential File Access | T1555.003 | High |
| Cryptocurrency Wallet Discovery | T1005 | High |
| Telegram Cache Access | T1213 | High |
| Screenshot via BitBlt | T1113 | Low |
| System Info File Creation | T1560 | Medium |
| sqlite3/nss3 DLL Loaded by Non-Browser | T1105 | Medium |

Compatible with Splunk, Elastic, and any Sigma-supported SIEM.

---

## Targeted Applications

**Browsers:** Chrome, Firefox, Edge, Opera

**Crypto Wallets:** Bitcoin, Exodus, Atomic, Electrum, Electrum-LTC, ElectrumCash, JaxxLiberty, Coinomi, Guarda, Binance, BlockstreamGreen, Ledger, Daedalus, MyMonero, Monero, Wasabi

**Browser Extension Wallets:** MetaMask, TronLink, BinanceChain, Ronin, XDEFI, WavesKeeper, Solflare, Rabby, Coinbase, Phantom, Brave Wallet, MEW CX, Keplr, Terra Station, TON

**Messaging:** Telegram Desktop

---

## References

- [MITRE ATT&CK — Raccoon Stealer (S1148)](https://attack.mitre.org/software/S1148/)
- [Sekoia — Raccoon Stealer v2 In-Depth Analysis](https://blog.sekoia.io/raccoon-stealer-v2-part-2-in-depth-analysis/)
- [S2W TALON — Raccoon Stealer is Back with a New Version](https://medium.com/s2wblog/raccoon-stealer-is-back-with-a-new-version-5f436e04b20d)
- [Malpedia — win.raccoon](https://malpedia.caad.fkie.fraunhofer.de/details/win.raccoon)
- [DOJ Indictment — Raccoon Stealer Operator](https://www.justice.gov/usao-wdtx/pr/newly-unsealed-indictment-charges-ukrainian-national-international-cybercrime-operation)

---

## Disclaimer

This emulation plan is intended for **authorized security testing only**. Use only in lab environments or against systems you own or have explicit written permission to test.
