#!/bin/sh
# Builds index.html (standalone PWA page) from app.html (the page body, also published as the Claude artifact).
set -e
cd "$(dirname "$0")"
cat head.html app.html tail.html > index.html
echo "index.html built ($(wc -c < index.html) bytes)"
