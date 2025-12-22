#!/bin/bash
# Dotfiles Bootstrap Script for Mac/Linux

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! command -v python3 &> /dev/null; then
    echo "Python3 not found. Attempting to install..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Check for Homebrew
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install python
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y python3
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3
        else
            echo "Unsupported Linux distribution. Please install python3 manually."
            exit 1
        fi
    else
        echo "Unsupported OS: $OSTYPE. Please install python3 manually."
        exit 1
    fi
fi

python3 "$DIR/main.py"
