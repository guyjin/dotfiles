#!/usr/bin/env sh

# Cross-platform installation script for zshrc utilities
# Supports macOS (Homebrew), Fedora Linux (DNF), and Arch Linux (pacman)
# Shell-agnostic: works with both bash and zsh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_question() {
    echo -e "${BLUE}[?]${NC} $1"
}

# Detect OS
detect_os() {
    local detected_os=""
    
    if [ "$(uname)" = "Darwin" ]; then
        detected_os="macos"
    elif [ -f /etc/arch-release ]; then
        detected_os="arch"
    elif [ -f /etc/fedora-release ]; then
        detected_os="fedora"
    else
        detected_os="unknown"
    fi
    
    # Display detected OS
    if [ "$detected_os" != "unknown" ]; then
        print_msg "Detected: ${detected_os}"
        print_question "Is this correct? (y/n): "
        read -r confirm
        
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || [ "$confirm" = "yes" ]; then
            OS="$detected_os"
            return
        fi
    fi
    
    # Manual selection
    echo ""
    print_msg "Please select your operating system:"
    echo "  1) macOS"
    echo "  2) Fedora Linux"
    echo "  3) Arch Linux"
    print_question "Enter your choice (1-3): "
    read -r choice
    
    case "$choice" in
        1) OS="macos" ;;
        2) OS="fedora" ;;
        3) OS="arch" ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    print_msg "Selected: $OS"
}

# Install Homebrew on macOS if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_msg "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_msg "Homebrew already installed"
    fi
}

# Install Paru AUR helper on Arch if not present
install_paru() {
    if command -v paru &> /dev/null; then
        print_msg "Paru already installed"
        return
    fi
    
    if command -v yay &> /dev/null; then
        print_msg "Yay already installed, skipping Paru installation"
        return
    fi
    
    print_msg "Installing Paru AUR helper..."
    
    # Install required dependencies
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone paru from AUR
    cd ~
    git clone https://aur.archlinux.org/paru-bin.git
    cd ~/paru-bin/
    
    # Build and install paru
    makepkg -si --noconfirm
    
    # Clean up
    cd ~
    rm -rf ~/paru-bin/
    
    print_msg "Paru installed successfully"
}

# Get the AUR helper command (paru or yay)
get_aur_helper() {
    if command -v paru &> /dev/null; then
        echo "paru"
    elif command -v yay &> /dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

# Install zsh
install_zsh() {
    if command -v zsh &> /dev/null; then
        print_warning "zsh is already installed, skipping..."
        return
    fi
    
    print_msg "Installing zsh..."
    if [ "$OS" = "macos" ]; then
        brew install zsh
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y zsh
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm zsh
    fi
}

# Change default shell to zsh
change_shell_to_zsh() {
    # Check if current shell is already zsh
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_warning "Default shell is already zsh, skipping..."
        return
    fi
    
    print_msg "Changing default shell to zsh..."
    
    # Make sure zsh is in /etc/shells
    if ! grep -q "$(which zsh)" /etc/shells; then
        print_msg "Adding zsh to /etc/shells..."
        echo "$(which zsh)" | sudo tee -a /etc/shells
    fi
    
    # Change the default shell
    chsh -s "$(which zsh)"
    print_msg "Default shell changed to zsh. You'll need to log out and back in for this to take effect."
}

# Install oh-my-zsh if not present
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "oh-my-zsh is already installed, skipping..."
        return
    fi
    
    print_msg "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# Ensure ~/.local/bin is in PATH
setup_local_bin() {
    # Create ~/.local/bin if it doesn't exist
    mkdir -p "$HOME/.local/bin"
    
    # Check if ~/.local/bin is already in PATH
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) 
            print_warning "~/.local/bin is already in PATH, skipping..."
            return
            ;;
    esac
    
    print_msg "Adding ~/.local/bin to PATH in ~/.zshrc..."
    
    # Add to .zshrc if it exists and doesn't already have the PATH export
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"; then
            echo '' >> "$HOME/.zshrc"
            echo '# Add ~/.local/bin to PATH' >> "$HOME/.zshrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            print_msg "Added ~/.local/bin to PATH in ~/.zshrc"
        fi
    fi
    
    # Also add to current session
    export PATH="$HOME/.local/bin:$PATH"
}

