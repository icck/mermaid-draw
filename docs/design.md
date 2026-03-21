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
- バックエンド呼び出しは非同期（`vim.system`の非同期モード）で実行する
- レスポンスが返ってきてからバッファを一括更新する（逐次書き換えしない）
- 前回と同じ内容の場合はバッファを更新しない（差分チェック）

### 過剰なAPI/プロセス呼び出し抑制
- `CursorHold` / `CursorHoldI` イベントでトリガーする
- `updatetime` のデフォルトを500msに設定する（ユーザーが上書き可）
- タイピング中は発火させない

### 非同期競合の処理
- `vim.system` のジョブハンドルを保持する
- 新しいトリガー発火時、前のジョブが実行中であれば `handle:kill()` でキャンセルし、新しいジョブを起動する

### 差し替え可能なバックエンド
- デフォルトは `binary`（ローカルの `mermaid-ascii` バイナリをstdin経由で呼ぶ）
- 将来的にAPIバックエンドにも切り替えられる設計にする

```lua
require('mermaid-draw').setup({
  backend = "binary",  -- ローカルバイナリ（デフォルト）
  -- backend = "api",  -- curl で mermaid-ascii.art を叩く
})
```

---

## バックエンド仕様

### binary バックエンド

[mermaid-ascii](https://github.com/AlexanderGrooff/mermaid-ascii) をローカルにインストールして使う。

**インストール方法**（Go必須）:

```sh
go install github.com/AlexanderGrooff/mermaid-ascii@latest
```

lazy.nvimを使っている場合は `build` フックに記載することで自動インストールできる：

```lua
{
  "icck/mermaid-draw",
  build = "go install github.com/AlexanderGrooff/mermaid-ascii@latest",
}
```

それ以外のプラグインマネージャーでは手動でインストールする。

`mermaid-ascii` がPATHに存在しない場合はエラーを通知する。`setup()` の `binary_path` で明示的にパスを指定することもできる。

```lua
require('mermaid-draw').setup({
  binary_path = "/usr/local/bin/mermaid-ascii",  -- デフォルトは "mermaid-ascii"（PATH検索）
})
```

**呼び出し方**: stdinにMermaidコードを渡す。

```sh
echo "<mermaid code>" | mermaid-ascii
# または
mermaid-ascii -f -
```

**オプション**（setupで設定可能）:
- `-x` : ノード間の水平スペース（デフォルト5）
- `-y` : ノード間の垂直スペース（デフォルト5）
- `-p` : ボックスのパディング（デフォルト1）
- `--ascii` : Unicodeボックス文字の代わりに純粋なASCII文字を使用

**出力**: ASCIIアートを標準出力に返す。

**エラー**: 非ゼロ終了コードの場合は構文エラーとして扱う。

### api バックエンド

`mermaid-ascii.art` のホストAPIをcurlで呼ぶ。エンドポイントの詳細は実装時に確認する。

---

## アーキテクチャ

```
[Neovim]
  イベント検知 (CursorHold / CursorHoldI)
    ↓
  mermaidブロック抽出
    ↓
  前のジョブをkill（実行中の場合）
    ↓
  バックエンド呼び出し (binary / api) ※非同期
    ↓
  レスポンス受信
    ↓
  差分チェック → 変化あれば右サイドパネルを一括更新
```

---

## サイドパネル仕様

- `nvim_open_win` のsplit方式（`split = "right"`）で開く
- 幅: `math.floor(vim.o.columns / 3)`（最小40列）
- バッファは `nofile` / `nomodifiable` / `nowrap` に設定する
- `:MermaidToggle` で表示/非表示をトグルする
- パネルが未表示の状態でトリガーが発火しても自動では開かない（トグルで明示的に開く）

---

## 対象ファイルタイプ

`filetype=markdown` のバッファで動作する（`.md`, `.mdx`, `.markdown` などを含む）。

`BufEnter` autocmdで `vim.bo.filetype == "markdown"` を判定してイベントを登録する。

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
- パネルが一度も開かれていない場合（初期状態）は空のまま何もしない

---

## TODO

- [ ] ファイル構造作成（`lua/mermaid-draw/init.lua`, `plugin/mermaid-draw.lua`）
- [ ] Mermaid ブロック検出ロジック
- [ ] binary バックエンド（`mermaid-ascii` のstdin呼び出し）
- [ ] api バックエンド（curl で `mermaid-ascii.art` 呼び出し）
- [ ] 右サイドパネル（バッファ/ウィンドウ管理）
- [ ] `CursorHold` / `CursorHoldI` + 差分チェック + 非同期競合処理
- [ ] `:MermaidToggle` コマンド + キーマップ
- [ ] `setup()` 設定インターフェース