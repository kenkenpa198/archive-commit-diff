<!-- omit in toc -->
# archive-commit-diff

指定した Git コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプトコマンドです。

```shell
$ acd <from_commit> <to_commit> # <from_commit> と <to_commit> の差分を出力する
$ acd <from_commit>             # <from_commit> と HEAD の差分を出力する
$ acd -h                        # ヘルプを表示する
```

## 1. 環境構築

```shell
# スクリプトを配置するディレクトリへ移動
$ cd your/bin/dir

# スクリプトをダウンロード
$ curl https://raw.githubusercontent.com/kenkenpa198/archive-commit-diff/main/acd.sh > acd

# ファイルへ実行権限を付与
$ chmod +x acd

# 実行権限が付与されたことを確認
$ ls -la
...
-rwxr-xr-x  1 username username 6542 Jan 12 19:11 acd

# コマンドが実行できるか確認
$ acd -h
------------------------------------------------------------------
                    archive-commit-diff v0.1.0
------------------------------------------------------------------
指定した Git コミット間の差分ファイルを ZIP 形式で出力します。
...

# （オプション）PATH が通っていなかったら PATH を通す
$ echo 'export PATH=/your/bin/dir:$PATH' >> ~/.bashrc
$ source ~/.bashrc
```

## 2. 実行

```shell
# Git リポジトリのルートへ移動
$ cd /your/git/repo

# コマンドを実行する
$ acd main your-branch # main ブランチと your-branch ブランチの差分を出力
アーカイブを出力しました。

 Summary
---------
from commit : main
to commit   : your-branch
Archived to : ./repo-20230112_230339.zip

 Archived files
----------------
./aaa.txt
./bbb.txt
./child/ccc.txt

# カレントディレクトリへアーカイブファイルが出力される
$ ls
aaa.txt  child
bbb.txt  repo-20230112_230339.zip # 出力したアーカイブファイル
```

## 3. 補足

- コミットの識別子には コミット ID 、ブランチ名、HEAD 、タグ が使用できます。

    ```shell
    $ acd.sh 322d4b4 a11729d  # コミット ID
    $ acd.sh main your-branch # ブランチ
    $ acd.sh HEAD~~ HEAD      # HEAD
    $ acd.sh v1.0.0 v1.1.0    # タグ
    ```

- `<to_commit>` は省略可能です。この場合は `<from_commit>` と `HEAD` の差分を出力します。

    ```shell
    $ acd main
    アーカイブを出力しました。

     Summary
    ---------
    from commit : main
    to commit   : HEAD
    Archived to : ./repo-20230112_230339.zip
    ...
    ```

- `-h` オプションでヘルプを表示します。

    ```shell
    $ acd -h
    ------------------------------------------------------------------
                        archive-commit-diff v0.1.0
    ------------------------------------------------------------------
    指定した Git コミット間の差分ファイルを ZIP 形式で出力します。

     Usage
    -------
        $ acd.sh <from_commit> <to_commit>
    ...
    ```

- パスにスペースを含む差分ファイルが存在していてもアーカイブ化が可能です。
- 以下の場合はメッセージを表示して正常終了します。
    - 指定したコミット間に差分が存在しなかった場合
- 以下の場合はエラーメッセージを表示してエラー終了します。
    - 引数の個数が 3 個以上の場合
    - カレントディレクトリが Git リポジトリのルートディレクトリ上でない場合
    - 差分出力に失敗した場合（指定したコミットが Git の履歴に存在しない場合など）

## 4. 既知の問題

- パスにスペースを含む差分ファイルが存在した場合、結果表示が分割して出力されます。

    ```shell
    $ ls
    'space in filename.txt'   space-not-in-filename.txt

    $ acd db89e6b 66ab2a3
    アーカイブを出力しました。
    ...
    Diff files
    ------------
    ./space\
    ./in\
    ./filename.txt              # 'space in filename.txt' がスペースで分割されて表示される
    ./space-not-in-filename.txt
    ```

    - 出力されたアーカイブファイルに影響はありません。

## 5. 参考文献

- [シェルスクリプトを高級言語のような書き味に近づける Tips 集](https://sousaku-memo.net/php-system/1817)
- [使いやすいシェルスクリプトを書く | Taichi Nakashima](https://deeeet.com/writing/2014/05/18/shell-template/)
- [Gitで差分ファイルを抽出+zipファイル化する方法 | 株式会社グランフェアズ](https://www.granfairs.com/blog/staff/git-archivediff)
- [fish shellでコミット差分アーカイブのコマンドファイルを作成する | TECH BOX](https://tech.arc-one.jp/git-archive-on-fish)
- [GIT で差分ファイルを抽出する時にパスにスペースがあるとエラーになる - Espresso & Onigiri](https://va2577.github.io/post/61/)
- [git rev-parseを使いこなす - Qiita](https://qiita.com/karupanerura/items/721962bb7da3e34187e1)
