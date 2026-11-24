#!/usr/bin/env bash

set -eax

# Fix permissions on the local folder
mkdir -p /home/$_CONTAINER_USER/.local/share
chown -R $_CONTAINER_USER:$_CONTAINER_USER /home/$_CONTAINER_USER/.local

# Make /tmp world-writable (with sticky bit) so non-root users and agents can use it
chmod 1777 /tmp

# Symlink the Diploi provided gitconfig to be used by the user
ln -s /etc/diploi-git/gitconfig /etc/gitconfig

# Configure VS Code
mkdir -p /home/$_CONTAINER_USER/.local/share/code-server/User
cat > /home/$_CONTAINER_USER/.local/share/code-server/User/settings.json <<EOT
{
  "workbench.colorTheme": "Default Dark Modern",
  "workbench.startupEditor": "none",
  "chat.commandCenter.enabled": false,
  "keyboard.dispatch": "keyCode"
}
EOT
chown -R $_CONTAINER_USER:$_CONTAINER_USER /home/$_CONTAINER_USER/.local/share/code-server

# Create a nice welcome message
# Logo generated with "figlet -f small Diploi | /usr/games/lolcat -p 1.9 -S 20 --force > motd.txt"
cat > /etc/motd <<'EOT'
 [38;5;199m [39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m_[39m[38;5;199m [39m[38;5;199m [39m[38;5;163m_[39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m_[39m[38;5;128m [39m[38;5;129m [39m[38;5;129m [39m[38;5;129m [39m[38;5;129m [39m[38;5;129m_[39m[38;5;93m [39m[38;5;93m[39m
 [38;5;199m|[39m[38;5;199m [39m[38;5;199m [39m[38;5;199m [39m[38;5;163m\[39m[38;5;164m([39m[38;5;164m_[39m[38;5;164m)[39m[38;5;164m_[39m[38;5;164m [39m[38;5;164m_[39m[38;5;164m_[39m[38;5;128m|[39m[38;5;129m [39m[38;5;129m|[39m[38;5;129m_[39m[38;5;129m_[39m[38;5;129m_[39m[38;5;93m([39m[38;5;93m_[39m[38;5;93m)[39m[38;5;93m[39m
 [38;5;199m|[39m[38;5;199m [39m[38;5;163m|[39m[38;5;164m)[39m[38;5;164m [39m[38;5;164m|[39m[38;5;164m [39m[38;5;164m|[39m[38;5;164m [39m[38;5;164m'[39m[38;5;128m_[39m[38;5;129m [39m[38;5;129m\[39m[38;5;129m [39m[38;5;129m/[39m[38;5;129m [39m[38;5;93m_[39m[38;5;93m [39m[38;5;93m\[39m[38;5;93m [39m[38;5;93m|[39m[38;5;93m[39m
 [38;5;163m|[39m[38;5;164m_[39m[38;5;164m_[39m[38;5;164m_[39m[38;5;164m/[39m[38;5;164m|[39m[38;5;164m_[39m[38;5;164m|[39m[38;5;128m [39m[38;5;129m.[39m[38;5;129m_[39m[38;5;129m_[39m[38;5;129m/[39m[38;5;129m_[39m[38;5;129m\[39m[38;5;93m_[39m[38;5;93m_[39m[38;5;93m_[39m[38;5;93m/[39m[38;5;93m_[39m[38;5;93m|[39m[38;5;63m[39m
 [38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;164m [39m[38;5;128m [39m[38;5;129m|[39m[38;5;129m_[39m[38;5;129m|[39m[38;5;129m [39m[38;5;129m [39m[38;5;129m [39m[38;5;93m [39m[38;5;93m [39m[38;5;93m [39m[38;5;93m [39m[38;5;93m [39m[38;5;93m [39m[38;5;63m [39m[38;5;63m [39m[38;5;63m[39m

 [0;37m👋 Welcome to your Diploi development environment!
    - Your application processes are [1;37mnot[0;37m running in this shell (for example, Node.js or Bun).
    - You can run commands here, for example "npm install".
    - You can edit your code here. Changes are instantly reflected across all components.
    - AI coding assistance is available in the terminal by typing "opencode".
    - Check the Diploi CLI for more info. Type "diploi" to see all available commands.[0m

EOT

# Disable oh-my-zsh update prompts (must be set before oh-my-zsh.sh is sourced)
sed -i '1s;^;zstyle ":omz:update" mode disabled\n;' /home/$_CONTAINER_USER/.zshrc

# Set the SHELL ENV on login
cat <<EOF >> /home/$_CONTAINER_USER/.zshrc
export SHELL=/usr/bin/zsh
EOF

# Print the welcome message on login
cat <<EOF >> /home/$_CONTAINER_USER/.zshrc
cat /etc/motd
EOF

# Move to /app on login
cat <<EOF >> /home/$_CONTAINER_USER/.zshrc
cd /app
EOF

# Create the runonce.sh script
cat > /usr/local/bin/diploi-runonce.sh <<EOT
#!/bin/sh

#
# Script to initialize a new development environment
#

if [ -d "/home/diploi-tmp" ] && [ -z "\$( ls -A '/home/diploi-tmp' )" ]; then
  # Copy home directory files from the Docker build if the actual home folder is empty
  echo "First boot detected. Will copy the home folder contents."
  mv -n /home/$_CONTAINER_USER/.[!.]* /home/diploi-tmp/

else
  echo "Not the first boot. Skipping home folder init."
fi
EOT

# Setup pnpm, the version the components' base image has (alixea-erp/component-bases). Node.js stopped shipping
# corepack in version 25, and its npm package brings the pnpm and yarn commands: the yarn the node feature installed
# from npm is in their way. The settings are ENV in the Dockerfile
mkdir -p /home/$_CONTAINER_USER/.pnpm-store /usr/local/share/corepack
chown $_CONTAINER_USER:$_CONTAINER_USER /home/$_CONTAINER_USER/.pnpm-store /usr/local/share/corepack
bash -c '. /usr/local/share/nvm/nvm.sh && npm uninstall -g yarn && npm install -g corepack@0.36.0'
sudo -u $_CONTAINER_USER -H zsh -lc "export COREPACK_HOME=/usr/local/share/corepack && export PNPM_HOME=/home/$_CONTAINER_USER/.local/share/pnpm && export PATH=\"\$PNPM_HOME/bin:\$PNPM_HOME:\$PATH\" && COREPACK_ENABLE_DOWNLOAD_PROMPT=0 . /usr/local/share/nvm/nvm.sh && corepack install -g pnpm@12.21.0 && SHELL=/usr/bin/zsh pnpm setup && pnpm config set store-dir /home/$_CONTAINER_USER/.pnpm-store --global"

# Install opencode globally and symlink it to a stable path for supervisord and non-login shells
bash -c '. /usr/local/share/nvm/nvm.sh && npm install -g opencode-ai@~1.19.6'
ln -sf "$(bash -c '. /usr/local/share/nvm/nvm.sh && command -v opencode')" /usr/local/bin/opencode

# Playwright with a headless Chromium, so AI agents can check pages without installing browsers into the project.
# Only the CLI wrapper and the shim use /opt/ms-playwright; a project's own Playwright keeps using ~/.cache/ms-playwright.
bash -c '. /usr/local/share/nvm/nvm.sh && npm install --prefix /opt/playwright playwright@1.65.1'
PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright /opt/playwright/node_modules/.bin/playwright install --with-deps --only-shell chromium
chown -R $_CONTAINER_USER:$_CONTAINER_USER /opt/ms-playwright
rm -rf /var/lib/apt/lists/*
mkdir -p /opt/playwright/global
cat > /opt/playwright/global/playwright.js <<'EOT'
process.env.PLAYWRIGHT_BROWSERS_PATH ??= '/opt/ms-playwright';
module.exports = require('/opt/playwright/node_modules/playwright');
EOT
cat > /usr/local/bin/playwright <<'EOT'
#!/bin/sh
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/ms-playwright}"
exec /opt/playwright/node_modules/.bin/playwright "$@"
EOT
chmod +x /usr/local/bin/playwright

chmod +x /usr/local/bin/diploi-runonce.sh

# Create supervisord entry for user specified init scripts
cat <<EOT >> /etc/supervisord.conf
; Added by diploi feature
[program:diploi-fix-permissions]
command=/bin/bash -c 'chmod 1777 /tmp; mkdir -p /home/$_CONTAINER_USER/.local && chown -R $_CONTAINER_USER:$_CONTAINER_USER /home/$_CONTAINER_USER/.local'
autostart=true
autorestart=false
startsecs=0
priority=2
stdout_logfile=/var/log/supervisor/diploi-fix-permissions.log
stderr_logfile=/var/log/supervisor/diploi-fix-permissions.err.log

[program:diploi-init]
command=/bin/bash -c 'if [ -f /etc/diploi/init.sh ]; then bash -e /etc/diploi/init.sh; fi'
autostart=true
autorestart=false
startsecs=0
priority=5
stdout_logfile=/var/log/supervisor/diploi-init.log
stderr_logfile=/var/log/supervisor/diploi-init.err.log

[program:opencode]
directory=/app
user=$_CONTAINER_USER
environment=HOME="/home/$_CONTAINER_USER",NODE_PATH="/opt/playwright/global"
command=/usr/local/bin/opencode serve --print-logs --log-level DEBUG --hostname 0.0.0.0 --port 4096
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
priority=30
stdout_logfile=/var/log/supervisor/diploi-opencode.log
stderr_logfile=/var/log/supervisor/diploi-opencode.err.log

EOT

# Leftovers of the installs above, made as root: the user's tools can't write into them
rm -rf /tmp/opencode /tmp/node-compile-cache
