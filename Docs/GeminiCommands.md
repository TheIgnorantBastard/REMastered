# Gemini Custom Slash Commands

Use this page to track every Gemini CLI (or other LLM) slash command that
wraps a repeatable REMastered workflow. Each entry should describe the purpose,
inputs, command body, outputs, and any files it touches.

## /index-files
- **Purpose:** Regenerate the file index (CSV + Markdown) and summarize changes.
- **Inputs:** None (optional flag to override `game.json` path).
- **Command body:**
  ```
  /index-files
  ```
  - Runs `Tools/scripts/Start-GameProject.ps1` (or directly
    `Generate_File_Index.ps1`) inside PowerShell.
  - After completion, diffs `Data/indexes/files.csv` against previous commit and
    returns a short summary of new/removed/changed files.
- **Outputs:**
  - Updated `Docs/Game_File_Index.md`
  - Updated `Data/indexes/files.csv`
  - Optional inline summary in chat.

## /session-log
- **Purpose:** Capture a human play session plus the memory/VRAM dumps created.
- **Inputs:**
  - Free-form text describing the player actions.
  - Optional list of dump filenames.
- **Command body:**
  ```
  /session-log action="Moved item from slot 1 to 3" dumps="Data/dumps/inventory_2025-11-22.bin"
  ```
  - Appends to `Docs/Sessions/<date>-session.md` with timestamp, action text,
    and linked dump files.
- **Outputs:**
  - Updated session log file (Markdown) with the new entry.

## /map-analyze
- **Purpose:** Given a hex slice and relevant disassembly, propose/confirm a map
  structure and append notes to `Docs/File_Formats/MAP.md`.
- **Inputs:**
  - Hex dump snippet or offset range.
  - Optional Ghidra pseudocode snippet.
- **Command body:**
  ```
  /map-analyze hex="<hex snippet>" code="<pseudocode>"
  ```
  - Gemini analyzes the data, infers header fields and grid layout, and writes a
    Markdown section to `Docs/File_Formats/MAP.md` (with "Hypothesis" vs
    "Verified" tags).
- **Outputs:**
  - Updated `Docs/File_Formats/MAP.md`.
  - Inline summary of findings.

Add more commands here as you automate other workflows (palette analysis,
audio module disassembly, etc.). Keep this list authoritative so everyone knows
which slash commands exist and what files they affect.
