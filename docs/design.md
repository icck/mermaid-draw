# mermaid-draw 設計ドキュメント

## 概要

Neovim内でMermaidダイアグラムをASCIIアートとしてレンダリングするプラグイン。

---

## 機能要件

- Mermaidコードブロック（` ```mermaid ``` `）を検出する
- カーソルがブロック内にある場合、右サイドパネルにASCIIアートをプレビュー表示する
- 編集内容をリアルタイムに反映する
- バックエンドを設定で差し替えできる

---

## 非機能要件

### ちらつきのない描画
- curlは非同期（`vim.system`の非同期モード）で実行する
- APIレスポンスが返ってきてからバッファを一括更新する（逐次書き換えしない）
- 前回と同じ内容の場合はバッファを更新しない（差分チェック）

### 過剰なAPIコール抑制
- `CursorHold` イベント + デバウンス（500ms目安）でトリガーする
- タイピング中はcurlを発火させない

### 差し替え可能なバックエンド
- 初期実装はcurlで `mermaid-ascii.art` APIを呼ぶ
- 将来的にローカルバイナリ（mermaid-asciiのフォーク等）に切り替えられる設計にする

```lua
require('mermaid-draw').setup({
  backend = "api",       -- curl で mermaid-ascii.art を叩く
  -- backend = "binary", -- ローカルバイナリを使う
})
```

---

## アーキテクチャ

```
[Neovim]
  イベント検知 (CursorHold + デバウンス)
    ↓
  mermaidブロック抽出
    ↓
  バックエンド呼び出し (curl / バイナリ) ※非同期
    ↓
  レスポンス受信
    ↓
  差分チェック → 変化あれば右サイドパネルを一括更新
```

---

## コマンド・キーマップ

| コマンド | デフォルトキーマップ | 説明 |
|---------|-----------------|------|
| `:MermaidToggle` | `<leader>mm` | サイドパネルの表示/非表示トグル |

キーマップはsetupで変更・無効化できる。

```lua
require('mermaid-draw').setup({
  keymaps = {
    toggle = "<leader>mm",  -- falseで無効化
  },
})
```

---

## 挙動の詳細

- カーソルがmermaidブロック外に出てもサイドパネルは閉じない（最後のプレビューを残す）
- 複数のmermaidブロックがある場合はカーソル位置のブロックを表示する
- 構文エラー時はパネル上部にエラーを表示し、前回の正常な結果はそのまま残す

---

## TODO

- [ ] ファイル構造作成（`lua/mermaid-draw/init.lua`, `plugin/mermaid-draw.lua`）
- [ ] Mermaid ブロック検出ロジック
- [ ] API バックエンド（curl で `mermaid-ascii.art` 呼び出し）
- [ ] 右サイドパネル（バッファ/ウィンドウ管理）
- [ ] `CursorHold` + デバウンス + 差分チェック
- [ ] `:MermaidToggle` コマンド + キーマップ
- [ ] `setup()` 設定インターフェース