# Axios npm Supply Chain - Elasticsearch EQL Queries
# These queries validate detection of the Axios npm supply chain attack TTPs
# Run against .ds-logs-endpoint.events.* indices via Kibana Dev Tools or ES|QL API

# ============================================================
# T1195.002 - Supply Chain Compromise: Software Supply Chain
# ============================================================
# Detects: npm package discovery phase - looking for compromised axios versions

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*package.json*"
  AND process.command_line LIKE "*plain-crypto-js*"
| KEEP @timestamp, host.name, process.name, process.command_line, user.name
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# T1083 - File and Directory Discovery: postinstall scripts
# ============================================================
# Detects: postinstall script enumeration checking for suspicious patterns

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*axios_postinstall*"
| KEEP @timestamp, host.name, process.name, process.command_line
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# T1105 - Ingress Tool Transfer: RAT download from C2
# ============================================================
# Detects: C2 contact to sfrclak.com on port 8000 (simulated)

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*sfrclak*"
  AND process.command_line LIKE "*8000*"
| KEEP @timestamp, host.name, process.name, process.command_line
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# T1547.001 - Boot or Logon Autostart Execution: Registry Run Keys
# ============================================================
# Detects: MicrosoftUpdate registry key persistence check

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*MicrosoftUpdate*"
| KEEP @timestamp, host.name, process.name, process.command_line
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# T1070.004 - Indicator Removal: Artifact deletion
# ============================================================
# Detects: Cleanup of staging artifacts (wt.exe, vbs, ps1 files)

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*Remove-Item*"
  AND (process.command_line LIKE "*wt.exe*"
    OR process.command_line LIKE "*6202033*"
    OR process.command_line LIKE "*axios_*")
| KEEP @timestamp, host.name, process.name, process.command_line
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# T1104 - Multi-Stage DNS - C2 Beacon Simulation
# ============================================================
# Detects: C2 beacon with IE8 User-Agent to sfrclak.com

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*SIMULATED*"
  AND process.command_line LIKE "*sfrclak*"
  AND process.command_line LIKE "*C2*"
| KEEP @timestamp, host.name, process.name, process.command_line
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# T1005 - Data from Local System: Exfil staging
# ============================================================
# Detects: Staging directory creation for exfiltration

FROM .ds-logs-endpoint.events.process-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND process.name LIKE "*powershell*"
  AND process.command_line LIKE "*axios_exfil*"
  AND process.command_line LIKE "*hostname.txt*"
| KEEP @timestamp, host.name, process.name, process.command_line
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# Network Connection Detection (if endpoint.network-* is indexed)
# ============================================================
# Detects: Outbound connection to known C2 infrastructure

FROM .ds-logs-endpoint.events.network-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND destination.port == 8000
  AND (destination.domain == "sfrclak.com"
    OR destination.domain == "callnrwise.com")
| KEEP @timestamp, host.name, process.name, destination.domain,
    destination.port, destination.address, network.direction
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# Registry Persistence Detection
# ============================================================
# Detects: Registry modification for MicrosoftUpdate Run key

FROM .ds-logs-endpoint.events.registry-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND registry.path LIKE "*MicrosoftUpdate*"
  AND registry.path LIKE "*Run*"
| KEEP @timestamp, host.name, registry.path, registry.action, user.name
| SORT @timestamp DESC
| LIMIT 50

# ============================================================
# File Creation Detection (RAT binary to ProgramData)
# ============================================================
# Detects: Binary written to ProgramData as wt.exe

FROM .ds-logs-endpoint.events.file-*
| WHERE host.name LIKE "*thorhq*" OR host.name LIKE "*DESKTOP*"
  AND file.path LIKE "*ProgramData*"
  AND file.name == "wt.exe"
| KEEP @timestamp, host.name, file.path, file.name, process.name
| SORT @timestamp DESC
| LIMIT 50
