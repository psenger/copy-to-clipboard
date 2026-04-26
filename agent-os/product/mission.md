# Product Mission

## Problem

Developers and macOS power users frequently need to copy a text file's contents to the clipboard — to paste into a terminal, chat, code review, or document. The only native way is to open the file in an editor, select all, copy, and close. That is four steps too many.

## Target Users

macOS developers and power users who work with text files (source code, configs, logs, markdown) and want clipboard access without leaving Finder.

## Solution

A launch-on-demand macOS Service that adds **"Copy Contents to Clipboard"** to the Finder right-click menu for any text file. One click, no app to open, no window to close.

Key differentiators:

- **No UI, no persistent process** — NSServices wakes the app per invocation and exits it immediately after. Zero background overhead.
- **Broad encoding support** — handles UTF-8, UTF-16 (BOM), and Windows-1252 automatically. Legacy files copy correctly where other tools silently garble characters.
- **Native Finder integration** — no third-party launchers, no shell scripts. Appears in the Services menu for any `public.text` UTI file.
