#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/dewdorp/webshell-detection-lab.git}"
REPO_BRANCH="${REPO_BRANCH:-test}"
INSTALL_DIR="${INSTALL_DIR:-/opt/webshell-detection-lab}"
LAB_USER="${LAB_USER:-$USER}"
SKIP_PACKAGES="${SKIP_PACKAGES:-0}"

need_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    return 1
  fi
}

install_packages() {
  if [ "$SKIP_PACKAGES" = "1" ]; then
    echo "Skipping package installation because SKIP_PACKAGES=1"
    return
  fi

  if need_command apt-get; then
    sudo apt-get update
    sudo apt-get install -y git curl nodejs npm php-cli openjdk-17-jdk maven
  elif need_command dnf; then
    sudo dnf install -y git curl nodejs npm php-cli java-17-openjdk-devel maven
  elif need_command yum; then
    sudo yum install -y git curl nodejs npm php-cli java-17-openjdk-devel maven
  else
    echo "No supported package manager found. Install git, node, npm, php, java, and maven manually."
  fi

  if ! need_command dotnet; then
    echo "dotnet CLI not found."
    echo "Install .NET SDK manually for your distribution:"
    echo "https://learn.microsoft.com/dotnet/core/install/linux"
  fi
}

clone_or_update() {
  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing install at $INSTALL_DIR"
    sudo -u "$LAB_USER" git -C "$INSTALL_DIR" pull --ff-only
  else
    echo "Cloning $REPO_URL branch $REPO_BRANCH to $INSTALL_DIR"
    sudo mkdir -p "$(dirname "$INSTALL_DIR")"
    sudo chown "$LAB_USER":"$LAB_USER" "$(dirname "$INSTALL_DIR")"
    sudo -u "$LAB_USER" git clone --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
  fi
}

prepare_lab() {
  sudo chown -R "$LAB_USER":"$LAB_USER" "$INSTALL_DIR"
  chmod +x "$INSTALL_DIR"/scripts/*.sh
  mkdir -p "$INSTALL_DIR/runtime/pids"
  "$INSTALL_DIR/scripts/check-prereqs.sh"
}

install_packages
clone_or_update
prepare_lab

cat <<MSG

Install complete.

Start a runtime:
  cd "$INSTALL_DIR"
  ./scripts/switch-server.sh node
  ./scripts/switch-server.sh php
  ./scripts/switch-server.sh jsp
  ./scripts/switch-server.sh aspnet

Open:
  http://localhost:8080/

Agent watch path:
  $INSTALL_DIR/runtime/current/uploads

If your Agent does not follow symlinks, use the concrete upload path printed by switch-server.sh.
MSG
