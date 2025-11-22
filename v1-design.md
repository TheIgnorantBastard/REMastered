# REMastered v1 – Design Outline

## 1. Goals

- Treat REMastered as a **host-driven control plane** for reverse engineering DOS games.
- Support a workflow where you can:
  1. Drop in a game.
  2. Configure it via `game.json`.
  3. Let tools (manual, scripts, or Gemini CLI) drive analysis of:
     - **Static data** (files, formats, indexes).
     - **Runtime state** via **DOSBox-X MCP**.
     - **Code and symbols** via **Ghidra** (headless / scripted).
- Keep the toolkit **emulator- and RE-tool-agnostic** at the core, with clean adapters for DOSBox-X and Ghidra.

## 2. High-level architecture

### 2.1 Core RE toolkit (host-only)

The core should:

- Work entirely from the host without assuming any MCP/GUI.
- Be callable from:
  - PowerShell.
  - Gemini CLI.
  - CI / Docker environments.

Key components we keep / refine from v0:

- **Project config & structure**
  - `game.json` describing:
    - Original DOS root + entry EXE.
    - Docs and data paths.
    - Tool configs (optional).
  - Standard directories:
    - `Original/`, `Docs/`, `Data/`, `Tools/`, `Ghidra/`.

- **File indexing & docs**
  - `Generate_File_Index.ps1` → `Docs/Game_File_Index.md`, `Data/indexes/files.csv`.
  - `Docs/Templates/*` → format/checklist/master-doc templates.
  - `New-FormatDoc.ps1`, `Verify-FormatDoc.ps1` (format documentation helpers).

- **Logs & notes**
  - `Write-MasterLog.ps1` with categories (bootstrap, dump, session, ghidra, etc.).
  - `Open-SessionPrompt.ps1` → append to `Docs/Sessions/` + master log.
  - `Open-IdeaPrompt.ps1` / `Log-Brainstorm.ps1` → append to `Docs/Ideas.md` + master log.

- **Dumps & metadata lifecycle**
  - `Dump-Memory.ps1`:
    - Writes binary dumps under `Data/dumps/<stage>/` (incoming/working/archive).
    - Generates `<dump>.meta.json` with label, tags, notes, hash, history.
  - `Archive-Dump.ps1`:
    - Moves/copies dumps between stages, updates metadata.
  - `Summarize-Dumps.ps1`:
    - Produces `Docs/Dump_Summary.md` with per-stage totals & details.

- **CI / tooling glue**
  - `Run-CI.ps1`, `Summarize-MasterLog.ps1` as generic, host-only helpers.

> v1 requirement: **No core script should assume DOSBox-X or Ghidra is present.** All such assumptions must live in adapters.

### 2.2 DOSBox-X adapter (MCP control plane)

Goal: provide a small, explicit API to control DOSBox-X from the host using MCP.

#### 2.2.1 Config and startup

- Extend `Tools/configs/dosbox-x.default.conf` with MCP settings. Example (pseudo):

  ```ini
  [dosbox]
  # ... existing settings
  # MCP / remote control
  # mcp_listen = tcp:localhost:7777   ; example, depends on actual DOSBox-X options
  ```

- Document a **recommended startup command**, e.g.:

  ```powershell
  .\Tools\scripts\Start-DosboxMcp.ps1
  ```

  which would:

  - Build the effective config for the current game.
  - Launch DOSBox-X with MCP enabled.

#### 2.2.2 MCP client

- New script/module: `Tools/scripts/Dosbox-McpClient.ps1`.
- Responsibilities:
  - Connect to the configured MCP endpoint (TCP/pipe).
  - Expose simple cmdlets/functions:
    - `Invoke-DosboxMcpCommand` (low-level call).
    - `Pause-Dosbox`, `Resume-Dosbox`.
    - `Send-DosKeys` or `Send-DosCommand` (type text + Enter).
    - Optional: `Capture-DosScreenshot`, etc., if supported.

- Must be:
  - Robust against connection errors.
  - Clearly logged via `Write-MasterLog.ps1`.

#### 2.2.3 Higher-level DOSBox workflows

On top of the MCP client, v1 should provide a small set of **RE-friendly** actions:

- `Pause-DosboxSession.ps1` / `Resume-DosboxSession.ps1` (reimplemented to use MCP).
- `Capture-GameState.ps1` (optional v1.1):
  - Pause via MCP.
  - Optionally run a DOS command (e.g., save game).
  - Call `Dump-Memory.ps1` on the host.
  - Resume.

`Open-SessionPrompt.ps1` can optionally:

- Accept a parameter `-UseMcpPause` (default: false).
- When true, call the MCP-based pause/resume wrappers around the prompt.

The integration with DOSBox-X is then **opt-in**:

- Core logger works without MCP.
- If MCP is configured, you get richer automation.

### 2.3 Ghidra adapter (headless control plane)

Goal: standardize how REMastered calls into Ghidra so that Gemini/CLI tools can request RE tasks without manual GUI steps.

Existing building blocks from v0:

- `Invoke-GhidraHeadless.ps1` – general wrapper around `analyzeHeadless`.
- `Export-GhidraData.ps1` – script to export data from a Ghidra project.

