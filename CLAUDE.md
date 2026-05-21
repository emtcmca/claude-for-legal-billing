<!--
CONFIGURATION LOCATION

User-specific configuration for this plugin lives at a version-independent path that survives plugin updates:

  ~/.claude/plugins/config/claude-for-legal/billing/CLAUDE.md

Rules for every skill, command, and agent in this plugin:
1. READ configuration from that path. Not from this file.
2. If that file does not exist or still contains [PLACEHOLDER] markers, STOP before doing substantive work. Say: "This plugin needs setup before it can give you useful output. Run /billing:cold-start-interview — it takes about 10 minutes and every command in this plugin depends on it." Do NOT proceed with placeholder or default configuration. The only skill that runs without setup is /billing:cold-start-interview itself.
3. Setup and cold-start-interview WRITE to that path, creating parent directories as needed.
4. On first run after a plugin update, if a populated CLAUDE.md exists at the old cache path but not at the config path, copy it forward before proceeding.
5. This file (the one you are reading) is the TEMPLATE. It ships with the plugin and is replaced on every update. Never write user data here.

**Billing data path.** All time entries, client profiles, attorney profiles, and invoices live at the path specified in `## Billing data` below. For solo use this is `~/.claude/plugins/config/claude-for-legal/billing/`. For firm use it points to a shared OneDrive or network folder. Every skill reads and writes to that path — never to the config path or the cache path.

**Shared company profile.** Firm name, address, and size come from `~/.claude/plugins/config/claude-for-legal/company-profile.md` — shared across all plugins. If it doesn't exist, cold-start-interview will create it.
-->

# Billing Practice Profile

*This file is written by the cold-start interview on first run. Until then, it's
a template. If you're seeing `[PLACEHOLDER]` values below, run `/billing:cold-start-interview`.*

*Once populated: edit this file directly. Every skill reads it before doing anything.*

---

## Firm billing info

**Firm name:** [PLACEHOLDER]
**Billing address:** [PLACEHOLDER]
**Billing email:** [PLACEHOLDER]
**Remittance instructions:** [PLACEHOLDER — e.g., "Net 30. Payment by check or ACH. See invoice for details."]

*(Firm name syncs from `company-profile.md`. Edit there to update across all plugins.)*

---

## Billing data

**Data path:** [PLACEHOLDER — `~/.claude/plugins/config/claude-for-legal/billing/` for solo; shared OneDrive/network path for firms]

*Every skill reads and writes to this path. To move billing data to a shared folder, update this path and move the existing `attorneys/`, `clients/`, `time-register.yaml`, and `invoices/` directories there.*

---

## Attorneys

*One entry per attorney who uses this plugin. Slug is lowercase-hyphenated. Add or update via `/billing:rate-card` or directly here.*

```yaml
# attorneys/[slug].yaml — created by cold-start-interview for each attorney
# Example:
#   slug: alice-jones
#   name: Alice Jones
#   email: alice@firm.com
#   default_rate: 350
#   billing_increment: 0.1   # 0.1 = 6-minute minimum; 0.2 = 12-minute
#   rate_overrides:
#     acme-corp: 325
#     beta-llp: 400
```

[PLACEHOLDER — attorney profiles added at cold-start]

---

## Invoice settings

**Invoice prefix:** [PLACEHOLDER — e.g., INV or BILL]
**Next invoice number:** [PLACEHOLDER — e.g., 001]
**Task codes:** [PLACEHOLDER — required | optional | hidden]
**Date format on invoices:** YYYY-MM-DD

---

## Panel settings

**Billing panel at end of session:** [PLACEHOLDER — enabled | disabled]
**Auto-detect active matter:** [PLACEHOLDER — enabled | disabled]
**Budget warning threshold:** [PLACEHOLDER — 75 (percent)]

---

## Notes

[PLACEHOLDER — any firm-specific billing rules, e.g., "minimum 0.2h per task for litigation matters" or "all invoices require partner approval before sending"]
