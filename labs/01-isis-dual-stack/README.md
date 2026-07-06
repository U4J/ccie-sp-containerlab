# 01 — IS-IS Dual Stack Underlay

## 目標

- 建立四台 router 的 IS-IS Level 2 adjacency。
- 從 `pe1` 經由 `p1`、`p2` 以 ECMP 到達 `pe2`。
- 同時驗證 IPv4 與 IPv6 loopback reachability。
- 練習 adjacency、LSDB、RIB 與 data plane 的逐層排錯。

## Address Plan

| Node | IPv4 loopback | IPv6 loopback |
| --- | --- | --- |
| pe1 | `10.255.0.1/32` | `2001:db8:0:1::1/128` |
| p1 | `10.255.0.2/32` | `2001:db8:0:2::1/128` |
| p2 | `10.255.0.3/32` | `2001:db8:0:3::1/128` |
| pe2 | `10.255.0.4/32` | `2001:db8:0:4::1/128` |

P2P links 使用 `10.0.0.0/31` 起的 IPv4 子網，以及 `2001:db8:100::/64`
起的 IPv6 子網。

## 驗證

```bash
make deploy
make verify
docker exec clab-ccie-sp-isis-pe1 vtysh -c "show isis neighbor"
docker exec clab-ccie-sp-isis-pe1 vtysh -c "show ip route isis"
docker exec clab-ccie-sp-isis-pe1 vtysh -c "show ipv6 route isis"
```

完成 baseline 後，可以嘗試：

1. 關閉 `pe1:eth1`，比較 IPv4/IPv6 收斂。
2. 調高經 `p1` 路徑的 IS-IS metric，確認 ECMP 消失。
3. 移除某一端的 `ipv6 router isis CORE`，從症狀定位設定不對稱。

