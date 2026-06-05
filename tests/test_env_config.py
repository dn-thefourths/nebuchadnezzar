#!/usr/bin/env python3
"""Tests for matrix-splash.py environment-variable configuration.

Dependency-free: run directly with `python3 tests/test_env_config.py`.
Loads the script as a module (its curses work is under __main__, so import is
side-effect free) and checks the MATRIX_* overrides and their fallbacks.
"""
import importlib.util
import os

SCRIPT = os.path.join(os.path.dirname(__file__), "..", "matrix-splash.py")


def load(**env):
    """Load matrix-splash.py fresh with the given MATRIX_* env values."""
    for key in ("MATRIX_TICK", "MATRIX_MESSAGE"):
        os.environ.pop(key, None)
    for key, value in env.items():
        os.environ[key] = value
    spec = importlib.util.spec_from_file_location("matrix_splash", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_defaults():
    m = load()
    assert m.TICK == 0.04, m.TICK
    assert m.MESSAGE == "Welcome to the Nebuchadnezzar", m.MESSAGE


def test_overrides():
    m = load(MATRIX_TICK="0.09", MATRIX_MESSAGE="Wake up, Neo")
    assert m.TICK == 0.09, m.TICK
    assert m.MESSAGE == "Wake up, Neo", m.MESSAGE


def test_invalid_tick_falls_back():
    m = load(MATRIX_TICK="garbage")
    assert m.TICK == 0.04, m.TICK


def test_blank_message_falls_back():
    m = load(MATRIX_MESSAGE="")
    assert m.MESSAGE == "Welcome to the Nebuchadnezzar", m.MESSAGE


if __name__ == "__main__":
    test_defaults()
    test_overrides()
    test_invalid_tick_falls_back()
    test_blank_message_falls_back()
    print("env-config tests passed")
