
# --- Environment Variables & Tooling ---

fpath=(~/.local/share/zsh/site-functions $fpath)
autoload -U compinit && compinit
# [NEW] Bun Configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# UV Cache Configuration
export UV_CACHE_DIR="/mnt/Storage/uv_cache"
export UV_PYTHON_INSTALL_DIR="/mnt/Storage/files/uv_python"

# LS_COLORS
# export LS_COLORS="$(vivid generate kanagawa)"
# Add local bins
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/scripts/executableFiles/" ]; then
  export PATH="$HOME/scripts/executableFiles:$PATH"
fi

# zsh-defer
source ~/.zsh-defer/zsh-defer.plugin.zsh
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
unsetopt PROMPT_SP
plugins=()

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
# Go
eval "$(mise activate zsh)"
export GOPATH=$HOME/go 
export GOBIN=$GOPATH/bin 
export PATH=$PATH:$GOBIN

# atuin
eval "$(atuin init zsh)"

deferred_init() {
    eval "$(zoxide init zsh)"
    [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
    [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
    [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
}

zsh-defer deferred_init

# --- Aliases ---
alias ls='eza --icons'
alias ll='eza -l --icons'
alias tree='eza --tree'
alias zshrc='nvim ~/.zshrc'
alias cat='bat'
alias pdb='protondb-cli'
alias pdbr='protondb-cli -r 3'
alias kity='nvim ~/.config/kitty/kitty.conf'
alias nt='nexttrace'
alias dua='dua i'
alias hypr='cd ~/.config/hypr'
alias :q='exit'
alias whereami='pwd'
alias yay='p yay'
# alias paru='p paru'
alias upd='update-desktop-database ~/.local/share/applications'
alias wtf='p tldr'
alias iwantto='navi'
alias cheat='cht.sh'
alias trzh='p trans -t zh -b'
alias tren='p trans -t en -b'
alias trno='p trans -t no -b'
alias dzh='p trans -t zh'
alias den='p trans -t en'
alias dno='p trans -t no'
alias http='export http_proxy=http://127.0.0.1:7897'
alias https='export https_proxy=http://127.0.0.1:7897'
alias rclone='p rclone'
alias sto='cd /mnt/Storage'
alias hrun='hyprctl dispatch exec'
alias leet='nvim -c "Leet"'
alias gh='p gh'
alias npm='bun'
alias npx='bunx'
alias de='deactivate'
alias puv='p uv'
alias asktech='noglob lama'
alias ask='ollama run gemini-3-flash-preview'
alias trl='noglob translate'
alias ins='paru -S'
alias insys='sudo pacman -S'
alias nameof='paru -Ss'
alias unins='paru -Rns'
alias fot='nvim ~/.config/foot/foot.ini'
alias infopanel='wtfutil'
alias day='darkman set light'
alias night='darkman set dark'
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias mynat='pystun3'
alias myexactnat='stunclient'
alias crtterm='cool-retro-term'
alias hd2mod='protontricks-launch --appid 553850 /mnt/Storage/HD2ModManager\ 1.3.0.1\ \(EOL\)-109-1-3-0-1-1758909252/Helldivers2ModManager.exe'
# 如果你安装了系统级的 node (sudo pacman -S nodejs)，保留 node 命令指向它作为备用
# 如果你想强制全用 bun，可以解开下面这行：
# alias node='bun'

# --- Functions ---

# Proxy Wrapper
PROXY_HTTP="http://127.0.0.1:7897"
PROXY_SOCKS="socks5://127.0.0.1:7897"

function p() {
    env http_proxy=$PROXY_HTTP \
        https_proxy=$PROXY_HTTP \
        all_proxy=$PROXY_SOCKS \
        HTTP_PROXY=$PROXY_HTTP \
        HTTPS_PROXY=$PROXY_HTTP \
        ALL_PROXY=$PROXY_SOCKS \
        "$@"
}

# [UPDATED] SillyTavern with Bun
st() {
  local target_dir="/mnt/Storage/SillyTavern"

  if [ ! -d "$target_dir" ]; then
    echo "Error: Directory not found: $target_dir"
    return 1
  fi

  (
    cd "$target_dir" || return
    # 检查是否需要初始化依赖
    if [ ! -d "node_modules" ]; then
        echo "⚠️ node_modules not found. Running 'bun install' first..."
        bun install
    fi
    
    echo "🚀 Starting SillyTavern with Bun..."
    # bun start 会读取 package.json 中的 start 脚本
    # 甚至可以直接 bun server.js (如果 ST 的入口是这个)
    bun start "$@"
  )
}

# Random Directory
rand() {
  local target_dir
  target_dir=$(find . -maxdepth 1 -mindepth 1 -type d -print0 | shuf -z -n 1)

  if [[ -z "$target_dir" ]]; then
    echo "No children directory found." >&2
    return 1
  fi

  if [ -t 1 ]; then
    echo "Randomly entering -> ${target_dir#./}"
    cd -- "$target_dir"
  else
    print "%s\n" "$target_dir"
  fi
}


fuck() {
  local text 
  if [ -n "$1" ]; then
    text="$1"
  else
    local fucks=("MotherFuck" "ShitHead" "Dickhead" "Son Of A Bitch" "Cock Sucker" "Shit" "Fuck" "Dogass" "Nigga")
    local random_index=$(( (RANDOM % ${#fucks[@]}) + 1 ))
    text=${fucks[$random_index]}
  fi
  toilet -f mono12 -w $(tput cols) "$text" | lolcat
}

fcopy() {
    [ -z "$1" ] || [ ! -f "$1" ] && echo "Usage: fcopy <file>" && return 1
    wl-copy < "$1" && echo "✔ Copied '$1'."
}

teecopy() {
  [ -z "$1" ] && echo "Usage: teecopy <cmd> | <file>" && return 1
  if [ -f "$1" ] && [ -r "$1" ]; then
    cat "$1" | tee >(wl-copy)
  else
    "$@" | tee >(wl-copy)
  fi
}

n () {
  if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
    echo "nnn is already running."
    return
  fi
  local -x NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/nnn"
  nnn -c "$@"
  if [ -f "$NNN_TMPFILE" ]; then
    . "$NNN_TMPFILE"
    rm -f "$NNN_TMPFILE" > /dev/null
  fi
}

# ==========================================
# Python Virtual Environment Manager (fzf)
# ==========================================
function workon() {
    # 你的 venv 集中存放目录
    local venv_root="/mnt/Storage/python_venvs"

    # 1. 检查目录是否存在
    if [[ ! -d "$venv_root" ]]; then
        echo "❌ 目录不存在: $venv_root"
        return 1
    fi

    # 2. 使用 fzf 选择环境
    # ls -1 罗列名字 -> fzf 进行选择
    # --height, --reverse 是为了界面好看
    # --preview 可以预览该环境下的 python 版本 (可选装逼功能)
    local venv_name=$(ls -1 "$venv_root" | fzf \
        --height 40% \
        --layout=reverse \
        --border \
        --prompt="🐍 Activate Venv > " \
        --header="Ctrl-C to cancel" \
        --preview "echo 'Python Version:'; $venv_root/{}/bin/python --version 2>/dev/null || echo 'Not found'"
    )

    # 3. 如果用户没选直接 Ctrl-C，这就为空，直接返回
    if [[ -z "$venv_name" ]]; then
        return 0
    fi

    local activate_script="$venv_root/$venv_name/bin/activate"

    # 4. 检查 activate 脚本是否存在
    if [[ -f "$activate_script" ]]; then
        # 如果当前已经在某个环境里，先退出来，防止嵌套混乱
        if [[ -n "$VIRTUAL_ENV" ]]; then
            deactivate
        fi
        
        # 激活
        source "$activate_script"
        echo "✅ 已激活环境: \033[1;32m$venv_name\033[0m"
    else
        echo "❌ 错误: 找不到 $activate_script，这可能不是一个有效的 venv。"
    fi
}

# ollama
lama() {
    echo "User: $* \nExplain briefly and show command if user is asking coding or computer related questions. User's Linux distro is EndeavourOS with systemd-boot. If user is not asking technology related questions, just reply normally. Better in Chinese, English is ok too." | ollama run gemini-3-flash-preview
}

translate() {
    echo "User: $* \nYou are a translator from now on. Mainly between English and Chinese, sometimes maybe some Norsk and other languages. Your mission is to translate “信达雅”-ly, but you may also translate in a humanic way or 'Internet' way. Only output the translation result but anything else. Additional requirements of user would be written inside []s. " | ollama run gemini-3-flash-preview
}


# 切换为英文环境
iwannabeenglish() {
    # 使用 localectl 修改系统配置
    sudo localectl set-locale LANG=en_US.UTF-8
    
    echo "Done! System locale set to en_US.UTF-8."
    echo "Note: You need to logout and login (restart Hyprland) to apply changes to GUI apps."
}

# 切换为中文环境
iwannabechinese() {
    sudo localectl set-locale LANG=zh_CN.UTF-8
    
    echo "搞定！系统语言已切换为中文 (zh_CN.UTF-8)。"
    echo "注意：你需要重新登录（重启 Hyprland）才能看到界面变化。"
}


spectro() {
    if [[ -z "$1" ]]; then echo "Usage: spectro <file>"; return 1; fi
    
    # -s 120x40: 这里不再是像素，而是“字符格子数”。
    # 120列宽，40行高，大概占据半个屏幕，你可以自己调。
    # 这里的 ffmpeg 输出分辨率要稍微高一点，方便 chafa 采样
    
    ffmpeg -hide_banner -v error -i "$1" \
           -lavfi "showspectrumpic=s=1200x500:mode=combined:color=rainbow:legend=1" \
           -f image2pipe -c:v png - \
    | chafa -s 120x40 -f symbols -
}

musictags() {
    docker run -d \
  --name musictag \
  -p 8001:8001 \
  -v /mnt/Storage/Music:/app/media \
  -v $HOME/.config/musictag:/app/data \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=022 \
  xhongc/music_tag_web:latest
}

# --- Initialization ---

# bindkey -v
# export KEYTIMEOUT=1


export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
