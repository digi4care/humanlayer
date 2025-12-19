#!/usr/bin/env bash

set -e

# Detect platform
case "$(uname -s)" in
    Linux*)
        if [ -n "$CI" ]; then
            echo "📦 Installing Linux-specific dependencies for CI..."
            # Note: apt packages are handled by GitHub Actions cache
            # This is a placeholder for any additional Linux setup
        else
            if [ -n "${HUMANLAYER_SKIP_PLATFORM_DEPS:-}" ]; then
                echo "📦 Skipping platform dependency installation (HUMANLAYER_SKIP_PLATFORM_DEPS=1)"
                exit 0
            fi
            echo "📦 Checking Linux-specific dependencies for Tauri..."

            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
            else
                echo "⚠️  Cannot detect Linux distribution. Please install Tauri dependencies manually."
                exit 0
            fi

            # Function to check if a command exists
            command_exists() {
                command -v "$1" >/dev/null 2>&1
            }

            case "$DISTRO" in
                arch|manjaro)
                    echo "Detected Arch Linux/Manjaro"
                    if command_exists pacman; then
                        # Check if webkit2gtk-4.1 is installed (key dependency)
                        if pacman -Qs webkit2gtk-4.1 >/dev/null 2>&1; then
                            echo "✅ Tauri dependencies already installed"
                        else
                            echo "Installing Tauri dependencies via pacman..."
                            sudo pacman -S --needed --noconfirm webkit2gtk-4.1 base-devel curl wget openssl gtk3 libappindicator-gtk3 librsvg || {
                                echo "❌ Failed to install packages. Please run manually:"
                                echo "   sudo pacman -S webkit2gtk-4.1 base-devel curl wget openssl gtk3 libappindicator-gtk3 librsvg"
                                exit 1
                            }
                            echo "✅ Tauri dependencies installed successfully"
                        fi
                    else
                        echo "❌ pacman not found. Please install dependencies manually."
                        exit 1
                    fi
                    ;;
                ubuntu|debian|pop|linuxmint)
                    echo "Detected Debian/Ubuntu-based distribution"
                    if command_exists apt-get; then
                        # Check if webkit2gtk-4.1 is installed (key dependency)
                        if dpkg -l | grep -q libwebkit2gtk-4.1-dev 2>/dev/null; then
                            echo "✅ Tauri dependencies already installed"
                        else
                            echo "Installing Tauri dependencies via apt..."
                            sudo apt-get update
                            sudo apt-get install -y libwebkit2gtk-4.1-dev build-essential curl wget file libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev || {
                                echo "❌ Failed to install packages. Please run manually:"
                                echo "   sudo apt-get install libwebkit2gtk-4.1-dev build-essential curl wget file libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev"
                                exit 1
                            }
                            echo "✅ Tauri dependencies installed successfully"
                        fi
                    else
                        echo "❌ apt-get not found. Please install dependencies manually."
                        exit 1
                    fi
                    ;;
                fedora|rhel|centos)
                    echo "Detected Fedora/RHEL-based distribution"
                    if command_exists dnf; then
                        echo "Installing Tauri dependencies via dnf..."
                        sudo dnf install -y webkit2gtk4.1-devel openssl-devel curl wget file gcc gcc-c++ make gtk3-devel libappindicator-gtk3-devel librsvg2-devel || {
                            echo "❌ Failed to install packages. Please run manually:"
                            echo "   sudo dnf install webkit2gtk4.1-devel openssl-devel curl wget file gcc gcc-c++ make gtk3-devel libappindicator-gtk3-devel librsvg2-devel"
                            exit 1
                        }
                        echo "✅ Tauri dependencies installed successfully"
                    elif command_exists yum; then
                        echo "Installing Tauri dependencies via yum..."
                        sudo yum install -y webkit2gtk4.1-devel openssl-devel curl wget file gcc gcc-c++ make gtk3-devel libappindicator-gtk3-devel librsvg2-devel || {
                            echo "❌ Failed to install packages. Please run manually:"
                            echo "   sudo yum install webkit2gtk4.1-devel openssl-devel curl wget file gcc gcc-c++ make gtk3-devel libappindicator-gtk3-devel librsvg2-devel"
                            exit 1
                        }
                        echo "✅ Tauri dependencies installed successfully"
                    else
                        echo "❌ Neither dnf nor yum found. Please install dependencies manually."
                        exit 1
                    fi
                    ;;
                opensuse*|sles)
                    echo "Detected openSUSE/SLES"
                    if command_exists zypper; then
                        echo "Installing Tauri dependencies via zypper..."
                        sudo zypper install -y webkit2gtk3-devel libopenssl-devel curl wget file gcc gcc-c++ make gtk3-devel libappindicator3-devel librsvg-devel || {
                            echo "❌ Failed to install packages. Please run manually:"
                            echo "   sudo zypper install webkit2gtk3-devel libopenssl-devel curl wget file gcc gcc-c++ make gtk3-devel libappindicator3-devel librsvg-devel"
                            exit 1
                        }
                        echo "✅ Tauri dependencies installed successfully"
                    else
                        echo "❌ zypper not found. Please install dependencies manually."
                        exit 1
                    fi
                    ;;
                *)
                    echo "⚠️  Unsupported distribution: $DISTRO"
                    echo "Please install Tauri dependencies manually. See:"
                    echo "https://tauri.app/v1/guides/getting-started/prerequisites#setting-up-linux"
                    exit 0
                    ;;
            esac
        fi
        ;;
    Darwin*)
        # macOS-specific setup if needed
        # Tauri dependencies are typically already available on macOS
        ;;
esac