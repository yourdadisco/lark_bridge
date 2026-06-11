# lark-feishu-bridge — Feishu Base 异步消息桥

让两个 lark-cli Bot Agent 通过共享飞书多维表格异步通信。

## 核心概念

- 两个或多个 Bot Agent 各装一个 copy，改自己的名字和 profile
- 共用同一个 Base Token + Table ID
- 通过 Base 记录传递消息：`send` → inbox（读不消耗）→ `respond`（写新消息）
- **纯 lark-cli**，无服务端、无 webhook
- **通过 cron 轮询** inbox，**只通知不消耗**，你回复后才 ack

## 安装

```bash
cp -r ~/Desktop/lark-feishu-bridge ~/.openclaw/workspace/agents/
```

## 配置

编辑 `scripts/bridge.ps1` 顶部：

```powershell
$MY_NAME = "助手A"          # 改成自己的 Bot 名字
$PROFILE = "cli_aaa25e2f02615bd5"  # 自己的 lark-cli profile
```

Base Token 和 Table ID 两个 Bot 共用，无需修改。

## 启动轮询

```powershell
openclaw cron add --name "feishu-bridge-poll" ^
  --schedule "{\"kind\":\"every\",\"everyMs\":60000}" ^
  --payload "{\"kind\":\"agentTurn\",\"message\":\"执行 lark-feishu-bridge 的 inbox 拉取新消息:\\npowershell -NoProfile -File agents/lark-feishu-bridge/scripts/bridge.ps1 inbox\\n如果有新消息就告诉我\",\"lightContext\":true}" ^
  --sessionTarget "isolated" ^
  --delivery "{\"mode\":\"announce\"}"
```

> 如果 delivery 报错 channel 问题，去掉 `--delivery` 参数。

## 命令

### send — 发消息给另一个 Bot

```powershell
powershell scripts/bridge.ps1 send <目标Bot名> <消息内容> [优先级]
```

优先级：`normal`（默认）、`high`、`critical`

### inbox — 查看待处理消息（不消耗）

```powershell
powershell scripts/bridge.ps1 inbox
```

- 只读，不标记 done，不会 ack
- 返回所有 `status=pending`、`target=自己` 的消息
- 返回 JSON 或 `EMPTY`

### ack — 确认处理完某条消息

```powershell
powershell scripts/bridge.ps1 ack <record_id> <from_name>
```

- 标记该记录为 done
- 自动回复一条 `[ack] ok` 给对方

### respond — 回复消息

```powershell
powershell scripts/bridge.ps1 respond <目标Bot名> <回复内容> [优先级]
```

- 写一条新 `response` 记录给对方
- **不自动 ack**，需要单独 `ack` 或留对方自己消耗

## 协作流程

```
助手A                                                 Hermes
  │                                                     │
  │── send "需求" ─────────────────────────────> Base 新增 pending
  │                                                     │
  │                                              cron 触发 inbox
  │                                              → 看到消息，告诉我
  │                                              → 我决定回复
  │                                                     │
  │                                              respond "结果" → Base 新增
  │                                                     │
  │  cron 触发 inbox                                     │
  │  → 看到回复，告诉我                                   │
  │  → 我决定回或不回                                     │
  │  ack 原消息                                           │
  │                                                     │
```

## 字段模型

| 字段 | 说明 |
|---|---|
| content | 消息正文 |
| from_name | 发送者名字 |
| msg_type | request / response / ack |
| target | 目标Bot名 或 all |
| status | pending / done |
| priority | normal / high / critical |

## 注意事项

- 脚本自动用 `subst W: .` 处理中文路径问题
- `inbox` **只读不消耗**——这是故意的，让你自己决定什么时候 ack
- 两个 Bot 必须共用同一个 Base Token + Table ID
- 脚本文件必须是 UTF-8 with BOM（已处理）
