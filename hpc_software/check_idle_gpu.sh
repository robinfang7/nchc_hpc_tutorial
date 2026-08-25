for node in $(sinfo -h -o "%N" | xargs scontrol show hostnames); do
    tres_info=$(scontrol show node $node 2>/dev/null | grep -E "CfgTRES|AllocTRES")
    [ -z "$tres_info" ] && continue

    total=$(echo "$tres_info" | grep "CfgTRES" | sed -E 's/.*gres\/gpu=([0-9]+).*/\1/')
    [[ -z "$total" || ! "$total" =~ ^[0-9]+$ ]] && total=0

    alloc=0
    if echo "$tres_info" | grep -q "AllocTRES"; then
        alloc=$(echo "$tres_info" | grep "AllocTRES" | sed -E 's/.*gres\/gpu=([0-9]+).*/\1/')
        [[ -z "$alloc" || ! "$alloc" =~ ^[0-9]+$ ]] && alloc=0
    fi

    free=$((total - alloc))

    # 🌟 關鍵修正：只有當「剩餘閒置張數大於 0」時才印出來
    if [ "$total" -gt 0 ] && [ "$free" -gt 0 ]; then
        printf "節點: %-15s | 總共: %d 張 | 已用: %d 張 | 👉 剩餘閒置: \033[1;32m%d\033[0m 張\n" "$node" "$total" "$alloc" "$free"
    fi
done
