#!/bin/bash
#Variables
DISTRO=$(grep -h ID_LIKE /etc/os-release| gawk -F= '{print $2}')
PACKAGES=("git" "fish" "gh" "podman" "git" "wget")
UNINSTALLPACKAGES=("nano")
# Functions
prompt_confirm() {
    #trap, save, and reset nocasematch after function execute
    trap "$(shopt -p nocasematch)" RETURN
    shopt -s nocasematch
    while true
        do read -p 'Confirm with (y)es/(n)o: ' confirm
        case $confirm in
            y | yes) return 0;;
            n | no) return 1;;
            * ) echo -e "Invalid Input...\nTry Again."
        esac
    done
}
ubuntu() {
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    source /etc/os-release
    sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
    wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add -
    sudo add-apt-repository universe
    sudo add-apt-repository multiverse
    sudo apt update
    sudo apt remove ${UNINSTALLPACKAGES[*]}
    sudo apt upgrade -y
    sudo apt install -y ${PACKAGES[*]}
}
fedora() {
    if ! $(command -v rpm-ostree)
        then sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf config-manager --add-repo https://rpmsphere.github.io/rpmsphere.repo
        sudo dnf update
        dnf remove ${UNINSTALLPACKAGES[*]}
        sudo dnf upgrade -y
        sudo dnf install -y ${PACKAGES[*]}
    else
        sudo rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo ostree remote add GitHub-CLI https://cli.github.com/packages/rpm/gh-cli.repo
        sudo ostree remote add RPMSphere --add-repo https://rpmsphere.github.io/rpmsphere.repo
        sudo rpm-ostree update
        sudo rpm-ostree uninstall ${UNINSTALLPACKAGES[*]}
        sudo rpm-ostree upgrade -y
        sudo rpm-ostree install -y ${PACKAGES[*]}
    fi
}
listpkg() {
    for pkg in ${PACKAGES[@]}
        do echo "Packages to be installed: ${#PACKAGES[@]}"
        for pkg in ${PACKAGES[@]}
            do echo $pkg
        done
        echo "Packages to be uninstalled: ${#UNINSTALLPACKAGES[@]}"
        for pkg in ${UNINSTALLPACKAGES[@]}
            do echo -$pkg
        done
}
# Execute
wget https://github.com/KenricYoung/dotfiles/archive/refs/heads/main.zip
unzip main.zip
cd dotfiles-main
cp .gitconfig ~/
sudo cp completion/completion.gh.bash /etc/bash_completion.d/
if ! [ -d ~/.config/fish/completions]
    then mkdir -p ~/.config/fish/completions/
fi
cp completion/completion.gh.fish ~/.config/fish/completions/
echo "System Info"
echo "$DISTRO-based"
#WSL Checks
if $(dmesg | grep -q "Hypervisor detected") then
    echo -e "WSL detected\nAdditional packages will be installed"
    #$PACKAGES+=
fi
sleep 2s
listpkg
if ! $(prompt_confirm)
    echo "Canceling installation"
    exit
fi

# Distribution check
if [$DISTRO = ubuntu] 
    then
        ubuntu
        echo "Packages installed"
elif [$DISTRO = fedora]; then
    fedora
    echo "Packages installed"
else
    echo "Unknown distribution. Canceling installation"
    exit
fi
# WSL fixes
if $(uname -r | grep -q "microsoft") then
    # GPG fix
    if ! [ -f ~/.gnupg/gpg-agent.conf ]  || ! $(grep -q pinentry-program ~/.gnupg/gpg-agent.conf)
    echo 'pinentry-program "/mnt/c/Program Files (x86)/Gpg4win/bin/pinentry.exe"' >> ~/.gnupg/gpg-agent.conf
    fi
    # Git Fix
    if ! [ -f ~/.gitconfig ] || ! $(grep -q  helper ~/.gitconfig)
    echo -e  '[credential]\n\thelper = /mnt/c/Users/kenri/AppData/Local/Programs/Git\ Credential\ Manager/git-credential-manager-core.exe' >> .gitconfig
    fi
fi