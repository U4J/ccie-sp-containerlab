# CCIE-SP v5.1 Lab Roadmap

這份 roadmap 把官方 exam topics 拆成適合版本控制的小型 lab。百分比依官方
v5.1 practical exam blueprint；實際準備時仍應以 Cisco 最新文件為準。

| 階段 | Lab 主題 | Blueprint 能力 |
| --- | --- | --- |
| 01 | IS-IS dual stack、ECMP、收斂 | Core Routing |
| 02 | OSPFv2/OSPFv3、BFD、LFA | Core Routing、HA |
| 03 | MPLS forwarding、LDP | Core Routing |
| 04 | iBGP、RR、MP-BGP、policy | Core Routing |
| 05 | MPLS L3VPN、Inter-AS、CSC | Architectures and Services |
| 06 | VPWS、VPLS、EVPN | Architectures and Services |
| 07 | Multicast、PIM、Anycast RP、mLDP | Core Routing |
| 08 | SR-MPLS、SR-TE、TI-LFA、PCEP | Segment Routing、HA |
| 09 | SRv6、uSID、interworking | Segment Routing |
| 10 | QoS、CoPP、uRPF、RPKI、FlowSpec | QoS、Security |
| 11 | Telemetry、NETCONF/RESTCONF、Python | Assurance and Automation |
| 12 | 8-hour mixed troubleshooting scenario | 全生命週期整合 |

## Lab 撰寫原則

- 一個 lab 聚焦一組清楚的技術與故障情境。
- 所有節點都應有 deterministic startup config。
- 驗證優先檢查 control plane、RIB/FIB 與 data plane。
- 每個刻意植入的故障都應有可觀察症狀與修復後的自動測試。
- 使用 documentation prefixes 與 private ASN，避免連到真實網路時誤宣告。

## 已實作 Lab

- [`xrd-playground`](../labs/xrd-playground/README.md)：階段 03 的基礎 MPLS
  forwarding/LDP，拓撲為 `CE-A -- PE-1 -- P-1 -- P-2 -- PE-2 -- CE-B`。
  後續每個情境請建立各自的 `labs/<lab-name>/` 資料夾，保有自己的 topology、
  configs、scripts 與 README。

## 平台策略

- FRR：IGP、BGP、MPLS/LDP、基本 L3VPN 與協定故障排除。
- GoBGP：BGP policy、FlowSpec、RPKI 與自動化測試。
- Nokia SR Linux：標準模型、gNMI 與 telemetry 練習。
- Cisco XRd/CML：需要 IOS XR CLI 或 Cisco-specific feature 的題目。