# Install eza
install_eza() {
    if command -v eza &> /dev/null; then
        print_warning "eza is already installed, skipping..."
        return
    fi
    
    print_msg "Installing eza..."
    if [ "$OS" = "macos" ]; then
        brew install eza
    elif [ "$OS" = "fedora" ]; then
        # Check Fedora version
        FEDORA_VERSION=$(rpm -E %fedora)
        if [ "$FEDORA_VERSION" -lt 42 ]; then
            sudo dnf install -y eza
        else
            # Fedora 42+ - eza removed from official repos, install from GitHub
            print_warning "Fedora 42+ detected. Installing eza from GitHub releases..."
            mkdir -p "$HOME/.local/bin"
            ARCH=$(uname -m)
            if [ "$ARCH" = "x86_64" ]; then
                wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
            elif [ "$ARCH" = "aarch64" ]; then
                wget -c https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz -O - | tar xz
            fi
            chmod +x eza
            mv eza "$HOME/.local/bin/eza"
            print_msg "eza installed to ~/.local/bin/eza"
        fi
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm eza
    fi
}

# Install fd (fdfind on Fedora)
install_fd() {
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        print_warning "fd is already installed, skipping..."
        return
    fi
    
    print_msg "Installing fd..."
    if [ "$OS" = "macos" ]; then
        brew install fd
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y fd-find
        # Create symlink in ~/.local/bin
        mkdir -p ~/.local/bin
        if [ ! -f ~/.local/bin/fd ]; then
            ln -s $(which fdfind) ~/.local/bin/fd
        fi
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm fd
    fi
}

# Install bat
install_bat() {
    if command -v bat &> /dev/null; then
        print_warning "bat is already installed, skipping..."
        return
    fi
    
    print_msg "Installing bat..."
    if [ "$OS" = "macos" ]; then
        brew install bat
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y bat
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm bat
    fi
}

# Install fzf
install_fzf() {
    if command -v fzf &> /dev/null; then
        print_warning "fzf is already installed, skipping..."
        return
    fi
    
    print_msg "Installing fzf..."
    if [ "$OS" = "macos" ]; then
        brew install fzf
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y fzf
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm fzf
    fi
}

# Install git
install_git() {
    if command -v git &> /dev/null; then
        print_warning "git is already installed, skipping..."
        return
    fi
    
    print_msg "Installing git..."
    if [ "$OS" = "macos" ]; then
        brew install git
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y git
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm git
    fi
}

# Install docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_warning "docker is already installed, skipping..."
        return
    fi
    
    print_msg "Installing docker..."
    if [ "$OS" = "macos" ]; then
        brew install --cask docker
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y moby-engine docker-compose
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        print_warning "You need to log out and back in for docker group membership to take effect"
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm docker docker-compose
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        print_warning "You need to log out and back in for docker group membership to take effect"
    fi
}

# Install neovim
install_neovim() {
    if command -v nvim &> /dev/null; then
        print_warning "neovim is already installed, skipping..."
        return
    fi
    
    print_msg "Installing neovim..."
    if [ "$OS" = "macos" ]; then
        brew install neovim
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y neovim
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm neovim
    fi
}

# Install lazygit
install_lazygit() {
    if command -v lazygit &> /dev/null; then
        print_warning "lazygit is already installed, skipping..."
        return
    fi
    
    print_msg "Installing lazygit..."
    if [ "$OS" = "macos" ]; then
        brew install lazygit
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y 'dnf-command(copr)'
        sudo dnf copr enable -y dejan/lazygit
        sudo dnf install -y lazygit
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm lazygit
    fi
}

# Install lazydocker
install_lazydocker() {
    if command -v lazydocker &> /dev/null; then
        print_warning "lazydocker is already installed, skipping..."
        return
    fi
    
    print_msg "Installing lazydocker..."
    if [ "$OS" = "macos" ]; then
        brew install lazydocker
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y 'dnf-command(copr)'
        sudo dnf copr enable -y atim/lazydocker
        sudo dnf install -y lazydocker
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm lazydocker
    fi
}

