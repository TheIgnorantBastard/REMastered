# REMastered – DOS Game Reverse Engineering Toolkit

REMastered is a minimal, reusable starter kit for reverse engineering old DOS games.
It gives you a standard project layout, a per-game config file, and a few core
scripts so you can quickly onboard any game and keep your findings organized.

## What you get

- **Standard directory structure** for original files, docs, data, tools, and Ghidra.
- **`game.json`** config that describes the current game (paths, entry EXE, tool paths).
- **Bootstrap script** `Tools/scripts/Start-GameProject.ps1` that:
  - Validates your original game folder and entry EXE.
  - Ensures standard directories exist.
  - Generates a CSV + Markdown file index of all game files.
  - Creates `Docs/Master_File_Document.md` from a template if needed.

## Basic usage

1. Clone this repo to a new folder for your game.
2. Copy the game's original DOS directory under `Original/dos/`, for example:
   - `Original/dos/legval/` for Legends of Valour.
3. Edit `game.json`:
   - Set `original.root` to the relative path of your DOS folder, e.g. `.\\Original\\dos\\legval`.
   - Set `original.entry_exe` to the main EXE (e.g. `RUN.EXE`).
   - Optionally adjust doc and data paths if you want a different layout.
4. Open PowerShell in the repo root and run:

   ```powershell
   .\Tools\scripts\Start-GameProject.ps1
   ```

5. Inspect the generated artifacts:
   - `Docs/Game_File_Index.md` – Markdown file index of all game files.
   - `Data/indexes/files.csv` – CSV index of all game files.
   - `Docs/Master_File_Document.md` – master RE document (if newly created).

From here you can start your reverse engineering work:

- Use **Ghidra** with a project under `Ghidra/projects/` and scripts under `Ghidra/scripts/`.
- Use **Dosbox-X** with a per-game config derived from `Tools/configs/dosbox-x.default.conf`.
- Keep notes on formats in `Docs/File_Formats/` and runtime structures in `Docs/Runtime_Structs/`.

## Notes

- This repo is intentionally game-agnostic. All game-specific details live in
  `game.json` and in the content you add under `Docs/`.
- The current scripts are minimal by design. You can extend them to integrate
  Gemini CLI, Dosbox-X MCP, PyGhidra MCP, or any other tooling you use.

## Using this as a template

1. Click **Use this template** on GitHub (or clone and copy manually).
2. Rename the repo/folder to match your target game (e.g., `lov-dos-re`).
3. Drop the game files under `Original/dos/<game>` and update `game.json`.
4. Run `Start-GameProject.ps1` to bootstrap docs and indexes.
5. Commit your findings (`Docs/`, `Data/indexes/metadata`) but keep raw dumps
   and original payloads out of Git by respecting `.gitignore`.

## Docker & automation roadmap

- A `Dockerfile` + `docker-compose.yml` are included. Build/run with Docker
  Desktop:

  ```powershell
  docker compose build
  docker compose run --rm remastered
  ```

  You will land in PowerShell inside the container with the repo mounted at
  `/workspace`. From there you can run:

  ```powershell
  .\Tools\scripts\Start-GameProject.ps1
  ```

  All generated files (indexes, docs, dumps) remain on the host filesystem.
- Feel free to add more services/commands (e.g., headless Dosbox-X MCP, Ghidra
  exporters) to the compose file if your workflow needs them.
- A helper service `dosbox_headless` is already defined. Launch it with:

  ```powershell
  docker compose run --rm dosbox_headless
  ```

  This will run dosbox-x with captures pointed at `Data/dumps/`, letting you
  script memory/VRAM dumps without touching your local DOSBox setup.

## Gemini custom slash commands

- `Docs/GeminiCommands.md` documents slash commands that wrap common tasks
  (e.g., regenerating the file index, logging gameplay sessions, analyzing
  map headers). Use it as a central registry when you add new scripted actions.

## Ctrl+F8 session logging hotkey

- `Tools/scripts/Open-SessionPrompt.ps1` launches a small dialog so you can pause
  the game, describe what you just did, and optionally attach dump files. It
  calls `Capture-Session.ps1` (and `Dump-Memory.ps1` when `-AutoDump` is used).
- A helper launcher `Tools/scripts/Launch-SessionPrompt.cmd` is provided so the
  script can be triggered from DOSBox-X key bindings.
- To wire it up:
  1. In your per-game `dosbox-x.conf`, keep `mapperfile=Tools/configs/mapper.map`.
  2. Start DOSBox-X, press **Ctrl+F1** to open the mapper, select an unused key
     (e.g., **Ctrl+F8**), and bind it to run the host command
     `Tools/scripts/Launch-SessionPrompt.cmd -AutoDump`.
  3. Close the mapper to save the binding. Pressing Ctrl+F8 now pauses the game,
     shows the logging prompt, writes the entry under `Docs/Sessions/`, and
     resumes the emulator when you dismiss the dialog.
