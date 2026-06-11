# lark-feishu-bridge

```
桌面/lark-feishu-bridge/
├── SKILL.md          ← Skill 说明（Agent 读这个了解怎么用）
├── scripts/
│   └── bridge.ps1    ← 核心脚本
└── tmp/              ← 临时目录
```

## 快速开始

1. **把这个文件夹拷贝到 OpenClaw 的 agents/ 目录**

2. **改配置** — 编辑 `scripts/bridge.ps1` 顶部：

   - `$MY_NAME` = 你的 Bot 名字（`助手A` 或 `Hermes`）
   - `$PROFILE` = 你的 lark-cli profile 名

3. **测试发送**（从终端执行）：

   ```powershell
   cd lark-feishu-bridge
   powershell -NoProfile -File scripts/bridge.ps1 send Hermes "你好，这是测试" high
   ```

4. **收消息**：

   ```powershell
   powershell -NoProfile -File scripts/bridge.ps1 inbox
   ```

5. **回复**：

   ```powershell
   powershell -NoProfile -File scripts/bridge.ps1 respond 助手A "收到，已处理" high
   ```

---

## 已测试通过的配置

| Bot | profile | name |
|---|---|---|
| 助手A | cli_aaa25e2f02615bd5 | 助手A |
| Hermes | cli_aaa3a73aae789bc6 | Hermes |

Base Token: `IWNsb1SH3achqxstUdBc8kbgnch`
Table ID: `tblUyyO5S0qtrdzZ`

> 2026-06-11 端到端演示已验证通过。
