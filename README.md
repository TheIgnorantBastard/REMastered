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

## Gemini custom slash commands

- `Docs/GeminiCommands.md` documents slash commands that wrap common tasks
  (e.g., regenerating the file index, logging gameplay sessions, analyzing
  map headers). Use it as a central registry when you add new scripted actions.
