# Workflow: Planning, Orchestration, and Dependencies

---

## 1. Plan-First Protocol

**For any non-trivial task, enter plan mode before writing code.**

### The Protocol

1. **Enter Plan Mode** — use `EnterPlanMode`
2. **Check MEMORY.md** — read any relevant entries
3. **Requirements Specification (for complex/ambiguous tasks)** — see below
4. **Draft the plan** — what changes, which files, in what order
5. **Save to disk** — write to `quality_reports/plans/YYYY-MM-DD_short-description.md`
6. **Present to user** — wait for approval
7. **Exit plan mode** — only after approval
8. **Save initial session log** — capture goal and key context while fresh
9. **Implement via orchestrator** — see Section 2

### Requirements Specification (For Complex/Ambiguous Tasks)

**When to use:** Task is high-level/vague, multiple valid interpretations, significant effort (>3 files).
**When to skip:** Task is clear and specific, simple single-file edit.

**Protocol:**
1. Clarify ambiguities (max 3-5 questions)
2. Create spec marking requirements MUST / SHOULD / MAY
3. Declare clarity: CLEAR / ASSUMED / BLOCKED
4. Get user approval, then draft plan

### Plans on Disk

Plans survive context compression. Save every plan to:
```
quality_reports/plans/YYYY-MM-DD_short-description.md
```

---

## 2. The Orchestrator Loop

**After a plan is approved, the orchestrator takes over autonomously.**

### The Dependency-Driven Loop

```
Plan approved → orchestrator activates
  │
  Step 1: IDENTIFY — Check dependency graph, determine which phases can activate
  │
  Step 2: DISPATCH — Launch worker agents (parallel when independent)
  │         Each worker paired with its critic (see agents.md)
  │
  Step 3: REVIEW — Critic evaluates worker output, produces score
  │         If score < 80 → worker fixes → critic re-reviews (max 3 rounds)
  │         If 3 rounds fail → ESCALATE (see agents.md)
  │
  Step 4: VERIFY — Compile, render, run code, check outputs
  │         If verification fails → fix → re-verify (max 2 attempts)
  │
  Step 5: SCORE — Aggregate scores across components (see quality.md)
  │
  └── Score >= threshold?
        YES → Present summary to user
        NO  → Identify blocking components, loop back to Step 2
              After max 5 overall rounds → present with remaining issues
```

### Agent Dispatch Rules

| Task Involves | Agents Dispatched |
|--------------|-------------------|
| Literature/references | librarian + librarian-critic |
| Data sourcing | explorer + explorer-critic |
| Data preparation | data-engineer + coder-critic |
| Viability screening | viability-screener (no critic) |
| Argument architecture | architect (×5) → architect-critic → data-auditor → decider → executor |
| Identification strategy | strategist + strategist-critic |
| R/Python scripts | coder + coder-critic |
| Paper manuscript | writer → prose-critic → writer-critic |
| Peer review | editor → domain-referee + methods-referee |
| Compilation only | verifier (standard mode) |

### Parallel Dispatch

Independent phases run concurrently:
- Literature and Data discovery run in parallel
- 5 architect lenses run in parallel
- 7 extension agents run in parallel
- Code and Paper can run in parallel (after Strategy)

### Limits

- **Worker-critic pairs:** max 3 rounds (then escalate)
- **Overall loop:** max 5 rounds
- **Verification retries:** max 2 attempts
- Never loop indefinitely

### Simplified Mode (R Scripts / Explorations)

For standalone R scripts and explorations — use the simplified loop:
```
Plan approved → implement → run code → check outputs → score → done
```
No multi-agent reviews. Just: write, test, verify quality >= 80.

### "Just Do It" Mode

When user says "just do it" / "handle it":
- Skip final approval pause
- Auto-commit if score >= 80
- Still run the full verify-review-fix loop

---

## 3. Dependency Graph (7 Phases)

**Phases activate by dependency, not sequence. Research is not a waterfall.**

### Phase Dependencies

| Phase | Requires | Can Re-enter? |
|-------|----------|---------------|
| Discovery | Research idea | Always — librarian is persistent |
| Data Preparation | Discovery (data assessment) | Yes — new data sources trigger re-wrangling |
| Viability | Data Preparation (data_wrangle.md + key_variables.md) | No — one-time gate |
| Strategy/Architecture | Discovery (lit) + Viability PASS | Yes — new findings can trigger re-strategy |
| Analysis | Strategy/Architecture decision (>= 80) | Yes — strategy revision triggers re-coding |
| Writing | Analysis approved (coder-critic >= 80) | Yes — new results trigger rewriting |
| Review/Polish | Writing approved (writer-critic >= 80) | Yes — major revisions loop back |

### How It Works

The Orchestrator checks the dependency graph before dispatching any agent. If a phase's inputs are satisfied, it can activate — regardless of whether earlier phases are "complete."

**Example — entering mid-pipeline:**
You already have data and a strategy. Enter at Analysis (skip Discovery/Strategy). The Orchestrator checks dependencies, not phase numbers.

**Example — targeted re-entry:**
A referee says "control for X." Orchestrator routes back to coder (not through the full pipeline), coder-critic reviews, writer updates, writer-critic reviews, then back to peer review.

---

## 4. Standalone Access

**Any skill can be invoked directly, bypassing the pipeline.**

### Two Modes

**Mode 1: Orchestrated (within the pipeline)**
The Orchestrator dispatches agents through the dependency graph automatically.

**Mode 2: Standalone (direct access)**
The user invokes a skill directly: `/strategize manuscript/04-results-ate.qmd`
This runs the agent(s) alone, right now, no phase dependencies.

### Standalone Skills

| Skill | What It Does |
|-------|-------------|
| `/discover` | Literature search + data discovery |
| `/wrangle` | Data preparation pipeline |
| `/viability` | Viability screening |
| `/architect` | Multi-lens argument architecture |
| `/strategize` | Identification strategy design + review |
| `/analyze` | End-to-end data analysis |
| `/write` | Draft paper sections + humanizer pass |
| `/review` | Simulated peer review / code review / methods audit |
| `/revise` | R&R routing per revision protocol |
| `/submit` | Final gate: score >= 95, all components >= 80 |
| `/tools` | Utilities (compile, validate-bib, format-tables) |

### Constraint

`/new-project` is the only skill that is always orchestrated — it launches the full pipeline.

---

## 5. Codex CLI Integration

For tasks requiring deep research or parallel analysis, Codex CLI can be invoked:

```bash
codex --quiet --full-auto "prompt here" 2>&1
```

**When to use Codex:**
- `/discover lit` — broad literature search (Codex for breadth, Claude for depth)
- `/analyze --dual` — dual-agent analysis (Claude + Codex produce independent R scripts)
- Codex outputs are saved with `cx_` prefix

**Not required** — the system works Claude-only. Codex is an optional enhancement decided per-project at setup.

---

## 6. Context Management

### General Principles
- Prefer auto-compression over `/clear`
- Save important context to disk before it's lost

### Context Survival Strategy

**Before Auto-Compression:**
1. MEMORY.md has all entries from this session
2. Session log is current
3. Active plan is saved to disk
4. Open questions documented in session log

**After Compression:**
First message: "Resuming after compression. Last task: [read most recent plan + git log]. Status: [next step]."

### Session Recovery

After compression or new session:
1. Read `CLAUDE.md` + most recent plan in `quality_reports/plans/`
2. Check `git log --oneline -10` and `git diff`
3. State what you understand the current task to be
