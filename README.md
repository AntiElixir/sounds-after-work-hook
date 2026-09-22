# sounds-after-work-hook

Agent 干完活自动播一段语音提醒你。 每次触发时从 `sounds/` 目录随机挑一个 mp3 播放。

## 一键配置

直接复制丢给你的 agent：

```
帮我配置这个 hook，https://github.com/AntiElixir/sounds-after-work-hook，要求适配我的系统和对应的 agent。
```

## 目录结构

```
sounds-after-work-hook/
├── work-finished.sh   # Stop hook 脚本（Claude Code / Codex 用）
├── sounds/            # 语音文件，丢进 mp3 自动加入轮换
├── README.md
├── LICENSE
└── .gitignore
```

## 加自己的语音

往 `sounds/` 里丢 mp3 即可，下次触发自动进入随机轮换，无需改脚本。空文件（0 字节）会被自动跳过。

用 edge-tts 生成示例：

```bash
uvx edge-tts --voice zh-CN-YunxiNeural --pitch=-15Hz --rate=+25% \
  --text "干完了，干完了。" --write-media ./sounds/干完了干完了-低沉霸总.mp3
```

## 行为说明

- 播放是 detached 的（`nohup afplay ... &`），不会阻塞 hook 返回。
- Codex 开了 goals 自动续跑时，每个 turn 结束都会触发 Stop。脚本会查 `~/.codex/goals_1.sqlite`：goal 还是 `active` 就静默，只有 goal 停下（complete / blocked / paused 等）才响。普通交互不受影响。
- 目录里没有可用 mp3 时直接静默退出。

## 依赖

- macOS（`afplay` 播放）
- `jq`（解析 hook payload）
- `sqlite3`（可选，仅 Codex goals 判定用，没有就退化成每次都响）

## License

MIT
