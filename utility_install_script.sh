#!/usr/bin/env sh

# Cross-platform installation script for zshrc utilities
# Supports macOS (Homebrew) and Fedora Linux (DNF)
# Shell-agnostic: works with both bash and zsh

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_msg "Detected macOS"
  elif [ -f /etc/fedora-release ]; then
    OS="fedora"
    print_msg "Detected Fedora Linux"
  else
    print_error "Unsupported OS. This script supports macOS and Fedora only."
    exit 1
  fi
}

# Install Homebrew on macOS if not present
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    print_msg "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    print_msg "Homebrew already installed"
  fi
}

# Install zsh
install_zsh() {
  if command -v zsh &>/dev/null; then
    print_warning "zsh is already installed, skipping..."
    return
  fi

  print_msg "Installing zsh..."
  if [ "$OS" = "macos" ]; then
    brew install zsh
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y zsh
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

# Install oh-my-zsh if not present
install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    print_warning "oh-my-zsh is already installed, skipping..."
    return
  fi

  print_msg "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# Install eza
install_eza() {
  if command -v eza &>/dev/null; then
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
      ARCH=$(uname -m)
      if [ "$ARCH" = "x86_64" ]; then
        wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
      elif [ "$ARCH" = "aarch64" ]; then
        wget -c https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz -O - | tar xz
      fi
      sudo chmod +x eza
      sudo chown root:root eza
      sudo mv eza /usr/local/bin/eza
    fi
  fi
}

# Install fd (fdfind on Fedora)
install_fd() {
  if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
    print_warning "fd is already installed, skipping..."
    return
  fi

  print_msg "Installing fd..."
  if [ "$OS" = "macos" ]; then
    brew install fd
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y fd-find
    # Create alias in ~/.local/bin if it doesn't exist
    mkdir -p ~/.local/bin
    if [ ! -f ~/.local/bin/fd ]; then
      ln -s $(which fdfind) ~/.local/bin/fd
    fi
  fi
}

# Install bat
install_bat() {
  if command -v bat &>/dev/null; then
    print_warning "bat is already installed, skipping..."
    return
  fi

  print_msg "Installing bat..."
  if [ "$OS" = "macos" ]; then
    brew install bat
  elif [ "$OS" = "fedora" ]; then
    # bat is in the Fedora Modular repository
    sudo dnf install -y bat
  fi
}

# Install fzf
install_fzf() {
  if command -v fzf &>/dev/null; then
    print_warning "fzf is already installed, skipping..."
    return
  fi

  print_msg "Installing fzf..."
  if [ "$OS" = "macos" ]; then
    brew install fzf
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y fzf
  fi
}

# Install git
install_git() {
  if command -v git &>/dev/null; then
    print_warning "git is already installed, skipping..."
    return
  fi

  print_msg "Installing git..."
  if [ "$OS" = "macos" ]; then
    brew install git
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y git
  fi
}

# Install docker
install_docker() {
  if command -v docker &>/dev/null; then
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
    # Add user to docker group
    sudo usermod -aG docker $USER
    print_warning "You need to log out and back in for docker group membership to take effect"
  fi
}

# Install neovim
install_neovim() {
  if command -v nvim &>/dev/null; then
    print_warning "neovim is already installed, skipping..."
    return
  fi

  print_msg "Installing neovim..."
  if [ "$OS" = "macos" ]; then
    brew install neovim
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y neovim
  fi
}

# Install lazygit
install_lazygit() {
  if command -v lazygit &>/dev/null; then
    print_warning "lazygit is already installed, skipping..."
    return
  fi

  print_msg "Installing lazygit..."
  if [ "$OS" = "macos" ]; then
    brew install lazygit
  elif [ "$OS" = "fedora" ]; then
    # Install from COPR
    sudo dnf install -y 'dnf-command(copr)'
    sudo dnf copr enable -y dejan/lazygit
    sudo dnf install -y lazygit
  fi
}

# Install lazydocker
install_lazydocker() {
  if command -v lazydocker &>/dev/null; then
    print_warning "lazydocker is already installed, skipping..."
    return
  fi

  print_msg "Installing lazydocker..."
  if [ "$OS" = "macos" ]; then
    brew install lazydocker
  elif [ "$OS" = "fedora" ]; then
    # Install from COPR
    sudo dnf install -y 'dnf-command(copr)'
    sudo dnf copr enable -y atim/lazydocker
    sudo dnf install -y lazydocker
  fi
}

# Install thefuck
install_thefuck() {
  if command -v thefuck &>/dev/null; then
    print_warning "thefuck is already installed, skipping..."
    return
  fi

  print_msg "Installing thefuck..."
  if [ "$OS" = "macos" ]; then
    brew install thefuck
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y thefuck
  fi
}

# Install starship
install_starship() {
  if command -v starship &>/dev/null; then
    print_warning "starship is already installed, skipping..."
    return
  fi

  print_msg "Installing starship..."
  if [ "$OS" = "macos" ]; then
    brew install starship
  elif [ "$OS" = "fedora" ]; then
    # Install using the official install script
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
}

# Install zoxide
install_zoxide() {
  if command -v zoxide &>/dev/null; then
    print_warning "zoxide is already installed, skipping..."
    return
  fi

  print_msg "Installing zoxide..."
  if [ "$OS" = "macos" ]; then
    brew install zoxide
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y zoxide
  fi
}

# Install fastfetch
install_fastfetch() {
  if command -v fastfetch &>/dev/null; then
    print_warning "fastfetch is already installed, skipping..."
    return
  fi

  print_msg "Installing fastfetch..."
  if [ "$OS" = "macos" ]; then
    brew install fastfetch
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y fastfetch
  fi
}

# Install nvm
install_nvm() {
  if [ -d "$HOME/.nvm" ] || command -v nvm &>/dev/null; then
    print_warning "nvm is already installed, skipping..."
    return
  fi

  print_msg "Installing nvm..."
  if [ "$OS" = "macos" ]; then
    brew install nvm
    mkdir -p ~/.nvm
  elif [ "$OS" = "fedora" ]; then
    # Install nvm using the official install script
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
}

# Install rbenv
install_rbenv() {
  if command -v rbenv &>/dev/null; then
    print_warning "rbenv is already installed, skipping..."
    return
  fi

  print_msg "Installing rbenv..."
  if [ "$OS" = "macos" ]; then
    brew install rbenv ruby-build
  elif [ "$OS" = "fedora" ]; then
    sudo dnf install -y rbenv
  fi
}

# Install mise (formerly rtx)
install_mise() {
  if command -v mise &>/dev/null; then
    print_warning "mise is already installed, skipping..."
    return
  fi

  print_msg "Installing mise..."
  if [ "$OS" = "macos" ]; then
    brew install mise
  elif [ "$OS" = "fedora" ]; then
    # Install using the official install script
    curl https://mise.run | sh
  fi
}

# Install oh-my-zsh if not present
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_msg "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    print_msg "oh-my-zsh already installed"
  fi
}

# Install oh-my-zsh if not present
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_msg "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    print_msg "oh-my-zsh already installed"
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
  fi

  echo ""
  print_msg "Installing zsh and oh-my-zsh..."
  install_zsh
  change_shell_to_zsh
  install_oh_my_zsh

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

  # Development tools
  install_docker
  install_lazygit
  install_lazydocker

  # Version managers
  install_nvm
  install_rbenv
  install_mise

  # Shell enhancements
  install_starship
  install_zoxide
  install_fastfetch

  echo ""
  print_msg "Installation complete!"
  print_msg "Please log out and back in (or restart your terminal) for shell changes to take effect"
  print_msg "After logging back in, run 'source ~/.zshrc' to apply all configurations"

  if [ "$OS" = "fedora" ]; then
    echo ""
    print_warning "Note: If you installed Docker, you need to log out and back in for group changes to take effect"
    print_warning "Note: On Fedora, 'fd' command is available at ~/.local/bin/fd (make sure ~/.local/bin is in your PATH)"
  fi
}

# Run main function
main
