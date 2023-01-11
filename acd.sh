#!/bin/bash
set -euo pipefail

# Git リポジトリ上の指定コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプト

###################################
# 関数定義 : メッセージを表示
###################################
# ヘルプを表示して正常終了する関数
print_help_exit() {
    # 引数が存在しない または 第 1 引数がオプション文字列である場合のみ実行
    if [[ $# = 0 ]] || [[ $1 == "-h" ]]; then

        # ヒアドキュメントを出力
        cat \
<< msg_help
-------------------------------------------------------------------
                        archive-commit-diff
-------------------------------------------------------------------
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

        # 正常ステータスで終了
        exit 0
    fi
}

# エラーメッセージを表示して異常終了する関数
function print_error_exit() {
    local message=$1
    echo "[ERROR] ${message}"
    echo "使い方を確認するにはオプション '-h' を付与して実行してください。"
    exit 1
}

# コマンド実行エラーを出力して異常終了する関数
# $1 : エラーが発生したコマンド
function print_cmd_error_exit() {
    local command=$1
    echo ""
    echo "[ERROR] ${command} コマンドの実行中にエラーが発生しました。"
    echo "出力されているエラー内容を確認してください。"
    echo "使い方を確認するにはオプション '-h' を付与して実行してください。"
    exit 1
}

# 出力結果（概要）を表示する関数
# $1 : 変更前のコミット
# $2 : 変更後のコミット
# $3 : アーカイブのファイル名
function print_result_summary() {
    echo "アーカイブを出力しました。"
    echo
    echo " Summary"
    echo "---------"
    echo "from commit : ${1}"
    echo "to commit   : ${2}"
    echo "Archived to : ./${3}"
}

# 出力結果（アーカイブされたファイル）を表示する関数
# $1 : アーカイブのファイル名
function print_result_files() {
    echo
    echo " Archived files"
    echo "----------------"

    # アーカイブファイルを読み込んでファイルパスを表示する
    # ディレクトリは表示から除外する
    zipinfo -1 "$1" -x "*/"
}


###################################
# 関数定義 : 処理系
###################################
# 渡された引数の個数を検証する関数
function validate_parameters_count() {
    if (( $# < 1 )) || (( $# > 2 )); then
        print_error_exit "引数は 1 個 もしくは 2 個 で指定してください。"
    fi
}

# カレントディレクトリが Git リポジトリのルートか検証する関数
function validate_inside_repo_root() {
    # .git がカレントディレクトリに存在するか否かで判定する
    if ! git rev-parse --resolve-git-dir ./.git &>/dev/null; then
        print_error_exit "このスクリプトは Git リポジトリのルートディレクトリ上で実行してください。"
    fi
return
}

# git archive コマンドを実行する関数
# $1 : 変更前のコミット識別子
# $2 : 変更後のコミット識別子（省略可能）
function do_git_archive() {
    # コミット識別子をローカル変数へ代入
    local from_commit to_commit
    from_commit=$1           # 変更前のコミット
    to_commit="${2:-"HEAD"}" # 変更後のコミット。$2 が未定義の場合は "HEAD" を代入

    # git diff コマンドの標準出力を配列化
    # スペースをファイル名に含む場合は \ でエスケープする
    if ! diff_files=( $(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR | sed -e "s/ /\\\\ /g") ); then
        print_cmd_error_exit "git diff"
    fi

    # 差分が存在しなかった場合は正常終了
    if [[ "${#diff_files[@]}" == 0 ]]; then
        echo "差分が存在しませんでした。"
        exit 0
    fi

    # ファイル名を定義
    local repo_name datetime archive_path
    repo_name="$(basename "$PWD")"
    datetime="$(date '+%Y%m%d_%H%M%S')"
    archive_path="$repo_name-$datetime.zip"

    # git archive コマンドを実行
    if ! echo "${diff_files[@]}" | xargs git archive --format=zip --prefix="$repo_name"/ "$to_commit" -o "$archive_path"; then
        # コマンド実行でエラーが発生した場合はコマンドエラーを出力して異常終了
        print_cmd_error_exit "git archive"
    fi

    # NOTE:
    # git diff ～ git archive の処理は https://va2577.github.io/post/61/ の「結果」に記載されているコマンドを参考に作成。
    # スペースをファイル名に含むファイルが差分に存在しても、1 つのファイルとして正しく処理を行うことができる。
    #
    # さらにこのコマンドを以下の 2 段階の処理に分割し、エラーハンドリングを行っている。
    # 1. git diff の実行・配列化
    # 2. git archive の実行
    #
    # ワンライナーのままでは、Git の歴史に存在しないコミットを渡された場合に git diff の処理に失敗するものの
    # 続けて git archive が実行されてしまい、空の ZIP ファイルが生成されてしまうため。

    # 結果を表示する
    print_result_summary "$from_commit" "$to_commit" "$archive_path"
    print_result_files "$archive_path"
}


###################################
# メイン処理
###################################
function main() {
    # ヘルプの表示判定処理
    print_help_exit "$@"

    # カレントディレクトリが Git リポジトリのルートか検証
    validate_inside_repo_root

    # 引数の個数を検証
    validate_parameters_count "$@"

    # git archive コマンドを実行
    do_git_archive "$@"
}

# メイン処理を実行
main "$@"
