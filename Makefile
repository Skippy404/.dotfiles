# Skippy's Makefile for .dotfiles
DIR=$(shell pwd)

# Default install
all: setupbin bin install vim bash zsh

update:
	git pull
	@#Update bashrc
	-@[[ -f ~/.backup/.dfBASH ]] && $$(rm ~/.bashrc; make bash) || echo "Completed .bashrc"
	@#Update vim
	-@[[ -f ~/.backup/.dfVIM ]] && $$(rm ~/.vimrc; rm -rf ~/.vim; make vim) || echo "Completed .vimrc"
	@#Update zshrc
	-@[[ -f ~/.backup/.dfZSH ]] && $$(rm ~/.zshrc; make zsh) || echo "Completed .zshrc"
	-@echo "Update Completed!"

submods:
	# Update submodules
	git submodule init
	git submodule update

# Preamble for bin
setupbin:
	[ ! -d ~/bin ] && git clone https://github.com/skiqqy/bin $$HOME/bin || echo "bin already exists"
	mkdir -p ~/bin/local
	cp $(DIR)/miscfiles/scripts/* ~/bin/local/
	-rm -f ~/bin/local/upd # We need to custom build this

# Sets up custom updating script based on install location
bin:
	$(shell echo "INSTALL_LOC=$(PWD)" > ~/bin/local/upd)
	$(shell cat $(DIR)/miscfiles/scripts/upd >> ~/bin/local/upd)
	chmod +x ~/bin/local/upd

# Make backup directory, and setup update script
install:
	mkdir -p ~/.backup

# Install vim configs
vim: install powerline-fonts
	-@rm -rf ~/.backup/.vim # only backup the latest .vim directory
	-@[ -d ~/.vim ] && mv -f ~/.vim ~/.backup || echo "No 'vim/' to backup"
	-@[ -f ~/.vimrc ] && mv -f ~/.vimrc ~/.backup || echo "No '.vimrc' to backup"
	-@touch ~/.backup/.dfVIM # Let's us know that vim configs was installed
	@# link files, and copy requirments
	-@curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
		    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
			|| \
			echo "Curl failed, resulting to emergency plug.vim" && \
			mkdir -p ~/.vim/autoload  && \
			cp $(DIR)/miscfiles/vim/plug.backup ~/.vim/autoload/plug.vim
	ln -s $(DIR)/miscfiles/vim/.vimrc ~/.vimrc # Link to vimrc
	vim -c PlugInstall -c q -c q

# Intall Bash configs
bash: install
	@# only uses simple config for now
	-@[ -f ~/.bashrc ] && mv -f ~/.bashrc ~/.backup || echo "No '.bashrc' to backup"
	-@touch ~/.backup/.dfBASH # Let's us know that bash configs was installed
	@# link files
	-@rm -f $(DIR)/.bashrc_local # We are creating a new one.
	-@cat $(DIR)/miscfiles/bash/.bashrc_1 > $(DIR)/.bashrc_local
	ln -s $(DIR)/.bashrc_local ~/.bashrc

cbash: submods
	@# Handle system info.
	-@echo -n "enable system info (aka neofetch/pfetch), [y/n]: "; \
		read ans; \
		if [ $$ans = "y" ]; then \
			echo "The following are available:"; \
			echo "----------------------------"; \
			echo "(n)eofetch"; \
			echo "(p)fetch"; \
			echo "(f)et.sh"; \
			echo "----------------------------"; \
			echo -n "Please select a letter: "; \
			read ans; \
			case $$ans in \
				"n") \
					echo "Neofetch chosen."; \
					echo "$(DIR)/submodules/neofetch/neofetch" >> "$(DIR)/.bashrc_local"; \
					;; \
				"p") \
					echo "pfetch chosen."; \
					echo "$(DIR)/submodules/pfetch/pfetch" >> "$(DIR)/.bashrc_local"; \
					;; \
				"f") \
					echo "fet.sh chosen."; \
					echo "$(DIR)/submodules/fet.sh/fet.sh" >> "$(DIR)/.bashrc_local"; \
					;; \
				*) \
					echo "Error, Invalid Selection."; \
			esac; \
		fi
	@# Setup thefuck
	-@echo -n "enable thefuck? (y/n): ";\
		read ans; \
		if [ $$ans = "y" ]; then \
			echo "eval \"\$$(thefuck --alias)\"" >> $(DIR)/.bashrc_local; \
		fi

# Install zsh configs
zsh: install
	-@[ -f ~/.zshrc ] && mv -f ~/.zshrc ~/.backup || echo "No '.zshrc' to backup"
	-@touch ~/.backup/.dfZSH # Let's  us know that zsh configs was installed
	@# link files
	ln -s $(DIR)/miscfiles/zsh/.zshrc_1 ~/.zshrc

# Vim dependencies
powerline-fonts:
	@#install powerline-fonts
	git clone https://github.com/powerline/fonts.git --depth=3
	./fonts/install.sh
	rm -rf fonts

# Uninstall, and revert to previous configs
uninstall: install
	@# Check vim status, and do backup if needed
	-@if [ -f ~/.backup/.dfVIM ]; then \
		rm -rf ~/.vim; \
		rm -rf ~/.vimrc; \
		[ -d ~/.backup/.vim ] && mv -f ~/.backup/.vim ~/ || echo "vim/ backup DNE"; \
		[ -f ~/.backup/.vimrc ] && mv -f ~/.backup/.vimrc ~/ || echo ".vimrc backup DNE"; \
		echo "vim uninstall succsesful!"; \
		rm -rf ~/.backup/.dfVIM; \
	fi
	@# Check bash status, and do backup if needed
	-@if [ -f ~/.backup/.dfBASH ]; then \
		rm -rf ~/.bashrc; \
		[ -f ~/.backup/.bashrc ] && mv -f ~/.backup/.bashrc ~/ || echo ".bashrc backup DNE"; \
		for file in $(DIR)/miscfiles/scripts/* ; do \
			rmf=$${file##*/}; \
			rm -f ~/bin/$$rmf; \
		done;\
		if [ ! "ls -A ~/bin" ]; then \
			echo "Deleting ~/bin, since it is empty"; \
			rm -rf ~/bin; \
		fi;\
		echo "bashrc uninstall succsesful!"; \
		rm -rf ~/.backup/.dfBASH; \
	fi
	@# Check zsh status, and fo backup if needed
	-@if [ -f ~/.backup/.dfZSH ]; then \
		rm -rf ~/.zshrc; \
		[ -f ~/.backup/.zshrc ] && mv -f ~/.backup/.zshrc ~/ || echo ".zshrc backup DNE"; \
		echo "zsh uninstall succsesful!"; \
		rm -rf ~/.backup/.dfZSH; \
	fi

test:
	bash .test.sh
