<!--
DEVELOPER NOTE — this is the plugin template, not the user's config.

The user's active config lives at:
  ~/.claude/plugins/config/claude-for-legal/billing/CLAUDE.md

This file is the template that cold-start-interview copies to that path on first run.
It is replaced on every plugin update. User data must never be written here.

Runtime behavior (placeholder checks, config-path reads, data-path resolution) is
defined in each skill's SKILL.md, not in this template. Skills explicitly read from
the config path — they do not rely on this file being auto-loaded by Claude Code.
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
