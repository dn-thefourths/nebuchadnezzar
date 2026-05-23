#!/usr/bin/env python3
"""
Nebuchadnezzar terminal splash
Rain → "Welcome to the Nebuchadnezzar" full-width banner → green prompt flash

Security notes:
  - stdlib only: curses, random, time, sys
  - no network, no subprocess, no file I/O, no eval/exec
  - runs as current user; file is 644 under a 750 home directory
"""
import curses, random, time, sys

CHARS = (
    "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ"
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
)
TICK    = 0.04   # seconds per frame (~25 fps)
MESSAGE = "Welcome to the Nebuchadnezzar"


# ── Rain ──────────────────────────────────────────────────────────────────────

def make_rain(width, height):
    return dict(
        drops  = [random.randint(-height, 0) for _ in range(width)],
        speeds = [random.randint(1, 2)        for _ in range(width)],
        trails = [random.randint(6, 18)       for _ in range(width)],
    )

def draw_rain(stdscr, rain, width, height, skip, C):
    drops, trails = rain['drops'], rain['trails']
    for col in range(min(width, len(drops))):
        if col in skip:
            continue
        head, trail = drops[col], trails[col]
        for row in range(height):
            dist = head - row
            if dist == 0:
                try: stdscr.addstr(row, col, random.choice(CHARS), C['HEAD'])
                except curses.error: pass
            elif 1 <= dist <= trail:
                fade = dist / trail
                # 0.3% chance of a red glitch character
                if random.random() < 0.003:
                    attr = C['GLITCH']
                elif fade > 0.6: attr = C['DIM']
                elif fade > 0.3: attr = C['RAIN']
                else:            attr = C['BRIGHT']
                if random.random() < 0.75:
                    try: stdscr.addstr(row, col, random.choice(CHARS), attr)
                    except curses.error: pass

def advance_rain(rain, width, height, skip, tick):
    if tick % 2 != 0:
        return
    drops, speeds, trails = rain['drops'], rain['speeds'], rain['trails']
    for col in range(min(width, len(drops))):
        if col in skip:
            continue
        drops[col] += speeds[col]
        if drops[col] > height + trails[col]:
            drops[col] = random.randint(-20, -3)
            trails[col] = random.randint(6, 18)

def sparse_col(stdscr, col, owned_rows, height, C):
    """Sparse dim chars in the non-message rows of a settled column."""
    for row in range(height):
        if row not in owned_rows and random.random() < 0.05:
            try: stdscr.addstr(row, col, random.choice(CHARS), C['DIM'])
            except curses.error: pass


# ── Phase: pure rain ──────────────────────────────────────────────────────────

def phase_rain(stdscr, rain, C, duration):
    t0 = time.time()
    tick = 0
    while time.time() - t0 < duration:
        if stdscr.getch() != -1:
            return True
        height, width = stdscr.getmaxyx()
        stdscr.erase()
        draw_rain(stdscr, rain, width, height, set(), C)
        stdscr.refresh()
        advance_rain(rain, width, height, set(), tick)
        tick += 1
        time.sleep(TICK)
    return False


# ── Phase: decode message lines in random cell order ─────────────────────────

def phase_decode(stdscr, rain, C, line_specs, per_char, settle, hold):
    """
    line_specs: list of (text, row, start_col)
    All characters across all lines are shuffled into a single decode order.
    Returns True if user pressed a key to skip.
    """
    cells = []
    for text, row, start_col in line_specs:
        for ci, ch in enumerate(text):
            cells.append((row, start_col + ci, ch))
    random.shuffle(cells)

    decode_at = {(r, c): i * per_char for i, (r, c, _) in enumerate(cells)}
    char_at   = {(r, c): ch           for (r, c, ch)   in cells}

    total = len(cells) * per_char + settle + hold
    t0    = time.time()
    tick  = 0

    while True:
        if stdscr.getch() != -1:
            return True
        t = time.time() - t0
        if t >= total:
            return False

        height, width = stdscr.getmaxyx()
        stdscr.erase()
        skip         = set()
        owned_by_col = {}   # col -> set of rows that have a settled message char

        for (r, c), ch in char_at.items():
            if r >= height or c >= width:
                continue
            ds = decode_at[(r, c)]
            if t >= ds + settle:
                skip.add(c)
                owned_by_col.setdefault(c, set()).add(r)
                try: stdscr.addstr(r, c, ch, C['MSG'])
                except curses.error: pass
            elif t >= ds:
                owned_by_col.setdefault(c, set()).add(r)
                try: stdscr.addstr(r, c, random.choice(CHARS), C['BRIGHT'])
                except curses.error: pass

        for col in skip:
            sparse_col(stdscr, col, owned_by_col.get(col, set()), height, C)

        draw_rain(stdscr, rain, width, height, skip, C)
        stdscr.refresh()
        advance_rain(rain, width, height, skip, tick)
        tick += 1
        time.sleep(TICK)


