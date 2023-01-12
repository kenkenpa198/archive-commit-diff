#!/bin/bash
set -euo pipefail

# 指定した Git コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプトコマンド

###################################
# 関数定義 : メッセージを表示
###################################
# ヘルプを表示して正常終了する関数
print_help_to_exit() {
    # 引数なし または第1引数に -h を付与して実行されたらヘルプを表示
    if [[ $# = 0 ]] || [[ $1 = "-h" ]]; then

        cat \
<< msg_help
------------------------------------------------------------------
                    archive-commit-diff v0.1.0
------------------------------------------------------------------
指定した Git コミット間の差分ファイルを ZIP 形式で出力します。

 Usage
-------
    $ acd.sh <from_commit> <to_commit>
    $ acd.sh <from_commit>
    $ acd.sh -h

 Example
---------
コミットの識別子には コミット ID, ブランチ名, HEAD, タグ が使用できます。
    $ acd.sh 322d4b4 a11729d
    $ acd.sh main your-branch
    $ acd.sh HEAD~~ HEAD
    $ acd.sh v1.0.0 v1.1.0

<to_commit> は省略可能です。この場合は <from_commit> と HEAD の差分を出力します。
    $ acd.sh main

-h オプションでヘルプを表示します。
    $ acd.sh -h
msg_help

        exit 0
    fi
}

# エラーメッセージを表示して異常終了する関数
function print_error_to_exit() {
    local message=$1

    echo "[ERROR] ${message}"
    echo "使い方を確認するにはオプション '-h' を付与して実行してください。"
    exit 1
}

# コマンド実行エラーを出力して異常終了する関数
function print_command_error_to_exit() {
    local command=$1

    echo
    echo "[ERROR] ${command} コマンドの実行中にエラーが発生しました。"
    echo "出力されているエラー内容を確認してください。"
    echo "使い方を確認するにはオプション '-h' を付与して実行してください。"
    exit 1
}

# 出力結果（概要）を表示する関数
function print_result_summary() {
    local from_commit to_commit archived_filename
    from_commit=$1
    to_commit=$2
    archived_filename=$3
    echo "アーカイブを出力しました。"
    echo
    echo " Summary"
    echo "---------"
    echo "from commit : ${from_commit}"
    echo "to commit   : ${to_commit}"
    echo "Archived to : ./${archived_filename}"
}

# 出力結果（アーカイブされたファイル）を表示する関数
# $@ : 表示するファイルパスの配列
function print_archived_files() {
    local diff_files
    diff_files=( "$@" )
    echo
    echo " Archived files"
    echo "----------------"

    for file in "${diff_files[@]}" ; do
        echo "./$file"
    done

    # NOTE:
    # スペースを含むファイルが存在する場合、区切り文字として扱われるため分割して出力されてしまう。
    # 対処するには複雑な構文となるようなのでいったん対応無し。
}


###################################
# 関数定義 : 処理系
###################################
# 渡された引数の個数を検証する関数
function validate_parameters_count() {
    if (( $# < 1 )) || (( $# > 2 )); then
        print_error_to_exit "引数は 1 個 もしくは 2 個 で指定してください。"
    fi
}

# カレントディレクトリが Git リポジトリのルートか検証する関数
function validate_inside_repo_root() {
    # .git がカレントディレクトリに存在するか否かで判定する
    if ! git rev-parse --resolve-git-dir ./.git &>/dev/null; then
        print_error_to_exit "このスクリプトは Git リポジトリのルートディレクトリ上で実行してください。"
    fi

    return
}

# git コマンドを実行する関数
function do_git_diff_and_git_archive() {
    local from_commit to_commit
    from_commit=$1
    to_commit="${2:-"HEAD"}" # $2 が未定義の場合は "HEAD" を代入

    # git diff コマンドの標準出力を配列化
    # パスに含まれるスペースを \ でエスケープしておく
    if ! diff_files=( $(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR | sed -e "s/ /\\\\ /g") ); then
        # エラーが発生した場合はコマンドエラーを出力して異常終了
        print_command_error_to_exit "git diff"
    fi

    # 差分が存在しなかった場合は正常終了
    # ここで処理を止めなかった場合 git archive コマンドが実行され空のファイルが生成されてしまう
    if [[ "${#diff_files[@]}" == 0 ]]; then
        echo "指定されたコミット間に差分が存在しませんでした。"
        exit 0
    fi

    # ファイル名を定義
    local repo_name datetime archive_path
    repo_name="$(basename "$PWD")"
    datetime="$(date '+%Y%m%d-%H%M%S')"
    archive_path="$repo_name-$datetime.zip"

    # git archive コマンドを実行
    if ! echo "${diff_files[@]}" | xargs git archive --format=zip --prefix="$repo_name"/ "$to_commit" -o "$archive_path"; then
        # エラーが発生した場合はコマンドエラーを出力して異常終了
        print_command_error_to_exit "git archive"
    fi

    # NOTE:
    # git diff ～ git archive の処理は https://va2577.github.io/post/61/ の「結果」に記載されているコマンドを参考に作成。
    # スペースをパスに含むファイルが差分に存在しても、1 つのファイルとして扱い正しく処理を行うことができる。
    #
    # さらにこのコマンドを以下の 2 段階の処理に分割し、エラーハンドリングを行っている。
    # 1. git diff の実行・配列化
    # 2. git archive の実行
    #
    # ワンライナーのままでは、Git の歴史に存在しないコミットを渡された場合に git diff の処理に失敗するものの
    # 続けて git archive が実行されてしまい、空の ZIP ファイルが生成されてしまうため。

    # 結果を表示する
    print_result_summary "$from_commit" "$to_commit" "$archive_path"
    print_archived_files "${diff_files[@]}"
}


###################################
# メイン処理
###################################
function main() {
    # ヘルプの表示判定処理
    print_help_to_exit "$@"

    # カレントディレクトリが Git リポジトリのルートか検証
    validate_inside_repo_root

    # 引数の個数を検証
    validate_parameters_count "$@"

    # git コマンドを実行
    do_git_diff_and_git_archive "$@"
}

# メイン処理を実行
main "$@"
