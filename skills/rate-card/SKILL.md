---
name: rate-card
description: >
  View and update billing rates — default hourly rates per attorney, client-specific
  overrides, billing arrangements (hourly, flat fee, contingency), and billing
  increments. Use when onboarding a new client, renegotiating a rate, or reviewing
  what rates are configured.
argument-hint: "[--attorney <slug>] [--client <slug>] [list | set | override]"
---

# /billing:rate-card

## When this runs

Attorney wants to view or update rates. Subcommands: `list`, `set`, `override`.

## Instructions

### 1. Read config

Read `~/.claude/plugins/config/claude-for-legal/billing/CLAUDE.md`. Get `billing_data_path`. Check for placeholders — if present, stop and direct to cold-start.

### 2. Dispatch on subcommand

Parse `$ARGUMENTS`. First token is the subcommand.

---

### `list` (default if no subcommand)

Show the current rate configuration in a readable table.

Read all files in `[billing_data_path]/attorneys/`. For each attorney, show:
- Default rate
- Billing increment
- All client-specific overrides

Then read all files in `[billing_data_path]/clients/`. For each client, show:
- Billing arrangement
- Budget cap
- Which attorney has a client-specific override (and what it is)

Output:

```markdown
## Rate Card

### Attorneys

| Attorney | Default Rate | Increment | Client Overrides |
|---|---|---|---|
| Alice Jones | $350/hr | 0.1h (6 min) | Acme Corp: $325/hr |
| Bob Smith | $275/hr | 0.1h (6 min) | — |

### Clients

| Client | Arrangement | Budget Cap | Notes |
|---|---|---|---|
| Acme Corp | Hourly | $15,000 | Prefers monthly invoices |
| Beta LLP | Flat fee | — | $5,000 flat for trademark search |
```

---

### `set --attorney <slug>`

Update an attorney's default rate or billing increment.

1. Read `[billing_data_path]/attorneys/[slug].yaml`. If not found, list available attorneys.
2. Show current values.
3. Ask what to change: rate, increment, or both.
4. Write updated YAML. Confirm before writing.

After writing:
> Rate updated for [name]. New entries will use the new rate. Existing pending entries are not affected — to adjust them, use `/billing:wip-review`.

---

### `override --attorney <slug> --client <slug>`

Set or update a client-specific rate override for an attorney.

1. Read the attorney YAML. Read the client YAML.
2. Show the current override if one exists.
3. Ask: "Rate for [attorney] on [client] matters: $___/hr (press enter to remove override and use default)"
4. Write the update.

Also ask: "Is this a special billing arrangement for this client?"
- If yes, offer to update the client's `arrangement` field (hourly | flat-fee | contingency | no-charge | courtesy).
- If flat-fee: ask for the flat amount and update `budget_cap` in the client YAML with a note.

---

### `override --client <slug>`

Update client-level settings: billing arrangement, budget cap, retainer balance.

1. Read `[billing_data_path]/clients/[slug].yaml`. If not found, offer to create a new client profile.
2. Show current values.
3. Ask what to change.

**Changing arrangement to flat-fee:**
> Setting a flat-fee arrangement means the billing panel will still track time for your records, but will not show hourly calculations. The flat amount should be set as the budget cap. Confirm?

**Changing arrangement to contingency:**
> Contingency matters: time is tracked for records, but the rate is $0 (no fees until settlement or verdict). Budget warnings are suppressed. Confirm?

**Updating budget cap:**
- Show current amount and running WIP total.
- Warn if the new cap is below the current WIP total.

---

## Billing arrangements

| Arrangement | How billing panel behaves | Invoice shows |
|---|---|---|
| `hourly` | Shows hours × rate = amount | Hours, rate, and amount |
| `flat-fee` | Shows hours tracked; no dollar math | Hours only (dollar line reads "Flat fee matter") |
| `contingency` | Shows hours tracked; $0 rate | Hours only (dollar line reads "Contingency matter — no current fees") |
| `no-charge` | Panel suppressed unless `--force` | Not billable |
| `courtesy` | Panel shows time; notes courtesy status | Hours only with "Courtesy — not billed" note |

---

## What this skill does not do

- Create attorney profiles from scratch — that's in `/billing:cold-start-interview`
- Create client profiles from scratch — that's in `/billing:time-entry` (on first entry for a new client) or `/billing:customize`
- Show or generate invoices — use `/billing:invoice-generate`