# Install thefuck
install_thefuck() {
    if command -v thefuck &> /dev/null; then
        print_warning "thefuck is already installed, skipping..."
        return
    fi
    
    print_msg "Installing thefuck..."
    if [ "$OS" = "macos" ]; then
        brew install thefuck
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y thefuck
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm thefuck
    fi
}

# Install starship
install_starship() {
    if command -v starship &> /dev/null; then
        print_warning "starship is already installed, skipping..."
        return
    fi
    
    print_msg "Installing starship..."
    if [ "$OS" = "macos" ]; then
        brew install starship
    elif [ "$OS" = "fedora" ]; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm starship
    fi
}

# Install zoxide
install_zoxide() {
    if command -v zoxide &> /dev/null; then
        print_warning "zoxide is already installed, skipping..."
        return
    fi
    
    print_msg "Installing zoxide..."
    if [ "$OS" = "macos" ]; then
        brew install zoxide
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y zoxide
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm zoxide
    fi
}

# Install fastfetch
install_fastfetch() {
    if command -v fastfetch &> /dev/null; then
        print_warning "fastfetch is already installed, skipping..."
        return
    fi
    
    print_msg "Installing fastfetch..."
    if [ "$OS" = "macos" ]; then
        brew install fastfetch
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y fastfetch
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm fastfetch
    fi
}

# Install stow
install_stow() {
    if command -v stow &> /dev/null; then
        print_warning "stow is already installed, skipping..."
        return
    fi
    
    print_msg "Installing stow..."
    if [ "$OS" = "macos" ]; then
        brew install stow
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y stow
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm stow
    fi
}

# Clone and setup dotfiles with stow
setup_dotfiles() {
    local DOTFILES_DIR="$HOME/dotfiles"
    local DOTFILES_REPO="https://github.com/guyjin/dotfiles.git"
    
    print_msg "Setting up dotfiles..."
    
    # Clone dotfiles repo if it doesn't exist
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_msg "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        print_warning "Dotfiles directory already exists at $DOTFILES_DIR"
        print_question "Do you want to update it? (y/n): "
        read -r update_dotfiles
        if [ "$update_dotfiles" = "y" ] || [ "$update_dotfiles" = "Y" ]; then
            print_msg "Updating dotfiles repository..."
            cd "$DOTFILES_DIR"
            git pull
            cd ~
        fi
    fi
    
    # Stow packages
    print_msg "Creating symlinks with stow..."
    cd "$DOTFILES_DIR"
    
    # Common packages for all platforms
    PACKAGES="btop ghostty kitty nvim ranger thefuck tmux zellij zshrc"
    
    # Add macOS-specific packages
    if [ "$OS" = "macos" ]; then
        PACKAGES="$PACKAGES karabiner"
    fi
    
    # Add Linux-specific packages
    if [ "$OS" = "fedora" ] || [ "$OS" = "arch" ]; then
        PACKAGES="$PACKAGES niri"
    fi
    
    for package in $PACKAGES; do
        if [ -d "$package" ]; then
            print_msg "Stowing $package..."
            # Use --adopt to handle existing files by moving them into the stow directory
            # Use --no-folding to create individual symlinks instead of symlinking entire directories
            stow --restow --target="$HOME" "$package" 2>/dev/null || {
                print_warning "Conflicts detected for $package. Attempting to resolve..."
                stow --adopt --target="$HOME" "$package" 2>/dev/null && \
                print_msg "$package stowed (existing files adopted)" || \
                print_warning "Could not stow $package - manual intervention may be needed"
            }
        fi
    done
    
    cd ~
    print_msg "Dotfiles setup complete!"
}

