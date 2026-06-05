# Nebuchadnezzar

Matrix-style terminal splash screen. Every new terminal window plays a full sequence then drops you into your shell (or any command you choose).

## What it does

1. **Matrix rain** with occasional red glitch characters
2. Full-width **`Welcome to the Nebuchadnezzar`** banner decodes from the rain
3. **`> LINK ESTABLISHED`** and **`> INITIATING INTERFACE...`** type out
4. Green **`> █`** prompt flashes four times
5. Launches your configured command (optional) — e.g. `claude`

## Requirements

- Python 3.8+ (stdlib only — no pip installs)
- zsh or bash
- macOS or Linux

## Install

```bash
git clone https://github.com/dn-thefourths/nebuchadnezzar.git
cd nebuchadnezzar
bash install.sh
```

The installer:
- Copies `matrix-splash.py` to `~/.config/`
- Detects your shell and appends the matching snippet to `~/.zshrc` or `~/.bashrc`
- Asks what command to auto-launch after the splash (leave blank for none)
- Optionally patches Terminal.app profiles to 14pt font (macOS only)

Open a new terminal to see it. Press any key during the sequence to skip it.

## Manual install

```bash
cp matrix-splash.py ~/.config/
cat zshrc-snippet.zsh >> ~/.zshrc      # zsh
cat bashrc-snippet.bash >> ~/.bashrc   # bash
```

Then set `MATRIX_LAUNCH` at the top of the appended snippet to whatever you want launched after the splash (e.g. `claude`, `zsh`, or leave it empty).

## Customise

### Environment variables

Set these in the shell snippet (or your environment) — no need to edit the script:

| Variable | Default | Effect |
|----------|---------|--------|
| `MATRIX_MESSAGE` | `"Welcome to the Nebuchadnezzar"` | Banner text |
| `MATRIX_TICK` | `0.04` | Frame time in seconds (~25 fps). Lower = faster. |
| `MATRIX_FREQUENCY` | `always` | `always` plays on every shell; `daily` plays at most once per calendar day (tracked in `~/.cache/nebuchadnezzar-last`). |

`MATRIX_FREQUENCY` throttles only the splash — terminal colours and `MATRIX_LAUNCH` still apply every shell.

### Phase timing

For finer control, the phase calls in `main()`:
- `phase_rain(... 1.2)` — duration of the pure rain phase (seconds)
- `phase_decode(... per_char=0.012, settle=0.35, hold=1.4)` — banner decode speed and hold time
- `phase_typewriter(... ["LINK ESTABLISHED", "INITIATING INTERFACE..."])` — typewriter lines (edit or add more)

## Security

- **stdlib only**: `curses`, `os`, `random`, `time`, `sys` — no network, no subprocess, no file writes (`os` only reads optional `MATRIX_*` config from the environment)
- `random` is used for visual randomness only (not cryptographic)
- The `daily` frequency option writes a single date stamp to `~/.cache/nebuchadnezzar-last` (shell side, not the script)
- Script runs as the current user with no privilege escalation
- All `curses.error` exceptions are caught to prevent crashes on terminal resize
- Every `while True` loop has a time-based exit condition; any keypress also skips immediately

## Files

```
matrix-splash.py      # the curses splash script
zshrc-snippet.zsh     # drop-in .zshrc addition
bashrc-snippet.bash   # drop-in .bashrc addition
install.sh            # guided installer
README.md
```
