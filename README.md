<!-- omit in toc -->
# archive-commit-diff

Git リポジトリ上の指定コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプトです。

<!-- omit in toc -->
## 目次

- [1. コマンド一覧](#1-コマンド一覧)
- [2. 使い方](#2-使い方)
    - [2.1. 環境構築](#21-環境構築)
    - [2.2. 実行](#22-実行)
    - [2.3. エイリアスで実行する場合](#23-エイリアスで実行する場合)
- [3. 補足](#3-補足)
- [4. 参考文献](#4-参考文献)

## 1. コマンド一覧

```shell
$ acd.sh <from_commit> <to_commit> # <from_commit> と <to_commit> の差分を出力する
$ acd.sh <from_commit>             # <from_commit> と HEAD の差分を出力する
$ acd.sh -h                        # ヘルプを表示する
```

## 2. 使い方

### 2.1. 環境構築

```shell
# ダウンロードしたスクリプトファイルへ実行権限を付与
$ chmod +x /your/bin/dir/acd.sh

# PATH を通す
$ echo 'export PATH=/your/bin/dir:$PATH' >> ~/.bashrc
$ source ~/.bashrc
```

### 2.2. 実行

```shell
# Git リポジトリのルートへ移動
$ cd /your/git/repo

# スクリプトを実行
$ acd.sh main your-branch
アーカイブを出力しました。

 Summary
---------
from commit : main
to commit   : HEAD
Archived to : ./repo-20230112_230339.zip

 Archived files
----------------
repo/foo.txt
repo/bar.txt
repo/child/baz.txt
```

### 2.3. エイリアスで実行する場合

```shell
# .bashrc へエイリアスを書き込み
$ echo 'alias acd="acd.sh"' >> ~/.bashrc
$ source ~/.bashrc

# スクリプトを実行
$ acd main your-branch
```

## 3. 補足

- ファイル名にスペースを含む差分ファイルが存在していても出力が可能です。
- 以下の場合はメッセージを表示して正常終了します。
    - 指定したコミット間に差分が存在しなかった場合
- 以下の場合はエラーメッセージを表示してエラー終了します。
    - 引数の個数が [1. コマンド一覧](#1-コマンド一覧) に該当しない場合
    - カレントディレクトリが Git リポジトリのルートディレクトリ上でない場合
    - 差分出力に失敗した場合（指定したコミットが Git の履歴に存在しない場合など）
- `<to_commit>` を省略した場合は `<from_commit>` と `HEAD`（最新のコミット）の差分を出力します。

    ```shell
    $ acd.sh main
    アーカイブを出力しました。

     Summary
    ---------
    from commit : main
    to commit   : HEAD

     Archived files
    ----------------
    repo/foo.txt
    ...
    ```

- `-h` オプションでヘルプを表示します。

    ```shell
    $ acd.sh -h
    -----------------------------------------------------------------
                        archive-commit-diff
    -----------------------------------------------------------------
    指定した Git コミット間の差分ファイルを ZIP 形式で出力します。

     Usage
    -------
        $ acd.sh <from_commit> <to_commit>
        $ acd.sh <from_commit>

    ...
    ```

## 4. 参考文献

- [シェルスクリプトを高級言語のような書き味に近づける Tips 集](https://sousaku-memo.net/php-system/1817)
- [使いやすいシェルスクリプトを書く | Taichi Nakashima](https://deeeet.com/writing/2014/05/18/shell-template/)
- [【 zipinfo 】コマンド――ZIPファイル内の情報を表示する：Linux基本コマンドTips（241） - ＠IT](https://atmarkit.itmedia.co.jp/ait/articles/1809/14/news041.html)
- [Gitで差分ファイルを抽出+zipファイル化する方法 | 株式会社グランフェアズ](https://www.granfairs.com/blog/staff/git-archivediff)
- [fish shellでコミット差分アーカイブのコマンドファイルを作成する | TECH BOX](https://tech.arc-one.jp/git-archive-on-fish)
- [GIT で差分ファイルを抽出する時にパスにスペースがあるとエラーになる - Espresso & Onigiri](https://va2577.github.io/post/61/)
- [git rev-parseを使いこなす - Qiita](https://qiita.com/karupanerura/items/721962bb7da3e34187e1)
