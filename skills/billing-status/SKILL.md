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
2. Check each installed plugin's active matter by reading its practice-level `CLAUDE.md` at `~/.claude/plugins/config/claude-for-legal/<plugin>/CLAUDE.md`. Check these plugins in order: `commercial-legal`, `ip-legal`, `corporate-legal`, `ai-governance-legal`, `product-legal`, `litigation-legal`. For each, look for a line matching the pattern `Active matter: <slug>` where `<slug>` is not the literal word `none` and not the phrase `none — practice-level context only`. The first non-none slug found is the active matter.
3. Once the active matter slug and plugin are known, read the matter's context file at `~/.claude/plugins/config/claude-for-legal/<plugin>/matters/<slug>/matter.md`. Parse the `**Client:**` line to get the client display name, and derive a client slug from it (lowercase-hyphenated). If `matter.md` is not found, use the matter slug itself as the client identifier.
4. Look up `[billing_data_path]/clients/<client-slug>.yaml`. If the file does not exist, proceed with the display name from `matter.md` and note in the panel that no billing profile exists for this client yet (offer to create one via `/billing:time-entry`).

If no active matter is found and `--session-end` was passed, show a minimal panel asking which client to log against.

### 3. Determine session time (--session-end only)

When triggered with `--session-end`:

1. **Locate the session timer file.** Timer files live at `[billing_data_path]/.sessions/[attorney-slug]_[session-id]` — one file per session per attorney, so multiple attorneys sharing the same data path do not interfere.
   - When triggered by the Stop hook's block decision, the reason text contains `Session timer: [path]`. Extract the exact path from that context and use it.
   - When invoked manually (no path in context), scan `[billing_data_path]/.sessions/` for files matching `[active-attorney-slug]_*` modified in the last 24 hours. Use the most recently modified.
   - If no file is found either way, prompt: "How long was this session? (Enter as hours like `0.8` or minutes like `48m`)" and hold `session_file = null`.
2. If a timer file was found, read its Unix timestamp, compute elapsed minutes, round UP to the next 0.1h increment:
   - 1–6 min → 0.1h
   - 7–12 min → 0.2h
   - 13–18 min → 0.3h
   - ... (ceiling division: `ceil(minutes / 6) × 0.1`)
3. Hold the computed elapsed time AND the session file path in memory. Do NOT delete the file yet — deletion happens only after a terminal decision (log or skip). Edit, switch-client, and cancel paths leave the file intact so the Stop hook can re-prompt.

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

- **User types a narrative + `log`** (or just types a narrative and presses enter): Ask for task code if `Task codes: required` or `optional` in config. If optional: "Task code? (L100/L200/etc., or press enter to skip)". Then write the entry directly (do not delegate to `/billing:time-entry`, which is `disable-model-invocation`):
  1. Generate an entry ID: `te-YYYY-MMDD-NNN` (NNN = next sequential number for the day, zero-padded).
  2. Read `[billing_data_path]/time-register.yaml`; if the file is empty or comment-only, treat as an empty list.
  2a. **Duplicate check** — scan existing entries for any with the same `attorney`, `client`, `matter_slug`, and `date` (today). If found, warn before proceeding: "There is already a time entry for [attorney] on [client] / [matter] today: '[existing narrative]' ([existing hours]h). Is this a separate billable activity or a duplicate? [Continue / Cancel]" If the attorney cancels, return to the panel without deleting the session timer file.
  3. Append a new top-level list item at the end of the file (each item starts with `- id:` at column 0):
     ```yaml
     - id: [id]
       date: [YYYY-MM-DD]
       attorney: [attorney-slug]
       client: [client-slug]
       matter_slug: [matter-slug or null]
       plugin: [active-plugin or null]
       hours: [rounded-hours]
       rate: [rate]
       amount: [hours * rate, 2 decimal places]
       task_code: [code or null]
       narrative: "[narrative]"
       status: pending
       invoice_id: null
       session_minutes_actual: [actual-elapsed-minutes]
       ai_cost_usd: null
       notes: null
     ```
  4. Delete the session timer file identified in step 3 (the specific `[billing_data_path]/.sessions/[attorney-slug]_[session-id]` path). If no file path was held (manual hour entry), do nothing.
- **User types `edit hours/rate`**: Ask which value to change, then re-display panel. Do NOT delete the session timer file.
- **User types `skip`**: Delete the session timer file (same path as above) so the Stop hook does not block again on the next stop attempt. Confirm "OK — session not logged. You can log it later with `/billing:time-entry`."
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
