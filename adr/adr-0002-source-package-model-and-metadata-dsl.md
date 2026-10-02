---
title: "ADR-0002: Source package モデルと metadata DSL"
status: "Accepted"
date: "2026-10-02"
authors: "T.Watanabe (maintainer)"
tags: ["architecture", "decision", "dsl", "metadata", "package"]
supersedes: ""
superseded_by: ""
---

# ADR-0002: Source package モデルと metadata DSL

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

作者は Agent 製品ごとの差異を意識せずに一つの source を書きたい。一方で、権限表現のように Agent ごとに表現が異なる metadata や、特定 Agent にしか書けない metadata、特定 Agent にしか配りたくない extension が存在する。

- skill と subagent を一つの機能として組み合わせて配布したい。
- entrypoint（`SKILL.md` や agent の `*.md`）は単体でも有効な文書であり、その frontmatter も尊重したい。

## Decision

本 ADR は ADR-0001 の PRI-001（single source）、PRI-003（Agent 固有の記述の置き場所）、PRI-004（本文は変換しない）を具体化する。

### Package と extension

- **package** は `<source_root>/<package>/` にある作者単位のまとまり。
- **extension** は package 内の type 別要素で、`<package>/<type>/` 一つが一 extension。type は現在 `skill` と `agent`。

ADR-0001 の図で compile の入力となる extension は、次の構成を持つ。

```text
<package>/<type>/
├── <entrypoint>.md   frontmatter + 本文（単体でも有効な文書）
├── metadata.yaml     任意。compile の入力で、配布しない
└── その他            同梱ファイル。そのまま配布する
```

- entrypoint は type が決める。skill は `SKILL.md`、agent は直下のただ一つの `*.md`（0 または 2 以上はエラー）。

### Extension metadata DSL（`metadata.yaml`、任意）

| Key | 意味 |
|---|---|
| `name` | extension identity。配置名になる。 |
| `deploy_to` | 配布先 Agent 名の制約。省略時は構成済み全 Agent。 |
| `adaptive` | Agent が artifact 表現を決める source fragment。規則のない field はそのまま通る。 |
| `static.common` | 全 Agent に適応なしで書かれる fragment。 |
| `static.agents.<agent>` | 指定 Agent にのみ適応なしで書かれる fragment。 |

- `adaptive` は「動的」ではなく「表現の決定権が Agent 側にある」ことを宣言する。
- `deploy_to` は選択の制約であり section に属さず、artifact metadata にも現れない。互換性の宣言ではない。対象外の Agent には artifact を一切生成しない。

### 優先順位（後勝ち）

- **Identity**: package ディレクトリ名 < entrypoint frontmatter `name` < `metadata.yaml` top-level `name`
- **Artifact metadata**: entrypoint frontmatter < `static.common` < Agent 適応済み fragment（`adaptive` 由来）< `static.agents.<agent>`

## Consequences

### Positive

- **POS-001**: 作者は一つの source で複数 Agent をカバーでき、Agent 固有の差は `adaptive` と `static.agents` に局所化される。
- **POS-002**: entrypoint 単体でも有効な文書のまま、`metadata.yaml` で上書き・補完できる。
- **POS-003**: `deploy_to` により未検証の Agent への配布を作者が制限できる。

### Negative

- **NEG-001**: 優先順位が 4 段あり、最終 metadata の出所を追うには規則の理解が必要。
- **NEG-002**: `adaptive` の field 語彙（例: `permissions`）は Agent 側の翻訳規則に暗黙に依存し、DSL として明示的に固定されていない。
- **NEG-003**: `deploy_to` の未知の Agent 名は警告のみで無視されるため、typo が配布漏れとして見逃されうる。
- **NEG-004**: source 構造の不正（未対応 type、空 package など）を一括検出する仕組みはまだない。

## Alternatives Considered

### 未知の `deploy_to` 名を厳格にエラー

- **ALT-001**: **Description**: 構成済み Agent に存在しない名前を build エラーにする。
- **ALT-002**: **Rejection Reason**: 外部 Agent を読み込んだかどうかで source の妥当性が変わってしまう。source 検証が整備されるまでは警告に留める。

### Agent ごとのファイル名をユーザー設定可能にする

- **ALT-003**: **Description**: artifact のファイル名を metadata で指定可能にする。
- **ALT-004**: **Rejection Reason**: ファイル名は Agent 製品の規約であり、作者が決めるものではない。

## References

- **REF-001**: ADR-0001（翻訳規則）、ADR-0003（`deploy_to` と scope）
- **REF-002**: `README.md`「Extension metadata」
