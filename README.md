# minigames
ミニゲーム詰め合わせ

# chatGPTが出してきたフォルダ構成(ゲーム名は例)
それぞれが作るゲームファイルの名前はshooting_ochiai.rb(ゲーム名_名前.rb)みたいな感じでいいのでは<br>

minigames/<br>
├─ main.rb               # 起動用ランチャー (メニュー画面)<br>
├─ Gemfile               # 使うgemをまとめるなら<br>
│<br>
├─ lib/                  # 共通で使うクラスやユーティリティ<br>
│   ├─ base_game.rb      # ゲームの基本クラス（update/draw定義）<br>
│   └─ helpers.rb        # 共通関数 (例: 衝突判定, 乱数色)<br>
│<br>
├─ assets/               # 画像・音楽・フォントをまとめる<br>
│   ├─ images/<br>
│   ├─ sounds/<br>
│   └─ fonts/<br>
│<br>
└─ games/                # 各ミニゲームをサブフォルダで管理<br>
    ├─ shooter/<br>
    │   └─ shooter.rb    # 今作ったシューティングゲーム<br>
    │<br>
    ├─ breakout/<br>
    │   └─ breakout.rb   # ブロック崩し<br>
    │<br>
    ├─ tetris/<br>
    │   └─ tetris.rb     # テトリス<br>
    │<br>
    └─ snake/<br>
        └─ snake.rb      # スネークゲーム<br>
