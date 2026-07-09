#!/bin/bash
# cliphist menu — uses fuzzel to pick from clipboard history
cliphist list | fuzzel --dmenu --prompt="Clipboard: " | cliphist decode | wl-copy
