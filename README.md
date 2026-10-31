# Agent Panel

Agent Panel is a KDE Plasma 6 panel widget for local coding-agent sessions. It groups chats into **Running**, **Needs input**, and **Finished**, provides a live summary of the current or most recently completed task, and lets you reopen supported sessions in the terminal selected in KDE System Settings.

The widget scans local Codex, Claude Code, Cursor, and Antigravity session stores. It includes an Agents view, a Projects view, newest-first ordering, and new Codex chat creation. Open chats show a close-window action; closed Codex chats can be permanently deleted with confirmation. Chat cards show the provider icon, title, summary, and project folder name.

## Install

Run `./install.sh`, then add **Agent Panel** from the Plasma widget chooser. To reload code changes, remove the widget from your panel and add it again.
