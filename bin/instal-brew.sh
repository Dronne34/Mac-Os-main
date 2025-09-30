#!/bin/bash

# Script pentru instalare Homebrew și pluginuri Zsh lipsă

set -e

# Instalează Homebrew dacă nu există
if ! command -v brew &>/dev/null; then
	echo "Instalez Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
	echo "Homebrew este deja instalat."
fi

# Instalează pluginuri și utilitare lipsă
echo "Instalez pluginuri și utilitare lipsă..."
brew install zsh-syntax-highlighting zsh-autosuggestions fzf zsh-navigation-tools zoxide

# Instalează Oh My Zsh dacă nu există
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	echo "Instalez Oh My Zsh..."
	RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo "Oh My Zsh este deja instalat."
fi


# Instalează tema powerlevel10k dacă nu există
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
	echo "Instalez tema powerlevel10k..."
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k
else
	echo "Tema powerlevel10k este deja instalată."
fi

# Activează fzf
"$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish

echo "\nToate pachetele au fost instalate. Dă un 'source ~/.zshrc' sau deschide un nou terminal pentru a aplica modificările."
