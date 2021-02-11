install:
	@stow -vS --no-folding config
	@fc-cache

clean:
	@stow -vD --no-folding config

init:
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	cargo install starship

init-mac: init
	brew install rust
	brew install exa

plugins:
	git clone https://github.com/zsh-users/zsh-autosuggestions.git $(ZSH_CUSTOM:-~/.oh-my-zsh/custom)/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $(ZSH_CUSTOM:-~/.oh-my-zsh/custom)/plugins/zsh-syntax-highlighting


