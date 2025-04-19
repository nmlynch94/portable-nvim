FROM --platform=linux/amd64 ubuntu:latest

# Config
ARG BUILD_DEPS="ninja-build gettext cmake curl build-essential"
ARG RUN_DEPS="gcc g++ git fzf markdownlint python3-pip python3-venv shellcheck tmux sudo unzip curl wget zsh golang terraform"
ARG NVIM_COMMIT_SHA="a99c469e547fc59472d6d105c0fae323958297a1"
ARG ZSH_PLUGINS="git aws zsh-vi-mode zsh-autosuggestions"
ARG USERNAME="nlynch"
ARG HOME_DIR="/home/${USERNAME}"
ARG DOTFILES_REPO="https://github.com/nmlynch94/dotfiles.git"
ARG XDG_CONFIG_HOME="${HOME_DIR}/.config"
ARG HASHICORP_FINGERPRINT="798A EC65 4E5C 1542 8C8E 42EE AA16 FCBC A621 E701"

ENV XDG_CONFIG_HOME="${XDG_CONFIG_HOME}"
ENV TMUX_PLUGIN_MANAGER_PATH="${XDG_CONFIG_HOME}/tmux/plugins/tpm"

RUN set -x && apt-get update -y \
	&& apt-get install -y gnupg software-properties-common wget \
	&& wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
	&& apt-get update -y && apt-get install -y ${BUILD_DEPS} ${RUN_DEPS} \
	&& curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
	&& unzip awscliv2.zip \
	&& ./aws/install

RUN git clone https://github.com/neovim/neovim.git \
	&& cd neovim \
	&& git checkout ${NVIM_COMMIT_SHA} \
	&& make CMAKE_BUILD_TYPE=RelWithDebInfo \
	&& make install \
	&& cd .. \
	&& rm -r neovim

RUN adduser --shell /bin/zsh ${USERNAME} \
	&& adduser ${USERNAME} sudo


USER ${USERNAME}

WORKDIR ${HOME_DIR}

RUN git clone --recurse-submodules "${DOTFILES_REPO}" "${HOME_DIR}/dotfiles" \
	&& cp -r ./dotfiles/.[!.]* ./ \
	# Install oh my zsh
	&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
	# Install zsh vi mode, and zsh-autosuggestions
	&& mkdir -p "${HOME_DIR}/.oh-my-zsh/custom/plugins" \
	&& git clone https://github.com/jeffreytse/zsh-vi-mode "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-vi-mode" \
	&& git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
	# Done custom oh my zsh plugins
	&& sed -i "s/plugins=(git)/plugins=(${ZSH_PLUGINS})/g" .zshrc \
	&& echo "export XDG_CONFIG_HOME=${HOME_DIR}/.config" >> ${HOME_DIR}/.zshrc \
	# Install tmux plugins
	&& "${XDG_CONFIG_HOME}/tmux/plugins/tpm/scripts/install_plugins.sh" \
	# Install nvim plugins from dotfiles
	&& nvim --headless "+Lazy! sync" +qa

USER root

# Cleanup packages
RUN apt-get remove "${BUILD_DEPS}" -y \
	&& apt-get autoremove -y \
	&& rm -rf "${HOME_DIR}/dotfiles"

USER ${USERNAME}

VOLUME ["${HOME_DIR}"]

CMD ["/bin/zsh"]
