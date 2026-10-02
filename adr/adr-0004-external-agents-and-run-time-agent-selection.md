---
title: "ADR-0004: 外部 Agent の読み込みと実行時の Agent 選択"
status: "Accepted"
date: "2026-10-02"
authors: "T.Watanabe (maintainer)"
tags: ["architecture", "decision", "extensibility", "security", "agent"]
supersedes: ""
superseded_by: ""
---

# ADR-0004: 外部 Agent の読み込みと実行時の Agent 選択

## Status

Proposed | **Accepted** | Rejected | Superseded | Deprecated

## Context

- 利用者は、組み込み以外の Agent 製品（社内ツールなど）にも対応させたい。
- Agent class は Ruby コードであり、読み込むことは任意コードの実行を意味する。
- 一回の実行で対象とする Agent を絞りたい場合がある。これを、source 側の配布宣言（`deploy_to`）と混同したくない。
- インストールされていない Agent の設定ディレクトリを誤って作りたくない。

## Decision

本 ADR は ADR-0001 の PRI-002（新しい製品には Agent class の追加で対応する）を、本体の外にある Agent class にまで広げる。

### 外部 Agent は信頼されたローカルコードとして明示的に読み込む

- 利用者が指定したディレクトリの直下にある Ruby ファイルだけを読み込む。自動探索、再帰読み込み、リモート取得は行わない。
- 各ファイルは自己完結し、新しい Agent class を登録しなければならない。他のファイルの Agent class に依存する定義はサポートしない（読み込み順は契約ではない）。読み込み後は組み込みの Agent と区別せずに扱う。
- 読み込みの失敗、Agent の未登録、Agent 名の重複が起きた場合は、build や deploy を始める前に停止する。
- sandbox は提供しない。信頼できるコードだけを読み込むのは利用者の責任とし、そのことを文書に明記する。

### 実行時の選択と配布宣言を分ける

- 実行時の Agent 指定は、その回の実行対象を絞るだけとする。artifact の内容や scope は変えない。
- 未知の Agent 名の扱いは、層によって変える。実行時の指定は利用者のその場の意図なのでエラーにする。`deploy_to` はどの Agent が構成されているか（外部 Agent を含む）に左右される source 側の宣言なので、警告を出して無視する（ADR-0002）。

### 未インストールの Agent には既定で配置しない

- Agent の設定ルートが存在しなければ、その Agent への配置を警告付きでスキップする。明示的に指定したときだけ、ディレクトリを作成して配置する。

## Consequences

### Positive

- **POS-001**: 本体を変更せずに、任意の Agent 製品に対応できる。
- **POS-002**: 読み込まれるコードが利用者から常に見える。
- **POS-003**: 構成の誤りを実行前に検出でき、build や deploy の途中結果を残さない。
- **POS-004**: 一回の実行で対象を絞っても、source の配布宣言の意味は変わらない。
- **POS-005**: インストールされていない製品のディレクトリを誤って作成しない。

### Negative

- **NEG-001**: 外部 Agent の読み込みは任意コードの実行であり、安全性は利用者の判断に依存する。

## Alternatives Considered

### 外部 Agent の自動探索・再帰読み込み・リモート取得

- **ALT-001**: **Description**: 規約上の場所を自動で探索する、サブディレクトリを再帰的に読み込む、マーケットプレイスやリモートから取得する。
- **ALT-002**: **Rejection Reason**: どのコードが読み込まれるのかが利用者から見えにくくなり、信頼境界が曖昧になる。

### 外部 Agent の sandbox 実行

- **ALT-003**: **Description**: 外部 Agent class を隔離環境で評価する。
- **ALT-004**: **Rejection Reason**: Ruby で実用的な sandbox を作るのは難しく、コストに見合わない。信頼モデルを文書化する方針とした。

### インストール判定に extension 用サブディレクトリを用いる

- **ALT-005**: **Description**: 設定ルート配下の `agents/` や `skills/` があるかどうかで判定する。
- **ALT-006**: **Rejection Reason**: インストール直後の製品はこれらのサブディレクトリをまだ持たないことがあり、誤判定する。

## References

- **REF-001**: ADR-0001、ADR-0002（`deploy_to`）、ADR-0003（artifact scope）
- **REF-002**: `README.md`「Commands」「External Agent registrations」