# ── Phase: typewriter lines ───────────────────────────────────────────────────

def phase_typewriter(stdscr, C, lines, char_delay=0.048, blink_delay=0.25, hold=0.5):
    """
    Type out lines one character at a time with a blinking block cursor.
    Draws on top of the existing (static) screen — no erase, no rain.
    """
    height, width = stdscr.getmaxyx()
    start_row = height - len(lines) - 3
    start_col = 4
    cursor    = "\u2588"   # █

    for i, line in enumerate(lines):
        row    = start_row + i
        typed  = ""
        prefix = "> "
        for ch in line:
            typed += ch
            try: stdscr.addstr(row, start_col, prefix + typed + cursor, C['PROMPT'])
            except curses.error: pass
            stdscr.refresh()
            time.sleep(char_delay)
            if stdscr.getch() != -1:
                return   # skip on keypress

        # Blink cursor twice at end of line
        for _ in range(2):
            try: stdscr.addstr(row, start_col, prefix + typed + " ", C['PROMPT'])
            except curses.error: pass
            stdscr.refresh()
            time.sleep(blink_delay)
            try: stdscr.addstr(row, start_col, prefix + typed + cursor, C['PROMPT'])
            except curses.error: pass
            stdscr.refresh()
            time.sleep(blink_delay)

        # Leave line without cursor before moving to next
        try: stdscr.addstr(row, start_col, prefix + typed, C['PROMPT'])
        except curses.error: pass

    stdscr.refresh()
    time.sleep(hold)


# ── Phase: green prompt flash ─────────────────────────────────────────────────

def phase_flash_prompt(stdscr, C):
    height, width = stdscr.getmaxyx()
    row  = height - 2
    col  = 4
    text = "> \u2588"   # "> █"

    for _ in range(4):
        try: stdscr.addstr(row, col, text, C['PROMPT'])
        except curses.error: pass
        stdscr.refresh()
        time.sleep(0.28)
        try: stdscr.addstr(row, col, " " * len(text), C['RAIN'])
        except curses.error: pass
        stdscr.refresh()
        time.sleep(0.16)

    # Leave prompt on for a final beat
    try: stdscr.addstr(row, col, text, C['PROMPT'])
    except curses.error: pass
    stdscr.refresh()
    time.sleep(0.5)


# ── Main ──────────────────────────────────────────────────────────────────────

def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()

    # Shift the terminal's green slot toward Matrix #00FF41 where supported
    if curses.can_change_color():
        curses.init_color(curses.COLOR_GREEN, 0, 880, 255)

    curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)   # rain body
    curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_BLACK)   # rain head / bright
    curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_BLACK)   # settled message
    curses.init_pair(4, curses.COLOR_GREEN, curses.COLOR_BLACK)   # green prompt / typewriter
    curses.init_pair(5, curses.COLOR_RED,   curses.COLOR_BLACK)   # red glitch

    C = {
        'RAIN':   curses.color_pair(1),
        'HEAD':   curses.color_pair(2) | curses.A_BOLD,
        'DIM':    curses.color_pair(1) | curses.A_DIM,
        'BRIGHT': curses.color_pair(1) | curses.A_BOLD,
        'MSG':    curses.color_pair(3) | curses.A_BOLD,
        'PROMPT': curses.color_pair(4) | curses.A_BOLD,
        'GLITCH': curses.color_pair(5) | curses.A_BOLD,
    }

    stdscr.bkgd(' ', curses.color_pair(1))
    stdscr.nodelay(True)

    height, width = stdscr.getmaxyx()
    rain = make_rain(width, height)
    row  = height // 2

    # 1 ── Pure rain ──────────────────────────────────────────────────────────
    if phase_rain(stdscr, rain, C, 1.2): return

    # 2 ── Full-width banner: border / message / border ───────────────────────
    s3     = max(0, (width - len(MESSAGE)) // 2)
    border = "═" * (width - 2)
    specs  = [
        (border,  row - 1, 1),
        (MESSAGE, row,     s3),
        (border,  row + 1, 1),
    ]
    if phase_decode(stdscr, rain, C, specs, 0.012, 0.35, 1.4): return

    # 3 ── Typewriter: status lines type out on the settled scene ─────────────
    phase_typewriter(stdscr, C, ["LINK ESTABLISHED", "INITIATING INTERFACE..."])

    # 4 ── Green prompt flash ─────────────────────────────────────────────────
    phase_flash_prompt(stdscr, C)


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except (KeyboardInterrupt, Exception):
        pass
    # Reset terminal colours and clear screen before handing off to claude
    sys.stdout.write("\033[0m\033[2J\033[H")
    sys.stdout.flush()
