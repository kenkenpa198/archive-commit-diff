<!-- omit in toc -->
# archive-commit-diff

指定した Git コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプトコマンド。

```shell
$ acd <from_commit> <to_commit> # <from_commit> と <to_commit> の差分を出力する
$ acd <from_commit>             # <from_commit> と HEAD の差分を出力する
$ acd -h                        # ヘルプを表示する
```

## 1. 特徴

- `git archive` コマンドのエラー発生が考えられる場合、アーカイブファイルを出力しません。
    - 通常、`git archive` コマンドはエラー終了時でも空のアーカイブファイルを生成してしまいます（Git 2.39.0 で確認）。
    - 当スクリプトでは `git archive` のエラー発生が考えられる場合、処理を中止して不要なアーカイブファイルを出力しません。
    - Git リポジトリ上の実行ではなかった場合や、指定したコミットが履歴に存在しなかった場合、差分のあるファイルが存在しなかった場合が対象となります。
- パスにスペースを含む差分ファイルが存在していてもアーカイブ化が可能です。
- アーカイブ完了後、アーカイブしたファイルを一覧表示します。

## 2. 環境構築

1. [最新のリリース](https://github.com/kenkenpa198/archive-commit-diff/releases/latest) > `Assets` > `Source code (zip)` から最新版のソースコードをダウンロードする。
2. ZIP ファイルを解凍後、ファイル `acd.sh` を好みのディレクトリへ配置する。
3. 以下を順番に実行する。

```shell
    # スクリプトを配置したディレクトリへ移動
$ cd your/bin/dir

    # 好みのコマンド名称へリネーム
    $ mv acd.sh acd
    $ ls -la
    -rw-r--r--  1 username username 8602 Jan 15 12:56 acd

# ファイルへ実行権限を付与
$ chmod +x acd

# 実行権限が付与されたことを確認
$ ls -la
    -rwxr-xr-x  1 username username 8602 Jan 15 13:00 acd

# コマンドが実行できるか確認
$ acd -h
------------------------------------------------------------------
                    archive-commit-diff v0.2.0
------------------------------------------------------------------
指定した Git コミット間の差分ファイルを ZIP 形式で出力します。
...

# （オプション）PATH が通っていなかったら PATH を通す
$ echo 'export PATH=/your/bin/dir:$PATH' >> ~/.bashrc
$ source ~/.bashrc
```

## 3. 実行

```shell
# Git リポジトリのルートへ移動
$ cd /your/git/repo

# コミット識別子を指定してコマンドを実行する
$ acd main your-branch
[INFO] アーカイブを出力しました。

 Summary
---------
from commit : main
to commit   : your-branch
archived to : ./repo-20230112_230339.zip

 Archived Files
----------------
repo/aaa.txt
repo/bbb.txt
repo/child/ccc.txt

# カレントディレクトリへアーカイブファイルが出力される
$ ls
aaa.txt  child
bbb.txt  repo-20230112-230339.zip # 出力されたアーカイブファイル
```

## 4. 補足

- コミット識別子を `<from_commit>` `<to_commit>` へ指定して実行してください。

    ```shell
    $ acd <from_commit> <to_commit>
    $ acd 322d4b4 a11729d
    ```

- コミット識別子にはコミット ID の他、ブランチ名、HEAD 、タグ が使用できます。

    ```shell
    $ acd main your-branch
    $ acd HEAD~~ HEAD
    $ acd v1.0.0 v1.1.0
    ```

- `<to_commit>` は省略可能です。この場合は `<from_commit>` と `HEAD` の差分を出力します。

    ```shell
    $ acd main
    [INFO] アーカイブを出力しました。

     Summary
    ---------
    from commit : main
    to commit   : HEAD
    archived to : ./repo-20230112_230339.zip
    ...
    ```

- `-h` オプションでヘルプを表示します。

    ```shell
    $ acd -h
    ------------------------------------------------------------------
                        archive-commit-diff v0.2.0
    ------------------------------------------------------------------
    指定した Git コミット間の差分ファイルを ZIP 形式で出力します。

     Usage
    -------
        $ acd <from_commit> <to_commit>
    ...
    ```

## 5. 参考文献

- [シェルスクリプトを高級言語のような書き味に近づける Tips 集](https://sousaku-memo.net/php-system/1817)
- [使いやすいシェルスクリプトを書く | Taichi Nakashima](https://deeeet.com/writing/2014/05/18/shell-template/)
- [初心者向け、「上手い」シェルスクリプトの書き方メモ - Qiita](https://qiita.com/m-yamashita/items/889c116b92dc0bf4ea7d)
- [Gitで差分ファイルを抽出+zipファイル化する方法 | 株式会社グランフェアズ](https://www.granfairs.com/blog/staff/git-archivediff)
- [fish shellでコミット差分アーカイブのコマンドファイルを作成する | TECH BOX](https://tech.arc-one.jp/git-archive-on-fish)
- [GIT で差分ファイルを抽出する時にパスにスペースがあるとエラーになる - Espresso & Onigiri](https://va2577.github.io/post/61/)
- [ShellCheck: SC2207 – Prefer mapfile or read -a to split command output (or quote to avoid splitting).](https://www.shellcheck.net/wiki/SC2207)
- [git rev-parseを使いこなす - Qiita](https://qiita.com/karupanerura/items/721962bb7da3e34187e1)
