# dg-matchbox-shaders — プロジェクト方針

Autodesk Flame **2025.2.7** 向け Matchbox（将来 Lightbox）を、DIGITAL GARDEN として開発・配布する。
OS 対象は **Rocky Linux** と **macOS**。

## 公開境界

| 内容 | 置き場 | GitHub (public) |
|------|--------|-----------------|
| 配布用 encrypted `.mx` + manifest | `dist/` | 含める |
| 社外用汎用インストーラ | `install/` | 含める |
| 公開 README / LICENSE / AGENTS | ルート | 含める |
| ツール雛形 | `tools/` | 含める（秘密なし） |
| 開発中ソース (glsl / xml / `.p`) | ローカル `shaders/` | **含めない** |
| 開発完了ソース | **社内サーバー**（作業控え: `private/sources-archive/`） | **含めない** |
| AI 向け作成マニュアル | ローカル `docs/manual/` | **含めない** |
| 社内フリート (inventory / known_hosts / デプロイ) | ローカル `private/fleet/` | **含めない** |
| `_old/`（移行元参照） | ローカル | **含めない** |

公開物は **MX のみ**。ソースを GitHub に載せない。

## ディレクトリ構成

```text
dg-matchbox-shaders/
  README.md LICENSE AGENTS.md
  dist/                 # 公開: manifest.json + shaders/*.mx
  install/install.sh    # 公開: Rocky / macOS 汎用インストーラ
  tools/                # 公開可: scaffold / validate / package（今後）
  docs/README.md        # 公開: 案内のみ
  docs/manual/          # 非公開: AI 向けマニュアル
  shaders/              # 非公開: 開発中 dg_* ソース
  private/fleet/        # 非公開: 社内 SSH デプロイ
  private/sources-archive/
  _old/                 # 非公開: 移行元
```

## ブランド・ライセンス

- 表示名: **DIGITAL GARDEN**
- 再配布: **禁止**（`LICENSE`）
- シェーダー接頭辞: **`dg_`**（`YG_*` は対象外・移行しない）
- インストール先: `/opt/Autodesk/presets/<version>/matchbox/shaders/DG/*.mx`
- Lightbox 将来: `.../action/lightbox/DG/` を想定（今は Matchbox のみ実装）

## 対応バージョン

- 開発・検証の正: Flame **2025.2.7**
- インストーラ既定の下限: **2025.1.0**（GLSL 430 / 2025.2.7 系機能セット）。必要なら `DG_MIN_FLAME_VERSION` で調整
- それ未満の presets はスキップ

## 開発フロー

1. `docs/manual/` と公式情報を根拠に作成・改良する
2. `shaders/<dg_Name>/` でソースを編集する
3. Linux / macOS 双方で `shader_builder` により **encrypted MX** を生成する
4. 両 OS の Flame で実機確認する
5. 検証済み MX だけを `dist/shaders/` に置き、`dist/manifest.json` を更新して GitHub に載せる
6. 完了ソースは社内サーバーへ保管する（控えは `private/sources-archive/`）
7. `_old` からの移行は **1 シェーダーずつ**。現行スクリプトは参考のみ・処理は再設計

## 配布

### 社外（GitHub・public）

```bash
./install/install.sh
./install/install.sh --dry-run
```

権限は公式ドキュメントに従う。不明時はログイン中ユーザーで書き込み、不足なら明示的に失敗する。

### 社内（ローカルのみ）

- 方式: **各マシンへ SSH**（共有ストレージ非依存）
- inventory / known_hosts / 認証は `private/fleet/`（Git 外）
- 旧 `_old/script` は参考のみ。パスワード直書き・root 前提・known_hosts 削除は再現しない
- 推奨: `audit` → `plan` → パイロット → 全体 `install`（ロールバック可能）

## エージェント向け制約

- ソース・マニュアル・フリート設定を公開コミットに混ぜない
- `_old` の認証情報を新しいスクリプトへ移さない
- 推測で API / XML 属性を増やさない。マニュアルと公式を根拠にする
- 既存シェーダーの一括移行をしない（都度ユーザー確認）
- `YG_*` は扱わない
