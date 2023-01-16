#!/bin/bash
set -euo pipefail

# 指定した Git コミット間の差分ファイルを ZIP 形式で出力するシェルスクリプトコマンド

###################################
# 作成メモ
###################################
# - メイン関数 main() を定義して実行する。グローバルスコープの汚染を防ぐため。
# - 関数内での変数宣言はローカル変数（snake_case）を宣言し関数スコープ内で扱う。
# - スクリプト内で共通で使用する変数は書き込み禁止のグローバル定数（UPPER_CASE）として定義する。
# - 渡された引数はグローバル定数やローカル変数へ代入して使用する。引数を命名してコードの可読性を上げるため。


###################################
# グローバル定数を定義
###################################
# 渡された引数を命名
SCRIPT_NAME="$(basename "$0")" # 実行されたこのスクリプトのファイル名
FROM_COMMIT="${1:-""}"         # $1 が未定義（引数なし）の場合は空文字を代入
TO_COMMIT="${2:-"HEAD"}"       # $2 が未定義の場合は "HEAD" を代入

# リポジトリ名と出力ファイルパスを定義
REPOSITORY_NAME="$(basename "$PWD")"
ARCHIVE_PATH="./$REPOSITORY_NAME-$(date '+%Y%m%d-%H%M%S').zip"

# 書き込みを禁止して定数化
readonly SCRIPT_NAME FROM_COMMIT TO_COMMIT REPOSITORY_NAME ARCHIVE_PATH


###################################
# 関数定義 : メッセージを表示
###################################
# ヘルプを表示して正常終了する関数
print_help_to_exit() {
    # 引数なし または第 1 引数が -h, --help で実行されていたらヘルプを表示
    if [[ $# = 0 ]] || [[ $FROM_COMMIT = "-h" ]] || [[ $FROM_COMMIT = "--help" ]]; then

        cat \
<< msg_help
------------------------------------------------------------------
                    archive-commit-diff v0.2.0
------------------------------------------------------------------
指定した Git コミット間の差分ファイルを ZIP 形式で出力します。

 Usage
-------
    $ $SCRIPT_NAME <from_commit> <to_commit>
    $ $SCRIPT_NAME <from_commit>
    $ $SCRIPT_NAME -h

 Example
---------
コミット識別子を <from_commit> <to_commit> へ指定して実行します。
    $ $SCRIPT_NAME 322d4b4 a11729d

コミット識別子には ブランチ名 HEAD タグ も使用できます。
    $ $SCRIPT_NAME main your-branch
    $ $SCRIPT_NAME HEAD~~ HEAD
    $ $SCRIPT_NAME v1.0.0 v1.1.0

<to_commit> を省略した場合は <from_commit> と HEAD の差分を出力します。
    $ $SCRIPT_NAME main

-h オプションでヘルプを表示します。
    $ $SCRIPT_NAME -h
msg_help

        exit 0
    fi
}

# メッセージを表示する関数
function print_info() {
    local message=$1

    echo "[INFO] ${message}"
}

# エラーメッセージを表示して異常終了する関数
function print_error_to_exit() {
    local message=$1

    echo "[ERROR] ${message}"
    echo
    echo "使い方を確認するにはオプション '-h' を付与して実行してください。"
    echo "    $ $SCRIPT_NAME -h"
    exit 1
}

# コマンド実行エラーを出力して異常終了する関数
function print_command_error_to_exit() {
    local command=$1

    echo
    echo "[ERROR] ${command} コマンドの実行中にエラーが発生しました。"
    echo "出力されているエラーメッセージを確認してください。"
    echo
    echo "使い方を確認するにはオプション '-h' を付与して実行してください。"
    echo "    $ $SCRIPT_NAME -h"
    exit 1
}

# 出力結果（概要）を表示する関数
function print_result_summary() {
    print_info "アーカイブを出力しました。"
    echo
    echo " Summary"
    echo "---------"
    echo "from commit : $FROM_COMMIT"
    echo "to commit   : $TO_COMMIT"
    echo "archived to : $ARCHIVE_PATH"
}

# 出力結果（アーカイブされたファイル）を表示する関数
function print_archived_files() {
    local diff_files
    diff_files=( "$@" )

    echo
    echo " Archived Files"
    echo "----------------"

    for file in "${diff_files[@]}" ; do
        echo "$file"
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

# git diff コマンドを実行する関数
function do_git_diff() {
    git diff --name-only "$FROM_COMMIT" "$TO_COMMIT" --diff-filter=ACMR
}

# git diff コマンドの実行を検証する関数
function validate_do_git_diff() {
    # エラーが発生した場合はコマンドエラーを出力して異常終了
    if ! git diff --name-only "$FROM_COMMIT" "$TO_COMMIT" --diff-filter=ACMR &>/dev/null; then
        print_command_error_to_exit "git diff"
    fi
}

# 差分ファイルが存在するか検証する関数
function validate_diff_files_exists() {
    local diff_files
    diff_files=( "$@" )

    # 差分が存在しなかった場合は正常終了する
    if [[ "${#diff_files[@]}" = 0 ]]; then
        print_info "指定されたコミット間に差分が存在しませんでした。"
        exit 0
    fi
}

# git archive コマンドを実行する関数
function do_git_archive() {
    local diff_files
    diff_files=( "$@" )

    # エラーが発生した場合はコマンドエラーを出力して異常終了
    if ! git archive --format=zip --prefix="$REPOSITORY_NAME"/ "$TO_COMMIT" "${diff_files[@]}" -o "$ARCHIVE_PATH"; then
        print_command_error_to_exit "git archive"
    fi
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

    # git diff コマンドの標準出力を配列化
    # 配列の代入には bash の mapfile コマンドを使用する。
    #
    # https://www.shellcheck.net/wiki/SC2207
    # > # For bash 4.4+, must not be in posix mode, may use temporary files
    # > mapfile -t array < <(mycommand)
    #
    # diff_files=( $(do_git_diff) ) でも配列の保存は可能だが、
    # スペースをパスに含む差分ファイルが存在した場合、別の要素として変数へ代入される。
    # この状態の変数を git archive コマンド内で展開すると、要素に対応するファイルパスが存在せずエラー終了してしまう。
    local diff_files
    mapfile -t diff_files < <(do_git_diff)

    # git diff が実行できていたか検証
    # git diff コマンド単体をもう一度送信してエラー処理を行う。
    # mapfile でコマンドの標準出力を配列に渡す方法ではコマンド本体に対してエラー処理が行えないため。
    #
    # https://www.shellcheck.net/wiki/SC2207
    # > Another exception is the wish for error handling:  array=( $(mycommand) ) || die-with-error works the way
    # > it looks while a similar mapfile construct like mapfile -t array < <(mycommand) doesn't fail
    # > and you will have to write more code for error handling.
    validate_do_git_diff

    # 差分ファイルが存在するか検証
    # git archive コマンドは引数のファイルパスが存在せずエラーとなっても
    # 空のファイルを生成してしまうため、差分ファイルが存在しない場合は事前に処理を止める。
    validate_diff_files_exists "${diff_files[@]}"

    # git archive コマンドを実行
    do_git_archive "${diff_files[@]}"

    # 結果を表示する
    print_result_summary
    print_archived_files "${diff_files[@]}"
}

# メイン処理を実行
main "$@"
