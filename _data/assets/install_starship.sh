#!/bin/bash

# Function to install fontconfig if not installed
install_fontconfig() {
    if ! dpkg -l fontconfig &>/dev/null; then
        echo "Installing fontconfig..."
        sudo apt update
        sudo apt install -y fontconfig
    fi
}

# Function to install unzip if not installed
install_unzip() {
    if ! command -v unzip &>/dev/null; then
        echo "Installing unzip..."
        sudo apt update
        sudo apt install -y unzip
    fi
}

# Function to install Nerd Font
install_nerd_font() {
    font_name=$1
    echo "Installing $font_name..."
    # Download and install the chosen Nerd Font
    curl -fLo "$font_name.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$font_name.zip
    unzip -o "$font_name.zip" -d ~/.fonts
    rm "$font_name.zip"
    # Refresh font cache
    fc-cache -fv ~/.fonts
}

# Function to install Starship.rs
install_starship() {
    echo "Installing Starship.rs..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)"
    # Append 'eval "$(starship init bash)"' to ~/.bashrc
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    # Check if ~/.config directory exists, if not, create it
    if [ ! -d ~/.config ]; then
        mkdir -p ~/.config
    fi
    # Set default preset to gruvbox-rainbow
    starship preset gruvbox-rainbow -o ~/.config/starship.toml
    # Download and overwrite the Starship configuration file
    curl -fLo ~/.config/starship.toml https://raw.githubusercontent.com/barendbotes/barendbotes.github.io/main/_data/assets/starship.toml
}

# Main script
echo "Select a Nerd Font to install:"
options=("FiraCode" "JetBrainsMono" "Hack" "Quit" "Agave")
select opt in "${options[@]}"; do
    case $opt in
        "FiraCode")
            install_fontconfig
            install_unzip
            install_nerd_font "FiraCode"
            install_starship
            break
            ;;
        "Agave")
            install_fontconfig
            install_unzip
            install_nerd_font "Agave"
            install_starship
            break
            ;;
        "JetBrainsMono")
            install_fontconfig
            install_unzip
            install_nerd_font "JetBrainsMono"
            install_starship
            break
            ;;
        "Hack")
            install_fontconfig
            install_unzip
            install_nerd_font "Hack"
            install_starship
            break
            ;;
        "Quit")
            echo "Quitting..."
            exit 0
            ;;
        *) echo "Invalid option";;
    esac
done
