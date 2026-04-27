---
title: "Word Count"
date: 2026-04-27T00:00:00Z
draft: false
name: "word-count"
version: "0.1.0"
author: "Hugo Studio contributors"
authorUrl: "https://github.com/hugo-tools"
repo: "https://github.com/hugo-tools/hugo-studio-plugin-word-count"
installUrl: "https://github.com/hugo-tools/hugo-studio-plugin-word-count/releases/latest/download/word-count.zip"
extensionPoints: ["panel"]
minStudioVersion: "1.11.0"
description: "A live word and reading-time counter for the active content body."
screenshots: []
---

A reference plugin that ships alongside the marketplace. It registers
a small **Word Count** panel that updates as the user types in the
body editor.

## What it does

- Shows total word count, character count (with and without spaces),
  and a reading-time estimate at 200 wpm.
- Subscribes to the editor's body change event so the numbers stay
  live without manual refresh.

## Why it exists

It's the smallest possible end-to-end plugin — useful as a starting
point for anyone writing their first one. Read the source for the
reference implementation of the `panel` extension point.

## Install

The Hugo Studio "Browse" tab installs it in one click. Manual:

1. Download from the `installUrl` above.
2. Extract into `<your-site>/.hugoeditor/plugins/word-count/`.
3. Restart Hugo Studio. A new "Word count" tab appears next to Git.
