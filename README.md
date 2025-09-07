# rcrs-docker

## 概要

このプロジェクトはロボカップレスキューシミュレーションを用いた実験の再現性を担保するために，シミュレーション環境をDocker上で動作させるものです．ロボカップレスキューシミュレーションでは，[サーバ](https://github.com/roborescue/rcrs-server)と[エージェント](https://github.com/roborescue/adf-sample-agent-java)をそれぞれ設定，動作させる必要があります．このプロジェクトでは，一つの実験条件に対して一つのenvファイルを記述し，envファイルを切り替えることで，それぞれの実験を実現できるようにしています．

なお，このプロジェクトは開発者が実験に使用しているJavaエージェントをさまざまな災害シナリオのもとで動作させるために作成しています．そのため，現在開発環境が提供されているadf-pythonや今後展開される可能性のあるインフラシステムへの対応は現在考えていません．

## 必要要件

このプロジェクトではDockerを使用します．事前にDockerをインストールしておいてください．

## 使用方法

### 1. リポジトリのクローン

任意のディレクトリにこのリポジトリをクローンします．もし，エージェント開発をしているディレクトリがある場合には，そのディレクトリと同階層にこのリポジトリをクローンすることを推奨します．

```sh
git clone https://github.com/NONONOexe/rcrs-docker.git
```

### 2. Dockerイメージのビルド

Dockerイメージをビルドします．次の`docker compose up`コマンドの`--build`オプションで，ビルドしてもよいのですが，ロボカップレスキューシミュレーションでは，サーバとエージェントの起動において，時間差が大きいと，うまく通信できないことがあるため，事前にビルドしておきます．

```sh
docker compose build
```

### 3. サービスの起動・終了

`docker compose up`コマンドでサーバとエージェントを起動します．サーバはイメージの段階でGitからダウンロードしていますが，エージェントは適宜開発することを想定し，バインドマウントしたものを用います．どのディレクトリをエージェントのディレクトリとしてマウントするかは，`compose.yaml`に設定されているため，適宜変更してください．デフォルトでは，このリポジトリと同階層の`ait-rescue`をマウントするようにしています．

```sh
# コンテナの起動・シミュレーションの開始
docker compose --env-file [任意の実験条件に対応するenvファイル] up server agent-custom

# コンテナの削除（必要に応じて）
docker compose down
```

また，サンプルエージェント（adf-sample-agent-java）を動作させたい場合には，次のように実行できます．`agent-sample`はあらかじめサンプルエージェントを含めたイメージとして用意しています．

```
docker compose --env-file [任意の実験条件に対応するenvファイル] up server agent-sample
```

他にも，エージェントを用意したい場合には，同様にして，Dockerfileのステージやserviceを追加してください．

### 4. シミュレーション結果の可視化

シミュレーション結果は`results`ディレクトリに各実験ごとに保管されます．この結果はringo-viewerを用いて可視化できます．[ringo-viewer](https://github.com/ringo-ringo-ringo/ringo-viewer)はロボカップレスキューシミュレーションの結果をウェブブラウザ上に可視化するツールです．シミュレーション内で動作するそれぞれのエージェントの振る舞いや知覚情報を確認できます．

```sh
# ringo-viewerによる結果の可視化（Ctrl+Cで終了）
docker compose --env-file [任意の実験条件に対応するenvファイル] up ringo
```

## 実験条件の設定

実験条件として現在設定できるのは，次の項目です．それぞれをenvファイルにより設定します．実験条件ごとに`.env.[実験条件名]`として管理することを推奨します．

### 実験名（`EXPERIMENT_NAME`）

`EXPERIMENT_NAME`には，実験名を設定します．この名前はサーバのログディレクトリに用いられます．

### 災害シナリオ（`MAP_NAME`）

`MAP_NAME`には，災害シナリオの名称を設定します．rcrs-serverで用意されたシナリオ，あるいは自身で用意したシナリオの名称を指定します．rcrs-serverのシナリオは`maps`配下にあるシナリオで，以下のものを利用できます．

- `berlin`（ドイツ，ベルリン）
- `eindhoven`（オランダ，アイントホーフェン）
- `istanbul`（トルコ，イスタンブール）
- `joao`（ブラジル，ジョアンペソア）
- `kobe`（日本，神戸）
- `montrial`（カナダ，モントリオール）
- `ny`（アメリカ，ニューヨーク）
- `paris`（フランス，パリ）
- `sakae`（日本，名古屋市，栄）
- `sf`（アメリカ，サンフランシスコ）
- `test`（テスト用シナリオ）
- `vc`（仮想都市）

また，自身で用意したシナリオは，`rcrs-server/custom-maps`配下にシナリオ名のディレクトリを作成し，その中に`map`と`config`ディレクトリを作成して，それぞれにマップデータと設定ファイルを配置します．

### 起動の種類（`RUN_TYPE`）

`RUN_TYPE`には，事前計算（`precompute`）か，本シミュレーション（`comprun`）かを選択します．実際には，事前計算と本シミュレーションを連続で実行したい場合が多いため，このリポジトリで用意している`.env`ファイルでは，設定せず，バッチスクリプトを用意して，その中で設定しています（`comprun.bat`を参照）．

## ディレクトリ構成

このプロジェクトでは，以下のディレクトリ構成となっています．実験条件を管理するenvファイルは，`config`ディレクトリの直下で保管しています．また，各コンテナへマウントするディレクトリはそれぞれのコンテナ名と対応したディレクトリにまとめています．

```txt
rcrs-docker/
├── compose.yaml
├── Dockerfile
├── config/                # 設定ファイル用ディレクトリ
├── rcrs-server/           # サーバ用ディレクトリ
│  ├── launch-server.sh    # サーバ起動スクリプト
│  └── custom-maps/        # カスタムマップ用ディレクトリ
├── rcrs-agent/            # エージェント用ディレクトリ
│  └── launch-agent.sh     # エージェント起動スクリプト
├── ringo-viewer/          # ringo-viewer用ディレクトリ
│  └── launch-ringo.sh     # ringo-viewer起動スクリプト
├── rcrs-agent/            # エージェント用ディレクトリ
├── results/               # 結果（ログ）保存用ディレクトリ
└── README.md              # この資料
```

## ライセンス

このプロジェクトは[MITライセンス](LICENSE)に基づいています．なお，rcrs-serverは[修正BSDライセンス](https://github.com/roborescue/rcrs-server/blob/master/LICENSE)に基づいています．利用時はそれぞれのライセンスに基づく取り扱いをお願いします．

## 関連リンク

- [ロボカップレスキューシミュレーション公式サイト](https://rescuesim.robocup.org/)
- [ait-rescue（近日公開予定）](https://github.com/NONONOexe/ait-rescue)
- [ringo-viewer](https://github.com/ringo-ringo-ringo/ringo-viewer)
