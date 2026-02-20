# Caldera Threat Emulations

A collection of adversary emulation plans for [MITRE Caldera](https://github.com/mitre/caldera), designed for purple team exercises, threat simulation, and security control validation.

Each plan maps real-world malware or threat actor behavior to MITRE ATT&CK techniques and provides ready-to-import Caldera abilities, adversary profiles, and Sigma detection rules.

---

## Emulation Plans

| Adversary | Type | MITRE ID | Techniques | Platform |
|-----------|------|----------|------------|----------|
| [Raccoon Stealer v2](./raccoon-stealer-v2/) | Infostealer / MaaS | S1148 | 20+ | Windows |

> More plans coming soon. Contributions welcome — see [Contributing](#contributing).

---

## Repository Structure

```
caldera-threat-emulations/
└── <adversary-name>/
    ├── README.md               # Threat profile, TTPs, usage instructions
    ├── deploy_to_caldera.sh    # One-command deployment script
    ├── adversaries/
    │   └── *.yml               # Caldera adversary profile
    ├── abilities/
    │   └── *.yml               # Individual ATT&CK technique abilities
    └── detection_rules/
        └── *.yml               # Sigma detection rules
```

---

## Quick Start

### Prerequisites
- [MITRE Caldera](https://github.com/mitre/caldera) 5.x (self-hosted or Docker)
- A Windows target VM with a Caldera agent (Sandcat) deployed
- PowerShell 5.1+ on the target

### Deploy an Emulation Plan

**Option A — Direct (non-Docker)**
```bash
git clone https://github.com/sakshamtushar/caldera-threat-emulations.git
cd caldera-threat-emulations/<plan-name>
export CALDERA_HOME=/path/to/caldera
chmod +x deploy_to_caldera.sh
./deploy_to_caldera.sh
# Restart Caldera to load new abilities
```

**Option B — Docker**
```bash
git clone https://github.com/sakshamtushar/caldera-threat-emulations.git
CONTAINER="your-caldera-container-name"

# Copy abilities
docker exec "$CONTAINER" mkdir -p /usr/src/app/data/abilities/<plan-name>
docker cp <plan-name>/abilities/. "$CONTAINER":/usr/src/app/data/abilities/<plan-name>/
docker cp <plan-name>/adversaries/. "$CONTAINER":/usr/src/app/data/adversaries/

# Restart container
docker restart "$CONTAINER"
```

### Run an Operation
1. Open Caldera web UI
2. Go to **Agents** → Deploy a Sandcat agent on your Windows VM
3. Go to **Operations** → Create new operation
4. Select the imported adversary profile
5. Click **Start**

---

## Disclaimer

> These emulation plans are intended for **authorized security testing only** — purple team exercises, lab environments, and security control validation against systems you own or have explicit written permission to test.
>
> Do **not** use against systems without authorization. The authors accept no responsibility for misuse.

---

## Contributing

Contributions are welcome. To add a new emulation plan:

1. Fork this repository
2. Create a new directory: `<adversary-name>/`
3. Follow the existing structure (abilities, adversaries, detection_rules, README, deploy script)
4. Ensure all ability IDs are unique UUIDs
5. Include a `README.md` with threat profile, TTP table, and usage instructions
6. Open a pull request

---

## References

- [MITRE ATT&CK](https://attack.mitre.org/)
- [MITRE Caldera Docs](https://caldera.readthedocs.io/)
- [Sigma Rules](https://github.com/SigmaHQ/sigma)

---

## License

[MIT](./LICENSE) © 2025 Saksham Tushar