- Customize the behavior by editing the mapper or passing additional parameters
  (`-DumpLabel`, `-PauseCommand`, `-ResumeCommand`) to the launcher script.

## Ctrl+F9 idea logging hotkey

- `Tools/scripts/Open-IdeaPrompt.ps1` pops up a lightweight dialog (with console
  fallback) so you can jot down automation/feature ideas on the spot. It uses
  `Log-Brainstorm.ps1` under the hood so entries go to `Docs/Ideas.md` and the
  master log.
- `Tools/scripts/Launch-IdeaPrompt.cmd` is the binder you can map to **Ctrl+F9**
  (or any key) inside DOSBox-X or another host. The workflow mirrors Ctrl+F8 but
  is geared toward brainstorming rather than gameplay logging.
- You can also call `Log-Brainstorm.ps1` directly from PowerShell/Gemini CLI or
  use the `/idea-log` slash command (documented in `Docs/GeminiCommands.md`) to
  log ideas manually or let Gemini propose one for you.

## Master log

- All helper scripts write to `Docs/Master_Log.md` via `Tools/scripts/Write-MasterLog.ps1`.
- Each entry is timestamped and tagged (e.g., `[bootstrap]`, `[session]`, `[dump]`, `[ghidra]`).
- Use this file to see a chronological history of automation actions, which helps avoid repeating work.

## Dump lifecycle & archiving

- Raw captures flow through `Data/dumps/incoming`, `Data/dumps/working`, and
  `Data/dumps/archive`. Each call to `Dump-Memory.ps1` writes a
  `<dump>.meta.json` sidecar that records tags, notes, hashes, and history.
- When you're done analyzing a capture, run
  `Tools/scripts/Archive-Dump.ps1 -DumpPath <path> [-TargetStage working|archive]`
  to move or copy it into its long-term home while appending new notes/tags and
  logging the transition.
- Because `Data/dumps/` stays gitignored, you can keep as many raw binaries as
  needed without polluting commits, yet the metadata captures the relevant
  context that bubbles up into the session logs and master log.
- Use `Tools/scripts/Summarize-Dumps.ps1` to produce `Docs/Dump_Summary.md`
  (stage/tag filters + optional history, with per-stage totals) so you can prune
  stale captures confidently.

## Script toolbox overview

- `Tools/scripts/New-FormatDoc.ps1` – generates a format doc from `Docs/Templates/FileFormat.template.md`.
- `Tools/scripts/Get-HexSnippet.ps1` – dumps a formatted hex/ASCII slice of any file/offset.
- `Tools/scripts/Dump-Memory.ps1` – captures emulator RAM or other binary blobs into
  `Data/dumps/<stage>/timestamp_label.bin` and writes a `<file>.meta.json` sidecar with
  tags, notes, and hash info so you can track insights later. Use `-Stage incoming|working|archive`
  to move captures through the lifecycle.
- `Tools/scripts/Archive-Dump.ps1` – moves or copies existing dumps between stages,
  updates metadata history/tags/notes, and records the action in the master log.
- `Tools/scripts/Summarize-Dumps.ps1` – scans all dump metadata, applies optional stage/tag
  filters, writes `Docs/Dump_Summary.md`, and logs aggregate counts/sizes for triage.
- `Tools/scripts/Capture-Session.ps1` – appends Markdown entries to `Docs/Sessions/` with optional dump links.
- `Tools/scripts/Compare-FileIndex.ps1` – compares `Data/indexes/files.csv` to a previous version (uses git history if no path provided).
- `Tools/scripts/Open-SessionPrompt.ps1` + `Launch-SessionPrompt.cmd` – Ctrl+F8 workflow described above (uses `Pause-DosboxSession.ps1` / `Resume-DosboxSession.ps1`).
- `Tools/scripts/Export-GhidraData.ps1` + `Invoke-GhidraHeadless.ps1` – run real headless Ghidra exports when `GHIDRA_HOME` is configured.
- `Tools/scripts/Pause-DosboxSession.ps1` / `Resume-DosboxSession.ps1` – wrappers to call your own pause/resume automation or environment-configured commands.
- `Tools/scripts/Summarize-MasterLog.ps1` – prints the master log by category/date.
- `Tools/scripts/Verify-FormatDoc.ps1` – checks every file in `Docs/File_Formats/` for required sections and TODOs.
- `Tools/scripts/Run-CI.ps1` – convenience runner for linting, format verification, and master-log summaries.
- `Tools/scripts/Log-Brainstorm.ps1` – quick way to append automation/feature ideas to `Docs/Ideas.md` (like an ideas hotkey).
