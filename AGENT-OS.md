## Agent OS

This project uses [Agent OS](https://github.com/buildermethods/agent-os) (by Builder Methods) — a spec-first AI workflow framework for Claude Code. It gives the AI persistent project context through **standards files** and **slash commands**, so every feature starts as an approved plan before any code is written.

---

### Prerequisites

| Requirement | Install |
|---|---|
| Git 2.x | `xcode-select --install` (macOS) / `sudo apt install git` (Linux) |
| Bash 4+ | `brew install bash` — macOS ships with 3.x which is too old |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |
| GitHub CLI (optional) | [cli.github.com](https://cli.github.com) — needed for issue-driven specs |

---

### First-Time Setup (new machine)

1. Clone the Agent OS base:

    ```bash
    git clone https://github.com/buildermethods/agent-os.git ~/agent-os
    ```

2. Install into this project (run from the project root):

    ```bash
    bash ~/agent-os/scripts/project-install.sh
    ```

    With a corporate profile:

    ```bash
    bash ~/agent-os/scripts/project-install.sh --profile your-org
    ```

3. The `agent-os/` and `.claude/commands/agent-os/` directories are already committed — you do not need to re-run discovery or re-bootstrap. Just refresh the commands after cloning:

    ```bash
    bash ~/agent-os/scripts/project-install.sh --commands-only
    ```

> **macOS Bash note:** If the install script errors, invoke it explicitly with the Homebrew bash:
> `  /opt/homebrew/bin/bash ~/agent-os/scripts/project-install.sh`

---

### Daily Workflow

**At the start of every session**, inject relevant standards into Claude's context:

```
/inject-standards
```

**Before implementing any feature**, enter plan mode (`Shift+Tab` in Claude Code) and run:

```
/shape-spec
```

Claude will ask clarifying questions, then save a spec folder under `agent-os/specs/` containing a `plan.md`, `shape.md`, `standards.md`, and `references.md`. Implementation only begins after you type **approve**.

> **Never skip the spec.** The plan-first model is what keeps the AI aligned with project standards. Jumping straight to implementation bypasses this.

---

### Slash Commands Reference

| Command | When to use |
|---|---|
| `/inject-standards` | Start of every session — loads relevant standards into context |
| `/shape-spec` | Before any new feature — must be run in plan mode (`Shift+Tab`) |
| `/discover-standards` | When you want to document a new codebase pattern as a standard |
| `/index-standards` | After editing any standard file — rebuilds `standards/index.yml` |
| `/plan-product` | One-time setup — defines mission, roadmap, and tech stack for the AI |

---

### Correcting a Spec

When implementation goes wrong, diagnose the failure mode before touching anything:

| Failure mode | Symptom | Fix |
|---|---|---|
| **Wrong plan** | Tasks out of order, missing steps | Edit `agent-os/specs/<spec>/plan.md` directly |
| **Wrong standard** | AI followed a rule that produced the wrong pattern | Edit the standard in `agent-os/standards/`, then run `/index-standards` |
| **Wrong scope** | Requirements shifted after shaping | Run `/shape-spec` again — keep the old spec as a historical record |

After any correction, reinject standards before resuming:

```
/inject-standards
```

To correct a single task mid-implementation, tell Claude explicitly:

```
Task 4 didn't work because [reason]. Please redo Task 4 with [constraint]. Do not touch Tasks 1–3.
```

Then update `plan.md` to reflect what was actually built.

---

### What to Commit

| Path | Commit? |
|---|---|
| `agent-os/standards/` | Yes |
| `agent-os/standards/index.yml` | Yes |
| `agent-os/product/` | Yes |
| `agent-os/specs/` | Yes — specs are living documentation |
| `.claude/commands/agent-os/` | Yes |

---

### References

| Resource | Link |
|---|---|
| Agent OS repository | [github.com/buildermethods/agent-os](https://github.com/buildermethods/agent-os) |
| Claude Code CLI | [anthropic.com/claude-code](https://www.anthropic.com/claude-code) |
| GitHub CLI | [cli.github.com](https://cli.github.com) |