# Install nvm
install_nvm() {
    if [ -d "$HOME/.nvm" ] || command -v nvm &> /dev/null; then
        print_warning "nvm is already installed, skipping..."
        return
    fi
    
    print_msg "Installing nvm..."
    if [ "$OS" = "macos" ]; then
        brew install nvm
        mkdir -p ~/.nvm
    elif [ "$OS" = "fedora" ] || [ "$OS" = "arch" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
}

# Install rbenv
install_rbenv() {
    if command -v rbenv &> /dev/null; then
        print_warning "rbenv is already installed, skipping..."
        return
    fi
    
    print_msg "Installing rbenv..."
    if [ "$OS" = "macos" ]; then
        brew install rbenv ruby-build
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y rbenv
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm rbenv
    fi
}

# Install mise (formerly rtx)
install_mise() {
    if command -v mise &> /dev/null; then
        print_warning "mise is already installed, skipping..."
        return
    fi
    
    print_msg "Installing mise..."
    if [ "$OS" = "macos" ]; then
        brew install mise
    elif [ "$OS" = "fedora" ] || [ "$OS" = "arch" ]; then
        curl https://mise.run | sh
    fi
}

# Install 1Password
install_1password() {
    if command -v 1password &> /dev/null; then
        print_warning "1Password is already installed, skipping..."
        return
    fi
    
    print_msg "Installing 1Password..."
    if [ "$OS" = "macos" ]; then
        brew install --cask 1password
    elif [ "$OS" = "fedora" ]; then
        print_msg "Adding 1Password repository..."
        sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
        sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
        sudo dnf install -y 1password
    elif [ "$OS" = "arch" ]; then
        AUR_HELPER=$(get_aur_helper)
        if [ -n "$AUR_HELPER" ]; then
            print_msg "Installing 1Password from AUR using $AUR_HELPER..."
            $AUR_HELPER -S --noconfirm 1password
        else
            print_error "No AUR helper found. This shouldn't happen - paru should have been installed."
        fi
    fi
}

# Install 1Password CLI
install_1password_cli() {
    if command -v op &> /dev/null; then
        print_warning "1Password CLI is already installed, skipping..."
        return
    fi
    
    print_msg "Installing 1Password CLI..."
    if [ "$OS" = "macos" ]; then
        brew install --cask 1password-cli
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y 1password-cli
    elif [ "$OS" = "arch" ]; then
        AUR_HELPER=$(get_aur_helper)
        if [ -n "$AUR_HELPER" ]; then
            print_msg "Installing 1Password CLI from AUR using $AUR_HELPER..."
            $AUR_HELPER -S --noconfirm 1password-cli
        else
            print_error "No AUR helper found. This shouldn't happen - paru should have been installed."
        fi
    fi
}

# Main installation function
main() {
    print_msg "Starting installation of utilities..."
    echo ""
    
    detect_os
    
    if [ "$OS" = "macos" ]; then
        install_homebrew
    elif [ "$OS" = "fedora" ]; then
        print_msg "Updating system packages..."
        sudo dnf update -y
    elif [ "$OS" = "arch" ]; then
        print_msg "Updating system packages..."
        sudo pacman -Syu --noconfirm
        echo ""
        print_msg "Installing Paru AUR helper..."
        install_paru
    fi
    
    echo ""
    print_msg "Installing zsh and oh-my-zsh..."
    install_zsh
    change_shell_to_zsh
    install_oh_my_zsh
    setup_local_bin
    
    echo ""
    print_msg "Installing command-line utilities..."
    
    # Core utilities
    install_git
    install_neovim
    install_eza
    install_fd
    install_bat
    install_fzf
    install_thefuck
    install_stow
    
    # Development tools
    install_docker
    install_lazygit
    install_lazydocker
    
    # Version managers
    install_nvm
    install_rbenv
    install_mise
    
    # Password management
    install_1password
    install_1password_cli
    
    # Shell enhancements
    install_starship
    install_zoxide
    install_fastfetch
    
    echo ""
    print_msg "Setting up dotfiles with stow..."
    setup_dotfiles
    
    echo ""
    print_msg "Installation complete!"
    print_msg "~/.local/bin has been added to your PATH in ~/.zshrc"
    print_msg "Please log out and back in (or restart your terminal) for shell changes to take effect"
    print_msg "After logging back in, run 'source ~/.zshrc' to apply all configurations"
    
    if [ "$OS" = "fedora" ]; then
        echo ""
        print_warning "Note: If you installed Docker, you need to log out and back in for group changes to take effect"
        print_warning "Note: On Fedora, 'fd' symlink has been created at ~/.local/bin/fd"
    elif [ "$OS" = "arch" ]; then
        echo ""
        print_warning "Note: If you installed Docker, you need to log out and back in for group changes to take effect"
        AUR_HELPER=$(get_aur_helper)
        if [ -n "$AUR_HELPER" ]; then
            print_msg "AUR helper installed: $AUR_HELPER"
        fi
    fi
}

# Run main function
main
