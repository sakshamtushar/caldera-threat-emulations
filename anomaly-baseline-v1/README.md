# Anomaly Baseline v1 — Caldera Emulation Plan

> **Platform:** Windows | **Type:** Time-based baseline + deviation (content-pipeline support tool, not a real-world threat profile)

Purpose-built for validating the TH201 (Threat Hunting 201) Episode 5 "Anomaly Detection & Forecasting" ES|QL hunts against real telemetry. Unlike the other plans in this repo, this one doesn't emulate a specific named threat actor or malware family — it exists to produce a **baseline period followed by a deviation** on the same host, compressed into a single ~15-20 minute operation, so hunts that need a "normal for this host, over time" reference point have real data to compare against.

---

## Contents

```
anomaly-baseline-v1/
├── README.md
├── .env.example                          # Config template — copy to .env and fill in values
├── deploy_to_caldera.sh                  # Automated filesystem deployment script (reads .env)
├── adversaries/
│   └── anomaly_baseline.yml              # Caldera adversary profile (4 abilities, 4 phases)
└── abilities/
    ├── baseline_process_noise.yml        # Phase 1 — quiet steady-rate discovery noise
    ├── volume_spike_deviation.yml        # Phase 2 — same noise, ~10x the rate, tight burst
    ├── first_seen_powershell.yml         # Phase 3 — one encoded/hidden PowerShell invocation
    └── dns_trend_ramp.yml                # Phase 4 — DNS beacon frequency accelerating over time
```

`detection_rules/` is intentionally empty for this plan — it's a validation fixture for hunt queries already being written directly for the episode script, not a threat profile that needs its own Sigma coverage.

---

## What each phase feeds

| Phase | Ability | Feeds | Why |
|---|---|---|---|
| 1 | `anomaly-baseline-process-noise` | Hunt 5.1 | Establishes ~14 discovery-command launches spaced ~20-45s apart — the "normal" a rolling baseline learns from |
| 2 | `anomaly-volume-spike-deviation` | Hunt 5.1 | ~50 of the same commands in under 90s — the deviation a `BUCKET()`-based rolling avg/stddev hunt should flag |
| 3 | `anomaly-first-seen-encoded-powershell` | Hunt 5.2 | One `-EncodedCommand` + hidden-window PowerShell launch — deliberately scoped to a specific suspicious pattern, not "first ever powershell.exe" (see the ability file's header comment for why a raw first-seen-process hunt isn't realistic) |
| 4 | `anomaly-dns-trend-ramp` | Hunt 5.3 | DGA-style DNS queries with a shrinking interval (~47s → ~3s across 16 queries) — gives a hand-rolled `EVAL` trend/forecast query a real ramping signal, since ES|QL has no native forecast function |

## Compressed timeline, not real days

The lab can't wait multiple real days for a baseline to accrue. The whole baseline→deviation arc for each hunt runs inside one operation (phases run in `atomic_ordering` sequence), and each hunt's `BUCKET()` interval in the ES|QL query must be set to match this compressed window (minutes, not days) — not faked via backdated document timestamps.

## Usage

**Fast path (used for episode validation) — REST API, no server restart:**
See the repo's `CLAUDE.md` "Deploying/authoring abilities via the REST API" and "Triggering an Operation via the REST API" sections. Remember the critical gotcha documented there: multi-line PowerShell `command` strings get their newlines stripped in transit when created via the API — every command in this plan is already authored as a single semicolon-joined logical line for that reason.

**Filesystem path (for a durable/importable copy):**
```bash
cp .env.example .env   # set CALDERA_HOME or DOCKER_MODE
chmod +x deploy_to_caldera.sh
./deploy_to_caldera.sh
```
Then in the Caldera web UI: Agents → confirm the Windows 11 endpoint's Sandcat agent is checked in → Operations → new operation → adversary `Anomaly Baseline v1` → Start.

## Design principle

Simulation only — no real exfiltration, no destructive commands, nothing that leaves persistent filesystem artifacts (see each ability's `cleanup` block). Every phase's only footprint is normal-looking process launches and DNS queries, which is exactly the telemetry the paired ES|QL hunts are meant to analyze.