v1 should define a clearer API surface, for example:

- `Analyze-GameBinary.ps1`:
  - Ensures Ghidra project exists at `cfg.tools.ghidra_project_dir`.
  - Imports main EXE (`cfg.original.entry_exe`).
  - Runs configured analyzers.
  - Logs actions and output locations.

- `Export-GhidraSymbols.ps1`:
  - Calls `Export-GhidraData.ps1` in a standard way.
  - Produces well-known outputs (e.g., `Data/indexes/ghidra_symbols.json`).

**Task checklist for the adapter:**

1. Create `Tools/scripts/Analyze-GameBinary.ps1` that accepts `-ConfigPath` and optional analyzer profile.
2. Normalize environment discovery (`$env:GHIDRA_HOME`, fallback instructions) and fail fast with actionable messages.
3. Define a `ghidra_exports/` folder convention under `Data/indexes/` (JSON + Markdown summaries).
4. Add a small schema doc in `Docs/Ghidra.md` covering required inputs/outputs.
5. Update `Docs/GeminiCommands.md` with `/ghidra-analyze` and `/ghidra-export` commands that call the new scripts.
6. Provide example invocation snippets in README so manual users can run the same commands outside Gemini.

Longer-term (beyond v1):

- Optionally integrate PyGhidra or other scripting.
- Define a simple JSON contract for Ghidra scripts so Gemini can request specific analyses.

## 3. Gemini CLI integration

v1 should assume Gemini (or any LLM client) interacts by **running scripts and reading files**, not by direct in-process calls.

Design principles:

- Every important action has a **single entry script**:
  - Bootstrap game → `Start-GameProject.ps1`.
  - Refresh file index → `Generate_File_Index.ps1` wrapper.
  - Analyze binary → `Analyze-GameBinary.ps1`.
  - Snapshot runtime state → `Capture-GameState.ps1` (when MCP exists).

- `Docs/GeminiCommands.md` documents:
  - Slash commands → script + parameters mapping.
  - Any assumptions (e.g., MCP must be enabled, Ghidra installed at `GHIDRA_HOME`).

**Task checklist for Gemini CLI docs/entrypoints:**

1. Refresh `Docs/GeminiCommands.md` so each command includes:
   - Script path + parameters.
   - Required config (e.g., MCP, GHIDRA_HOME, game.json fields).
   - Expected outputs (files/log entries).
2. Add new commands:
   - `/session-log` → `Open-SessionPrompt.ps1` (host-only).
   - `/dump-snapshot` → future MCP-aware snapshot script.
   - `/ghidra-analyze`, `/ghidra-export` → new adapter scripts.
3. Document error-handling expectations (e.g., Gemini surfaces script stderr verbatim).
4. Provide a quick-start snippet in README linking to Gemini commands doc.

## 4. Docker usage

Docker should **not** be required for DOSBox-X or Ghidra.

v1 Docker role:

- Provide a reproducible environment for host-only tooling:
  - Python 3.13 + UV.
  - Pytest, format parsers, data converters.
  - Headless Ghidra exports if desired.

Guidelines:

- Docker container should:
  - Mount the repo at `/workspace`.
  - Be able to run all core scripts that do **not** depend on GUI windows or MCP.
- DOSBox-X and Ghidra GUI remain native on Windows, talking to the same repo tree.

## 5. v1 Minimal Feature Set

To consider v1 "usable" as a base template:

1. **Core**
   - `game.json` model stable and documented.
   - Bootstrap path (`Start-GameProject.ps1`) robust and cwd-independent.
   - File index + master docs generated reliably.
   - Dump lifecycle + metadata + summary working and documented.

2. **DOSBox-X adapter (MCP)**
   - MCP settings documented in `dosbox-x.default.conf`.
   - `Dosbox-McpClient.ps1` with at least:
     - Connect, simple command send, pause/resume.
   - High-level script to pause/resume sessions using MCP.
   - (Optional for v1.0) Single example automation: snapshot routine that combines MCP pause + `Dump-Memory.ps1`.

3. **Ghidra adapter**
   - `Analyze-GameBinary.ps1` wrapper around `Invoke-GhidraHeadless.ps1`.
   - One concrete export script (e.g., symbols or function list) with documented output path.

4. **Docs / UX**
   - `README.md` updated to:
     - Distinguish core host-only features from optional DOSBox-X/Ghidra integration.
     - Remove any promises about Ctrl+F8 / keymapper-based host commands.
   - `Docs/GeminiCommands.md` aligned with the v1 script entrypoints.

## 6. Migration from v0 prototype

- **Keep:**
  - Directory layout, `game.json`, most scripts under `Tools/scripts` that are host-only.
  - Dump/metadata scripts, session/idea logging, Ghidra headless helpers.

- **Refine:**
  - `Start-GameProject.ps1` path handling (already partially fixed).
  - README and docs to match the new architecture.

- **Remove or de-emphasize:**
  - Any documentation that promises direct DOSBox-X key → host script mappings (Ctrl+F8/F9).
  - DOSBox-X-specific glue that is not expressed through the new MCP adapter layer.

This document is a living outline for REMastered v1. As v1 features are implemented, sections should be updated with concrete command examples and configuration snippets verified against the actual code.
