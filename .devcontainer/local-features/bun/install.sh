#!/usr/bin/env bash

set -eax

VERSION="${VERSION:-latest}"

case "$(uname -m)" in
    aarch64 | arm64) TARGET=aarch64 ;;
    *) TARGET=x64 ;;
esac

if [ "$VERSION" = "latest" ]; then
    URL="https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${TARGET}.zip"
else
    URL="https://github.com/oven-sh/bun/releases/download/bun-v${VERSION#v}/bun-linux-${TARGET}.zip"
fi

# Into the image, not the user's home: a deployment's home is only filled at its first start, and a Bun there would
# stay at that day's version and come first in PATH
curl -fsSL -o /tmp/bun.zip "$URL"
unzip -q /tmp/bun.zip -d /tmp
install -m 755 "/tmp/bun-linux-${TARGET}/bun" /usr/local/bin/bun
ln -sf bun /usr/local/bin/bunx
rm -rf /tmp/bun.zip "/tmp/bun-linux-${TARGET}"

# What `bun add -g` installs for the user, after the image's own tools
cat <<'EOT' >> /home/$_REMOTE_USER/.zshrc
export PATH="$PATH:$HOME/.bun/bin"
EOT
