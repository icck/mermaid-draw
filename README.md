# mermaid-draw

Neovim内でMermaidダイアグラムをASCIIアートとしてリアルタイムプレビューするプラグイン。

```
┌────────┐     ┌────────┐
│ Client │     │ Server │
└───┬────┘     └───┬────┘
    │              │
    │   Request    │
    ├─────────────►│
    │              │
    │   Response   │
    │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┤
    │              │
```

## 機能

- Markdownファイル内の ` ```mermaid ``` ` ブロックを検出
- カーソルがブロック内にある時、右サイドパネルにASCIIアートをリアルタイム表示
- 非同期レンダリングでちらつきなし
- `:MermaidToggle` でパネルの表示/非表示をトグル

## 依存

- Neovim 0.10+
- [mermaid-ascii](https://github.com/AlexanderGrooff/mermaid-ascii)（Go製のCLIツール）

## インストール

### 1. mermaid-ascii をインストール

Go が必要です。

```sh
go install github.com/AlexanderGrooff/mermaid-ascii@latest
```

### 2. プラグインをインストール

**lazy.nvim**（`build` に書くと `mermaid-ascii` も自動インストールされます）

```lua
{
  "icck/mermaid-draw",
  build = "go install github.com/AlexanderGrooff/mermaid-ascii@latest",
  ft = "markdown",
  config = function()
    require('mermaid-draw').setup()
  end,
}
```

**その他のプラグインマネージャー**

`mermaid-ascii` を手動でインストールした上で、設定ファイルに追加してください。

```lua
require('mermaid-draw').setup()
```

## 設定

すべての設定はオプションです。

```lua
require('mermaid-draw').setup({
  -- バックエンド: "binary"（デフォルト）
  backend = "binary",

  -- mermaid-ascii バイナリのパス（デフォルトはPATHから検索）
  binary_path = "mermaid-ascii",

  -- mermaid-ascii に渡す追加オプション
  -- -x: ノード間の水平スペース（デフォルト5）
  -- -y: ノード間の垂直スペース（デフォルト5）
  -- -p: ボックスのパディング（デフォルト1）
  -- --ascii: Unicode文字の代わりにASCII文字を使用
  binary_opts = {},

  -- updatetime（ミリ秒）: CursorHoldが発火するまでの待機時間
  updatetime = 500,

  -- キーマップ（falseで無効化）
  keymaps = {
    toggle = "<leader>mm",
  },
})
```

## 使い方

1. Markdownファイルを開く
2. `<leader>mm`（または `:MermaidToggle`）で右サイドパネルを開く
3. ` ```mermaid ``` ` ブロック内にカーソルを移動
4. しばらく待つ（デフォルト500ms）とASCIIアートが表示される

カーソルがブロック外に出てもパネルは閉じず、最後のプレビューが残ります。
複数のmermaidブロックがある場合は、カーソル位置のブロックが表示されます。

## 対応ダイアグラム

`mermaid-ascii` がサポートするダイアグラムのみ対応しています。

| ダイアグラム | 対応状況 |
|------------|---------|
| フローチャート (`graph LR` / `graph TD`) | ✅ |
| シーケンス図 (`sequenceDiagram`) | ✅ |
| その他 | ❌ |

> **注意**: 複雑な経路のクロスや対角線の矢印は `mermaid-ascii` の制限により正しくレンダリングされないことがあります。

## ライセンス

MIT