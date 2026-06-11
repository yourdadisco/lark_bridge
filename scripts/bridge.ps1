# bridge.ps1 — lark-feishu-bridge v5
# 两个 Bot Agent 通过飞书 Base 异步通信

$BT      = "IWNsb1SH3achqxstUdBc8kbgnch"
$TI      = "tblUyyO5S0qtrdzZ"
$MY_NAME = "助手A"
$PROFILE = "cli_aaa25e2f02615bd5"

$CMD = $args[0]
if (!$CMD) { Write-Output "Usage: bridge.ps1 send <To> <Content> [priority] | inbox [OwnerId] | respond <To> <Content> [priority] | ack <RecordId>"; exit 0 }

cmd /c "subst W: /d" 2>&1 | Out-Null
cmd /c "subst W: ." 2>&1 | Out-Null

function writeBase($obj) {
  $p = @()
  $obj.Keys | ForEach-Object { $v = $obj[$_] -replace '"','\"'; $p += """$_"":""$v""" }
  $j = "{$($p -join ',')}"
  [IO.File]::WriteAllText("W:\_b.json", $j, [Text.UTF8Encoding]::new($false))
  cmd /c "W: && lark-cli --profile $PROFILE base +record-upsert --base-token $BT --table-id $TI --json @.\_b.json --as user" 2>&1 | Out-Null
  Remove-Item "W:\_b.json" -ErrorAction SilentlyContinue
}

if ($CMD -eq "send") {
  $To = $args[1]
  if ($args.Count -ge 3) {
    $Priority = $args[$args.Count-1]
    $Content = if ($args.Count -eq 3) { $args[2] } else { ($args[2..($args.Count-2)] -join ' ') }
  } else { $Content = ""; $Priority = "normal" }
  writeBase @{from_name=$MY_NAME; content=$Content; target=$To; priority=$Priority; msg_type="request"; status="pending"}
  Write-Output "[OK] $MY_NAME > $To ($Priority)"
  exit 0
}

if ($CMD -eq "inbox") {
  cmd /c "W: && lark-cli --profile $PROFILE base +record-list --base-token $BT --table-id $TI --format json --as user > W:\_raw.txt" 2>&1 | Out-Null
  if (!(Test-Path "W:\_raw.txt")) { Write-Output "EMPTY"; exit 0 }
  $txt = [IO.File]::ReadAllText("W:\_raw.txt", [Text.UTF8Encoding]::new($false))
  Remove-Item "W:\_raw.txt" -ErrorAction SilentlyContinue
  if (!$txt) { Write-Output "EMPTY"; exit 0 }

  $d = ($txt | ConvertFrom-Json).data
  if (!$d -or !$d.data -or !$d.fields -or $d.data.Count -eq 0) { Write-Output "EMPTY"; exit 0 }

  $fs = $d.fields; $rs = $d.data; $ris = $d.record_id_list
  $out = @()
  for ($i = 0; $i -lt $rs.Count; $i++) {
    $h = @{}
    for ($j = 0; $j -lt $fs.Count; $j++) { $h[$fs[$j]] = if ($null -ne $rs[$i][$j]) { $rs[$i][$j].ToString() } else { "" } }
    if ($h["status"] -ne "pending") { continue }
    if ($h["from_name"] -eq $MY_NAME) { continue }
    $tg = $h["target"]
    if ($tg -and $tg -ne "all" -and $tg -ne $MY_NAME) { continue }

    $out += [PSCustomObject]@{
      record_id=$ris[$i]
      from=$h["from_name"]
      content=$h["content"]
      priority=$h["priority"]
      msg_type=$h["msg_type"]
    }
  }

  if ($out.Count -eq 0) { Write-Output "EMPTY" } else { Write-Output ($out | ConvertTo-Json -Depth 3) }
  exit 0
}

if ($CMD -eq "ack") {
  $rid = $args[1]
  # 标记为 done
  [IO.File]::WriteAllText("W:\_d.json", '{"status":"done"}', [Text.UTF8Encoding]::new($false))
  cmd /c "W: && lark-cli --profile $PROFILE base +record-upsert --base-token $BT --table-id $TI --record-id $rid --json @.\_d.json --as user" 2>&1 | Out-Null
  Remove-Item "W:\_d.json" -ErrorAction SilentlyContinue
  # 发 ack 通知
  $from = $args[2]
  if ($from) { writeBase @{from_name=$MY_NAME; content="[ack] ok"; msg_type="ack"; target=$from; priority="normal"; status="pending"} }
  Write-Output "[OK] acked $rid"
  exit 0
}

if ($CMD -eq "respond") {
  $To = $args[1]
  if ($args.Count -ge 3) {
    $Priority = $args[$args.Count-1]
    $Content = if ($args.Count -eq 3) { $args[2] } else { ($args[2..($args.Count-2)] -join ' ') }
  } else { $Content = ""; $Priority = "normal" }
  writeBase @{from_name=$MY_NAME; content=$Content; target=$To; priority=$Priority; msg_type="response"; status="pending"}
  Write-Output "[OK] $MY_NAME response to $To"
  exit 0
}

Write-Output "Usage: bridge.ps1 send <To> <Content> [priority] | inbox [OwnerId] | respond <To> <Content> [priority] | ack <RecordId> [From]"
