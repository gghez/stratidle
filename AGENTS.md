# Agent Instructions

This project is a game developed with Godot.

- Use Godot as the main engine for the project.
- The Godot console CLI is available here: `/mnt/c/Godot/Godot_v4.6.1-stable_win64_console.exe`.
- From WSL, for `headless` runs, use a native Windows path with `--path`, not a `/mnt/...` path.
- Reference command that worked:
  `'/mnt/c/Godot/Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:\Users\gg00x\nosisjeux\stratidle' --quit`
- The Godot IDE running on Windows will be reloaded manually to reflect changes made by the coding agent.
- The agent may use the tools provided by the Godot console CLI during development.
- In particular, the agent may use the CLI `headless` mode when useful to automate, verify, or execute development tasks.
- The coding agent must test changes before announcing completion, ideally via Godot in `headless` mode when that kind of verification is relevant.
- Before altering a game rule, the coding agent must read `README.md` to verify the current state of the game rules and concepts. This should be done only once per coding session.
- The coding agent must keep the key game concepts in `README.md` up to date as new instructions are provided.
