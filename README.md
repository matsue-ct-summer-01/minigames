# minigames
ミニゲーム詰め合わせ<br>

## 仕様メモ
ウィンドウサイズ640×480

## chatGPTが出してきたフォルダ構成(ゲーム名は例)
それぞれが作るゲームファイルの名前はshooting_ochiai.rb(ゲーム名_名前.rb)みたいな感じでいいのでは<br>

minigames/
├─ main.rb               # 起動用ランチャー (メニュー画面)
├─ Gemfile               # 使うgemをまとめるなら
│
├─ lib/                  # 共通で使うクラスやユーティリティ
│   ├─ base_game.rb      # ゲームの基本クラス（update/draw定義）
│   └─ helpers.rb        # 共通関数 (例: 衝突判定, 乱数色)
│
├─ assets/               # 画像・音楽・フォントをまとめる
│   ├─ images/
│   ├─ sounds/
│   └─ fonts/
│
└─ games/                # 各ミニゲームをサブフォルダで管理
    ├─ shooter/
    │   └─ shooter.rb    # 今作ったシューティングゲーム
    │
    ├─ breakout/
    │   └─ breakout.rb   # ブロック崩し
    │
    ├─ tetris/
    │   └─ tetris.rb     # テトリス
    │
    └─ snake/
        └─ snake.rb      # スネークゲーム
