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

# 差分ファイルが存在するか検証する関数
function validate_diff_files_exists() {
    local diff_files
    diff_files=( "$@" )

    # 差分が存在しなかった場合は正常終了する
    if [[ "${#diff_files[@]}" = 0 ]]; then
        echo "指定されたコミット間に差分が存在しませんでした。"
        exit 0
    fi
}

# 差分のアーカイブ処理を実行する関数
function do_archive() {
    local from_commit to_commit
    from_commit=$1
    to_commit="${2:-"HEAD"}" # $2 が未定義の場合は "HEAD" を代入

    # git diff コマンドの標準出力を配列化
    # mapfile コマンドを使用して標準出力を明示的に分割し配列化する。
    #
    # https://www.shellcheck.net/wiki/SC2207
    # > # For bash 4.4+, must not be in posix mode, may use temporary files
    # > mapfile -t array < <(mycommand)
    #
    # スペースをパスに含む差分ファイルが存在した場合、別の要素として変数へ代入され
    # git archive コマンドで変数を展開する際にファイルパルが存在せずエラー終了してしまうため。
    local diff_files
    mapfile -t diff_files < <(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR)

    # git diff が実行できていたか検証
    # git diff コマンド単体でも送信してエラー処理を行う。
    # mapfile でコマンドの標準出力を配列に渡す方法はエラーを検知できないため。
    #
    # https://www.shellcheck.net/wiki/SC2207
    # > Another exception is the wish for error handling:  array=( $(mycommand) ) || die-with-error works the way
    # > it looks while a similar mapfile construct like mapfile -t array < <(mycommand) doesn't fail
    # > and you will have to write more code for error handling.
    if ! git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR &>/dev/null; then
        # エラーが発生した場合はコマンドエラーを出力して異常終了
        print_command_error_to_exit "git diff"
    fi

    # 差分が存在するか検証
    # git archive コマンドは引数が存在せずエラーとなっても空のファイルを生成してしまうため、
    # 差分ファイルが存在しない場合は事前に処理を止める。
    validate_diff_files_exists "${diff_files[@]}"

    # ファイル名を定義
    local repo_name datetime archive_path
    repo_name="$(basename "$PWD")"
    datetime="$(date '+%Y%m%d-%H%M%S')"
    archive_path="$repo_name-$datetime.zip"

    # git archive コマンドを実行
    if ! git archive --format=zip --prefix="$repo_name"/ "$to_commit" "${diff_files[@]}" -o "$archive_path"; then
        # エラーが発生した場合はコマンドエラーを出力して異常終了
        print_command_error_to_exit "git archive"
    fi

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

    # 渡された引数の個数を検証
    validate_parameters_count "$@"

    # アーカイブ処理を実行
    do_archive "$@"
}

# メイン処理を実行
main "$@"
