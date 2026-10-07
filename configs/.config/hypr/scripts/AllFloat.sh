#!/bin/bash
# All Float Mode（原 SUPER+ALT+SPACE）
# 切换当前工作区全部窗口的浮动状态：非全浮动 → 全部浮动；已全浮动 → 全部取消
#
# [0.56 迁移] 原 `hyprctl dispatch workspaceopt allfloat` 无等价物：
#   allfloat 选项已从 0.56 上游移除（二进制无此字符串；workspace_rule 的
#   layout_opts.allfloat 实测也不被消费）。且旧命令只对 master 布局有效，
#   在 dwindle 下本来就是空操作。
#   这里用逐窗口 float dispatcher（toggle 语义，实测）实现，任何布局下都有效。

notif="$HOME/.config/swaync/images/ja.png"

WS=$(hyprctl -j activeworkspace | jq -r '.id')
TOTAL=$(hyprctl -j clients | jq --argjson ws "$WS" '[.[] | select(.workspace.id == $ws)] | length')
FLOATING=$(hyprctl -j clients | jq --argjson ws "$WS" '[.[] | select(.workspace.id == $ws and .floating)] | length')

[ "$TOTAL" -eq 0 ] && exit 0

if [ "$FLOATING" -eq "$TOTAL" ]; then
	TARGET=false
	MSG=" All Float: OFF"
else
	TARGET=true
	MSG=" All Float: ON"
fi

# 仅对状态与目标不符的窗口调用（float dispatcher 是 toggle）
hyprctl -j clients | jq -r --argjson ws "$WS" --argjson t "$TARGET" \
	'.[] | select(.workspace.id == $ws and .floating != $t) | .address' |
	while read -r addr; do
		hyprctl dispatch "hl.dsp.window.float({ window = \"address:$addr\" })" >/dev/null
	done

notify-send -e -u low -i "$notif" "$MSG"
