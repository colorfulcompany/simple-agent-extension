---
title: "ADR-0003: Compile 時に決定する artifact scope（shared / own）"
status: "Accepted"
date: "2026-10-02"
authors: "T.Watanabe (maintainer)"
tags: ["architecture", "decision", "scope", "skill", "deploy"]
supersedes: ""
superseded_by: ""
---

# ADR-0003: Compile 時に決定する artifact scope（shared / own）

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

一部の Agent 製品は共通の skill ディレクトリ（`~/.agents/skills`）を読む。同一内容の skill をそこに一度だけ置けば重複を避けられるが、次の場合は共有できない。

- Agent 固有の適応で metadata が変わる skill を共有ディレクトリに置くと、他の Agent が誤った metadata を読む。
- `deploy_to` で配布先を限定した extension を共有ディレクトリに置くと、全 Agent に届いてしまい制限が無効になる。
- 共有 skill ディレクトリを読まない Agent（Claude Code）がある。
- agent（subagent）には共有の配置先がない。

## Decision

本 ADR は ADR-0001 の PRI-002（製品の知識は Agent class に閉じる）と PRI-006（判断は compile で完結する）を、配置先の分類に適用する。

各 artifact を **`shared`** または **`own`** のいずれかに分類し、その判定を **compile 時に**行って compile 結果に記録する。

判定規則（上から順に適用）:

1. extension が `deploy_to` を持つ → `own`
2. Agent がその type の共有をサポートしない（agent type 全般、Claude Code の skill）→ `own`
3. Agent 適応で metadata が変化した、または `static.agents.<agent>` が存在する → `own`
4. それ以外 → `shared`

`static.common` は全 Agent に共通のため判定に影響しない。PRI-006 に従い、deploy は記録された scope をそのまま使う。

## Consequences

### Positive

- **POS-001**: 同一内容の skill を共有ディレクトリに一度だけ配置でき、Agent 間の重複を避けられる。
- **POS-002**: Agent 固有の内容が他の Agent へ漏れることを構造的に防ぐ。

### Negative

- **NEG-001**: metadata の小さな差でも `own` に切り替わるため、作者が意図せず配置先が変わることがある。
- **NEG-002**: shared artifact は、実行時に対象の Agent を絞っても、共有ディレクトリ経由で他の Agent に届く。この到達範囲を制御する仕組みは未決定。

## Alternatives Considered

### 常に Agent 固有ディレクトリへ配置

- **ALT-001**: **Description**: 共有ディレクトリを使わず、すべて `own` にする。
- **ALT-002**: **Rejection Reason**: 共有ディレクトリを読む Agent 間で同一 skill が重複し、共通規約を活かせない。

### 作者が scope を明示指定

- **ALT-003**: **Description**: `metadata.yaml` に `shared: true` のような指定を設ける。
- **ALT-004**: **Rejection Reason**: 内容が Agent 固有である場合に誤指定で漏洩しうる。内容から機械的に導出する方が安全。

## References

- **REF-001**: ADR-0001、ADR-0002（`deploy_to`）
