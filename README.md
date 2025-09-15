# minigames
ミニゲーム詰め合わせ<br>

## 仕様メモ
ウィンドウサイズ640×480

## chatGPTが出してきたフォルダ構成(シーン別に管理)
~~それぞれが作るゲームファイルの名前はshooting_ochiai.rb(ゲーム名_名前.rb)みたいな感じでいいのでは~~<br>
ウィンドウは共通・シーンで管理する方式と仮定<br>

```plaintext
minigames/
├─ main.rb                  # アプリのエントリーポイント
│
├─ lib/                     # 共通処理やユーティリティ
│   ├─ base_scene.rb        # 全シーン共通の抽象クラス
│   └─ helpers.rb           # 汎用関数 (衝突判定・カードシャッフルなど)
│
├─ assets/                  # 素材 (画像・音声・フォントなど)
│   ├─ images/
│   ├─ sounds/
│   └─ fonts/
│
└─ scenes/                  # 各シーン
    ├─ menu_scene.rb        # メニュー
    │
    ├─ tetris/              # テトリス
    │   ├─ tetris_scene.rb
    │   ├─ block.rb
    │   └─ board.rb
    │
    ├─ shooter/             # シューティング
    │   ├─ shooter_scene.rb
    │   ├─ player.rb
    │   ├─ bullet.rb
    │   └─ enemy.rb
    │
    ├─ concentration/       # 神経衰弱 (Concentration)
    │   ├─ concentration_scene.rb
    │   └─ card.rb
    │
    ├─ uno/                 # UNO
    │   ├─ uno_scene.rb
    │   ├─ card.rb
    │   ├─ deck.rb
    │   └─ player.rb
    │
    └─ pk/                  # PKゲーム
        ├─ pk_scene.rb
        ├─ ball.rb
        ├─ goalie.rb
        └─ player.rb