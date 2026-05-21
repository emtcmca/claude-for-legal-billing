---
name: billing-status
description: >
  Show the current billing state — active client, hours logged today, WIP for the
  active matter, and budget status. Also serves as the end-of-session billing panel
  when triggered by the Stop hook. Use when checking billing state, logging time at
  end of a session, or switching clients.
argument-hint: "[--session-end to show the end-of-session panel | --client <slug> to view a specific client]"
---

# /billing:billing-status

## When this runs

Manually (`/billing:billing-status`), or triggered by the Stop hook at end of session with `--session-end`. With `--client <slug>`, shows status for that client even if a different one is active.

## Instructions

### 1. Read config

Read `~/.claude/plugins/config/claude-for-legal/billing/CLAUDE.md`. If it has `[PLACEHOLDER]` values, say: "Billing setup isn't complete yet. Run `/billing:cold-start-interview` first." Stop.

Get `billing_data_path` from the config.

### 2. Determine active client and matter

Check these sources in order (first match wins):

1. If `--client <slug>` was passed, use that client.
2. Check each installed plugin's active matter:
   - Read `~/.claude/plugins/config/claude-for-legal/commercial-legal/CLAUDE.md` → `Active matter:` line
   - Read `~/.claude/plugins/config/claude-for-legal/ip-legal/CLAUDE.md` → `Active matter:` line
   - Read `~/.claude/plugins/config/claude-for-legal/corporate-legal/CLAUDE.md` → `Active matter:` line
   - Read any other installed plugin CLAUDE.md that has an `Active matter:` line
   - The first non-`none` value found is the active matter slug.
3. Read the matter slug's `matter.md` file (from the relevant plugin's matters folder) to get the client name.
4. Look up the client slug in `[billing_data_path]/clients/[slug].yaml`. If the client file doesn't exist yet, that's fine — note it in the panel.

If no active matter is found and `--session-end` was passed, show a minimal panel asking which client to log against.

### 3. Determine session time (--session-end only)

When triggered with `--session-end`:

1. Look for a session start file at `~/.claude/plugins/config/claude-for-legal/billing/.session-start`. This file is written by a `UserPromptSubmit` hook (described in the cold-start-interview).
2. If the file exists, read the timestamp, compute elapsed minutes, round UP to the next 0.1h increment:
   - 1–6 min → 0.1h
   - 7–12 min → 0.2h
   - 13–18 min → 0.3h
   - ... (ceiling division: `ceil(minutes / 6) × 0.1`)
3. If the file does not exist, prompt: "How long was this session? (Enter as hours like `0.8` or minutes like `48m`)"
4. Delete the `.session-start` file after reading.

### 4. Look up today's entries and WIP

Read `[billing_data_path]/time-register.yaml`.

Compute:
- **Today's hours** for the active attorney on the active client (entries with today's date and matching attorney slug)
- **WIP total** for the active client: sum of `amount` for all entries where `status: pending` or `status: approved` (not yet billed)
- **Budget status**: read `budget_cap` and `budget_billed` from the client YAML; add WIP to `budget_billed` for the running total; compute percentage.
- **Today's AI cost**: not tracked per session — show `[not tracked]` unless the session-start hook captures it (future feature)

### 5. Display the billing panel

**Standard panel (no --session-end):**

```
┌─────────────────────────────────────────────────────────────┐
│  BILLING  [Client Name]  /  [matter-slug]                   │
│  Today: [N]h logged   WIP: $[N]   Rate: $[N]/hr             │
│  Budget: $[billed] of $[cap] ([pct]%)  [warning if ≥ 75%]   │
└─────────────────────────────────────────────────────────────┘
```

If there's no budget cap, omit the budget line.

If the client has `arrangement: flat-fee`, show: `[Flat fee matter — time tracked for records only]` instead of the rate and WIP dollar amounts.

**End-of-session panel (--session-end):**

```
┌─────────────────────────────────────────────────────────────────┐
│  SESSION BILLING  [Client Name]  /  [matter-slug]               │
│  Session: [actual min] min  →  [rounded]h (6-min increments)    │
│  [Attorney Name]  ·  $[rate]/hr  →  $[amount]                   │
│  Budget: $[billed] of $[cap] ([pct]%)  [⚠ if ≥ 75%]            │
│─────────────────────────────────────────────────────────────────│
│  Describe the work (required for billing):                      │
│  >                                                              │
│─────────────────────────────────────────────────────────────────│
│  [log]  edit hours/rate  skip  switch client                    │
└─────────────────────────────────────────────────────────────────┘
```

Wait for the attorney's response:

- **User types a narrative + `log`** (or just types a narrative and presses enter): Ask for task code if `Task codes: required` or `optional` in config. If optional: "Task code? (L100/L200/etc., or press enter to skip)". Then call the time-entry skill to write the record.
- **User types `edit hours/rate`**: Ask which value to change, then re-display panel.
- **User types `skip`**: Confirm "OK — session not logged. You can log it later with `/billing:time-entry`."
- **User types `switch client`**: Ask which client, update the active client, and re-display the panel for the new client.

### 6. Budget warnings

If budget percentage ≥ 90%:
> ⛔ Budget: $[billed] of $[cap] — [pct]% used. [Client] is near the ceiling. Consider discussing a revised estimate before logging more time.

If budget percentage ≥ 75% but < 90%:
> ⚠ Budget: $[billed] of $[cap] — [pct]% used. Consider flagging this to the client.

### 7. After logging (session-end only)

After writing the time entry, show a brief confirmation:

> ✓ Logged: [hours]h to [Client Name] / [matter-slug] — status: pending
> Total WIP for [Client Name]: $[new WIP total]

Then stop. Do not offer to generate an invoice — that's for `/billing:wip-review` and `/billing:invoice-generate`.

## What this skill does not do

- Generate invoices — use `/billing:invoice-generate`
- Review or approve pending entries — use `/billing:wip-review`
- Show cross-client or cross-attorney reports — use `/billing:billing-report`
