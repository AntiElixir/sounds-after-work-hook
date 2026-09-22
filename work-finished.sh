#!/usr/bin/env bash
# work-finished — announce that the agent finished its turn and is waiting on you.
#
# Wired into:
#   Claude Code  ~/.claude/settings.json -> hooks.Stop
#   Codex        ~/.codex/hooks.json     -> Stop
#
# Location-independent: sounds live in ./sounds next to this script.
# Drop a new mp3 in there and it joins the rotation automatically.
#
# ── 为什么不是"每个 turn 结束都响" ─────────────────────────────────────────
# Codex 开了 goals 之后会自己续跑：一个 turn 结束，1 秒后自动提交下一个 turn，
# 直到 goal 变成 complete/blocked/paused。每个 turn 结束都会触发 Stop，
# 于是 goal 跑十分钟就响十几次 —— 但任务并没有完成，你也不需要做任何事。
#
# 所以这里加一道判定：session 有 status='active' 的 goal 就静默。goal 停下来
# （complete / blocked / paused / usage_limited / budget_limited）才响。
# 普通交互没有 goal 行，查不到 → 照常即时响，不受影响。
#
# 读的是 ~/.codex/goals_1.sqlite 的 thread_goals 表。这是 Codex 内部表结构，
# 不是公开 API，以后版本改了可能失效。失效方向是安全的：查不到就一直响
# （退化成旧行为），不会变成漏报。
#
# ── 当前语音（./sounds，regen 示例，在本目录下执行）─────────────────────────
#   哥哥工作完成啦-晓晓暖声.mp3  Xiaoxiao +20Hz
#     uvx edge-tts --voice zh-CN-XiaoxiaoNeural --pitch=+20Hz \
#       --text "哥哥，工作完成啦～" --write-media ./sounds/哥哥工作完成啦-晓晓暖声.mp3
#   干完了干完了-低沉霸总.mp3  Yunxi   -15Hz +25%
#     uvx edge-tts --voice zh-CN-YunxiNeural --pitch=-15Hz --rate=+25% \
#       --text "干完了，干完了。" --write-media ./sounds/干完了干完了-低沉霸总.mp3
#   干完了干完了-浑厚霸总.mp3  Yunjian -10Hz +25%
#   干完了干完了-沉稳霸总.mp3  Yunyang -20Hz +10%
#   干完了干完了-少年霸总.mp3  Yunxia  -25Hz +25%
#   Over-霸总.mp3              Yunxi   -15Hz -5%, text "Over."
#
#   ffmpeg 也可以后处理：asetrate=<sr>*N,aresample=<sr>,atempo=<1/N>
#   （N 为音高倍数，atempo 用来把速度还原；纯变频会连带加速）
#
# ── 试过但没选的 ───────────────────────────────────────────────────────────
#   zh-CN-XiaoyiNeural +25Hz  卡通腔少女，语尾上扬更明显，但没晓晓耐听
#   zh-CN-XiaoyiNeural +45Hz  更幼更尖，接近动漫幼女声，偏刺耳
#   macOS say -v Tingting/Meijia + ffmpeg 变频
#                             底子是成年女声，变频只得到花栗鼠，甜美度上不去

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SOUNDS_DIR="$HOOK_DIR/sounds"

PAYLOAD=$(cat)

# Suppress while a Codex goal is actively driving this session (see above).
SESSION_ID=$(printf '%s' "$PAYLOAD" | jq -r '.session_id // empty' 2>/dev/null)
if [ -n "$SESSION_ID" ] && [ -r "$HOME/.codex/goals_1.sqlite" ]; then
	GOAL_STATUS=$(sqlite3 "file:$HOME/.codex/goals_1.sqlite?mode=ro" \
		"SELECT status FROM thread_goals WHERE thread_id = '$SESSION_ID' LIMIT 1;" 2>/dev/null)
	[ "$GOAL_STATUS" = "active" ] && exit 0
fi

# Random pick from all non-empty mp3s next to this script.
# Detached so playback never delays the harness.
# NOTE: no `mapfile` here — it needs bash 4+, but `#!/usr/bin/env bash`
# resolves to bash 3.2 (/bin/bash) under Codex's minimal PATH.
CLIPS=()
while IFS= read -r f; do
	[ -n "$f" ] && CLIPS=("${CLIPS[@]}" "$f")
done < <(find "$SOUNDS_DIR" -maxdepth 1 -name '*.mp3' -size +0c 2>/dev/null)
[ ${#CLIPS[@]} -eq 0 ] && exit 0
nohup afplay "${CLIPS[$((RANDOM % ${#CLIPS[@]}))]}" >/dev/null 2>&1 &
exit 0
