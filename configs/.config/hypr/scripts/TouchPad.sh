#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling touchpad.
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109
#
# [0.56 迁移] `hyprctl keyword '$TOUCHPAD_ENABLED' ...` 变量式 keyword 已移除
#   → hl.device({ name = ..., enabled = ... })
#   ⚠ Laptops.lua 里的 Touchpad_Device = "asue1209:00-04f3:319f-touchpad" 是
#     JaKooLit 默认残留（ASUS 触摸板），与本机 (HP OMEN / Synaptics) 不匹配，
#     故此处改为按名字动态探测。

notif="$HOME/.config/swaync/images/ja.png"

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

TP_NAME=$(hyprctl -j devices | jq -r '[.mice[] | select(.name | test("touchpad"; "i"))] | .[0].name')
if [ -z "$TP_NAME" ] || [ "$TP_NAME" = "null" ]; then
	notify-send -u critical " Touchpad" " 未找到触摸板设备"
	exit 1
fi

enable_touchpad() {
    printf "true" >"$STATUS_FILE"
    notify-send -u low -i $notif  " Enabling" " touchpad"
    hyprctl eval "hl.device({ name = \"$TP_NAME\", enabled = true })"
}

disable_touchpad() {
    printf "false" >"$STATUS_FILE"
    notify-send -u low -i $notif " Disabling" " touchpad"
    hyprctl eval "hl.device({ name = \"$TP_NAME\", enabled = false })"
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
