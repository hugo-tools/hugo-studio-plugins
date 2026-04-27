---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
name: "{{ .Name }}"
version: "0.1.0"
author: ""
authorUrl: ""
repo: ""
installUrl: ""
extensionPoints: []
minStudioVersion: "1.11.0"
screenshots: []
---

A short description of what this plugin does (one sentence). The
longer body below shows up on the plugin's detail page.

## What it does

…

## Install

The Hugo Studio "Browse" tab pulls this entry from the marketplace
JSON feed and offers a one-click install. Manual install:

1. Download from `installUrl`.
2. Extract into `<your-site>/.hugoeditor/plugins/{{ .Name }}/`.
3. Restart Hugo Studio.

## Configuration

…
