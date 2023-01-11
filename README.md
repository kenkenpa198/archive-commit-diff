<!-- omit in toc -->
# git-archive-diff

Git リポジトリ上の指定コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプト。

```shell
 Usage
-------
    $ ./git-archive-diff.sh <from_commit> <to_commit>
    $ ./git-archive-diff.sh <from_commit>
```

## 1. 使い方

```shell
# ダウンロードしたスクリプトファイルへ実行権限を付与
$ chmod +x /your/bin/dir/git-archive-diff.sh

# PATH を通す
$ echo 'export PATH=/your/bin/dir:$PATH' >> ~/.bashrc
$ source ~/.bashrc

# Git リポジトリへ移動
$ cd /your/git/dir

# スクリプトを実行
$ git-archive-diff.sh main feature/your-branch
アーカイブを出力しました。

 Summary
---------
    from commit : master
    to commit   : feature/your-branch
    exported to : ./git-archive-diff-20230111_224000.zip

 Files
-------
    foo/bar/aaa.txt
    foo/bar/bbb.txt
    foo/bar/ccc.txt
```

エイリアスで実行する場合

```shell
# .bashrc へエイリアスを書き込み
$ echo 'alias gad="git-archive-diff.sh"' >> ~/.bashrc
$ source ~/.bashrc

# スクリプトを実行
$ gad main feature/your-branch
```

## 2. 補足

- ファイル名にスペースを含むファイルが存在していても出力が可能です。
- 以下の場合はエラーメッセージを表示して終了します。
    - カレントディレクトリが Git リポジトリでない場合
    - 指定したコミットが存在しない等で差分出力に失敗した場合
- `<to_commit>` を省略した場合は `<from_commit>` と最新のコミット（ `HEAD` ）の差分を出力します。
- `-h` オプションでヘルプを表示します。

    ```shell
    $ ./git-archive-diff.sh -h
    ```

## 3. 参考文献

- [シェルスクリプトを高級言語のような書き味に近づける Tips 集](https://sousaku-memo.net/php-system/1817)
- [使いやすいシェルスクリプトを書く | Taichi Nakashima](https://deeeet.com/writing/2014/05/18/shell-template/)
- [Gitで差分ファイルを抽出+zipファイル化する方法 | 株式会社グランフェアズ](https://www.granfairs.com/blog/staff/git-archivediff)
- [Gitレポジトリの中にいるか確認する方法 | 晴耕雨読](https://tex2e.github.io/blog/git/check-if-inside-git-repo)
- [コマンドの標準エラー出力を変数に代入 - ハックノート](https://hacknote.jp/archives/20651/)
- [fish shellでコミット差分アーカイブのコマンドファイルを作成する | TECH BOX](https://tech.arc-one.jp/git-archive-on-fish)
