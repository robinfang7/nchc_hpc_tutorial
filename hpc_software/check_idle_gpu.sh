#!/bin/bash
# check_idle_gpu.sh — 列出全叢集各節點閒置 GPU（含 25a-ggpn[01-36] GB200）
#
# 用法：./check_idle_gpu.sh [關鍵字]
#   ./check_idle_gpu.sh          # 全部節點
#   ./check_idle_gpu.sh ggpn     # 只看 GB200 節點
#   ./check_idle_gpu.sh 25a-hgpn # 只看 H200 節點
#
# 資料來源：scontrol show nodes -o（一次向 controller 查回「所有」節點，
# 每節點一行；不經 sinfo 的分割區視角，gb200 節點保證涵蓋，
# 也不會因節點同屬多個分割區而漏列或重複）
#
# 判斷邏輯：閒置 = CfgTRES 的 gres/gpu 張數 − AllocTRES 已配置張數
#           DOWN/DRAIN/FAIL 等狀態的節點另以 ⚠️ 標記（有剩餘但不可排程）

scontrol show nodes -o | awk -v filt="${1:-}" '
{
    line = $0

    # ── 逐欄位剖析（-o 模式：一節點一行）──
    node = ""
    if (match(line, /NodeName=[^ ]+/)) node = substr(line, RSTART+9, RLENGTH-9)

    state = ""
    if (match(line, /State=[^ ]+/)) state = substr(line, RSTART+6, RLENGTH-6)

    gpu_model = "gpu"
    if (match(line, /Gres=gpu:[A-Za-z0-9_.-]+:[0-9]+/)) {
        tok = substr(line, RSTART, RLENGTH)
        split(tok, p, ":")
        gpu_model = p[2]
    }

    total = alloc = 0
    if (match(line, /CfgTRES=[^ ]*/)) {
        tok = substr(line, RSTART, RLENGTH)
        if (match(tok, /gres\/gpu(:[^=]+)?=[0-9]+/)) {
            v = substr(tok, RSTART, RLENGTH)
            sub(/^gres\/gpu(:[^=]+)?=/, "", v)
            total = v + 0
        }
    }
    if (match(line, /AllocTRES=[^ ]*/)) {
        tok = substr(line, RSTART, RLENGTH)
        if (match(tok, /gres\/gpu(:[^=]+)?=[0-9]+/)) {
            v = substr(tok, RSTART, RLENGTH)
            sub(/^gres\/gpu(:[^=]+)?=/, "", v)
            alloc = v + 0
        }
    }

    if (total <= 0) next                    # 沒有 GPU 的節點
    free = total - alloc
    if (free <= 0) next                     # GPU 全部被佔用
    if (filt != "" && node !~ filt) next    # 有指定關鍵字則過濾

    # DOWN/DRAIN/FAIL/MAINT：有剩餘張數但排不進去
    if (state ~ /DOWN|DRAIN|FAIL|MAINT|NOT_RESPONDING/)
        printf "節點: %-15s | %-6s | 總共: %d 張 | 已用: %d 張 | ⚠️ 剩餘: \033[1;33m%d\033[0m 張（%s，不可排程）\n", node, gpu_model, total, alloc, free, state
    else {
        printf "節點: %-15s | %-6s | 總共: %d 張 | 已用: %d 張 | 👉 剩餘閒置: \033[1;32m%d\033[0m 張\n", node, gpu_model, total, alloc, free
        sum_free[gpu_model] += free
        sum_node[gpu_model]++
    }
}
END {
    if (length(sum_free) == 0) {
        print "（目前沒有符合條件的閒置 GPU）"
        exit
    }
    printf "%s\n", "--------------------------------------------------"
    for (m in sum_free)
        printf "摘要：%-8s 共 %d 個節點有閒置，合計 \033[1;32m%d\033[0m 張\n", m, sum_node[m], sum_free[m]
}
'
