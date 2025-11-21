
# REMastered – DOS Game Reverse Engineering Toolkit (Concepts)

## Goals

- **Reusable Starter Kit** for reverse engineering old DOS games (e.g. RPGs, adventures, simulators), not tied to any specific title.
- Provide a **standard project layout**, config file, and scripts so any new game can be onboarded quickly.
- Support a workflow that combines:
  - Static file analysis (headers, formats, archives).
  - Code analysis (Ghidra + PyGhidra MCP).
  - Runtime observation (Dosbox‑X + MCP, memory/VRAM dumps).
  - Assisted reasoning and documentation (Gemini CLI / other LLM tools).
- Keep a **single source of truth** for findings in human‑readable Markdown, so work is not duplicated.

The Legends of Valour work is used as a reference and sanity check, but this toolkit is meant to be game‑agnostic.

---

## High‑Level Repository Layout

This is the target layout for any project created from REMastered:

- `game.json`  
  Per‑project configuration (paths, entry EXE, tool settings).

- `Original/`  
  Where the original DOS game files live. Intended to be **read‑only**.
  - `Original/dos/` – the directory mounted as a DOS drive in Dosbox‑X.

- `Docs/`  
  Human‑oriented documentation and notes.
  - `Docs/Master_File_Document.md` – central RE master doc for the game.
  - `Docs/Game_File_Index.md` – Markdown table generated from the file index.
  - `Docs/File_Formats/` – one file per discovered format (e.g. `MAP.md`, `PALETTE.md`).
  - `Docs/Runtime_Structs/` – in‑memory structures (inventory layout, entities, etc.).
  - `Docs/Sessions/` – play logs linking human actions to memory dumps.
  - `Docs/Templates/` – generic templates for master doc and checklists.

- `Data/`  
  Machine‑generated data and exports.
  - `Data/indexes/` – CSV/JSON file indexes, Ghidra exports, symbol tables.
  - `Data/dumps/` – memory dumps, VRAM/palette dumps, save‑state metadata.

- `Tools/`  
  Scripts and configs used across games.
  - `Tools/scripts/`
    - `Start-GameProject.ps1` – one‑shot bootstrap for a new game profile.
    - `Read-GameConfig.ps1` – loads `game.json`.
    - `Generate_File_Index.ps1` – generic file indexer (CSV + Markdown).
    - (Future) `Capture-Session.ps1` – helper to append play logs and link dumps.
    - (Future) Ghidra/PyGhidra export helpers.
  - `Tools/configs/`
    - `dosbox-x.default.conf` – baseline Dosbox‑X config template.
    - `gemini.default.profile.yml` – template Gemini/LLM integration profile.

- `Ghidra/`  
  Integration touchpoints for static code analysis.
  - `Ghidra/projects/` – user‑created per‑game Ghidra projects.
  - `Ghidra/scripts/` – template scripts for exporting symbols, strings, xrefs.

This layout is generic; a specific game is plugged in only via config and content, not by changing this structure.

---

## Per‑Game Configuration (`game.json`)

Each project created from REMastered has a `game.json` describing the current game:

```jsonc
{
  "name": "Unknown DOS Game",
  "id": "example-dos-game",
  "original": {
    "root": ".\\Original\\dos\\game",
    "entry_exe": "GAME.EXE"
  },
  "docs": {
    "master_file_doc": ".\\Docs\\Master_File_Document.md",
    "file_index_md": ".\\Docs\\Game_File_Index.md"
  },
  "data": {
    "indexes_dir": ".\\Data\\indexes",
    "dumps_dir": ".\\Data\\dumps"
  },
  "tools": {
    "dosbox_config": ".\\Tools\\configs\\dosbox-x.conf",
    "ghidra_project_dir": ".\\Ghidra\\projects\\Game_Project",
    "ghidra_scripts_dir": ".\\Ghidra\\scripts",
    "gemini_profile": ".\\Tools\\configs\\gemini.profile.yml"
  }
}
```

The core scripts read this file instead of hard‑coding paths, which makes the toolkit portable across games.

---

## Bootstrap Flow (`Start-GameProject.ps1`)

For any new game, the workflow looks like:

1. **Drop original game files** under `Original/dos/<something>` (e.g. the full DOS game directory).
2. **Edit `game.json`** to point `original.root` at that directory and set `entry_exe` to the main EXE.
3. Run:
   ```powershell
   .\Tools\scripts\Start-GameProject.ps1
   ```
4. The script will:
   - Load `game.json` and validate that the original files and entry EXE exist.
   - Ensure all standard directories exist (`Docs`, `Data/indexes`, `Data/dumps`, etc.).
   - Create `Docs/Master_File_Document.md` from a template if it does not exist.
   - Run `Generate_File_Index.ps1` to build a CSV index and `Docs/Game_File_Index.md`.
   - Create baseline configs like `Tools/configs/dosbox-x.conf` and a placeholder Ghidra project directory if they are missing.

After this one‑time bootstrap, the project is ready for deeper work: file format analysis, Ghidra work, Dosbox‑X instrumentation, and human + automated documentation.

---

## Workflow Pillars

The toolkit is built around four pillars:

- **File‑Level Recon**  
  Systematic indexing of all files, hex signatures, inferred types, and reverse‑engineering status. Results are stored in CSV/JSON under `Data/indexes` and surfaced in Markdown under `Docs/`.

- **Code‑Level Recon (Ghidra)**  
  Ghidra projects under `Ghidra/projects` with optional helper scripts under `Ghidra/scripts` to export symbols, strings, and function information back into `Data/indexes` for tooling and documentation.

- **Runtime Observation (Dosbox‑X)**  
  Dosbox‑X configs under `Tools/configs` to run the game from `Original/dos`, plus future hooks (MCP, scripts) to capture memory/VRAM dumps into `Data/dumps` tied to human‑written session logs in `Docs/Sessions`.

- **Assisted Reasoning & Documentation**  
  External tools (e.g. Gemini CLI or other LLMs) operate on the indexed data, disassemblies, and dumps to propose structure hypotheses and update documentation (especially `Master_File_Document.md` and `Docs/File_Formats/*`). The toolkit’s job is to keep these artifacts organized and avoid re‑doing the same work.

---

## Next Steps

- Implement the core scripts:
  - `Read-GameConfig.ps1` to load `game.json`.
  - `Generate_File_Index.ps1` as a parameterized file indexer.
  - `Start-GameProject.ps1` to wire everything together for a fresh game.
- Add minimal templates under `Docs/Templates/` for the master document and checklist.
- Optionally, add starter configs for Dosbox‑X and Ghidra to document how they should be wired into this layout.

