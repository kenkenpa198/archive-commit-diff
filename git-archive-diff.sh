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
-----------------------------------------------------------------
                     git-archive-diff v2.0.0
-----------------------------------------------------------------
Git コミット間の差分ファイルを ZIP 形式で出力します。

 Usage
-------
    $ bash ./git-archive-diff.sh <from_commit> <to_commit>
    $ bash ./git-archive-diff.sh <from_commit>

 Example
---------
コミットの識別子には コミット ID, ブランチ名, HEAD, タグ が使用できます。
    $ bash ./git-archive-diff.sh 322d4b4 a11729d
    $ bash ./git-archive-diff.sh main feature/your-branch
    $ bash ./git-archive-diff.sh HEAD~~ HEAD
    $ bash ./git-archive-diff.sh v1.0.0 v1.1.0

<to_commit> を省略した場合は <from_commit> と最新のコミット (HEAD) の差分を出力します。
    $ bash ./git-archive-diff.sh main

-h オプションでヘルプを表示します。
    $ bash ./git-archive-diff.sh -h
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
function print_result_summary() {
    echo "アーカイブを出力しました。"
    echo
    echo " Summary"
    echo "---------"
    echo "    from commit : ${1}"
    echo "    to commit   : ${2}"
    echo "    exported to : ./${3}"
}

# 出力結果（アーカイブされたファイル）を表示する関数
# $1 : アーカイブのファイル名
# $2 : 表示から除外するルートディレクトリの名称
function print_result_files() {
    echo
    echo " Archived Files"
    echo "----------------"

    # アーカイブファイルを読み込んでファイルパスを表示する
    # ルートディレクトリは表示から除外する
    zipinfo -1 "$1" -x "$2/"
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

# カレントディレクトリが Git リポジトリ内か検証する関数
function validate_inside_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        print_error_exit "このスクリプトは Git リポジトリ上で実行してください。"
    fi
return
}

# git archive コマンドを実行する関数
# $1 : 変更前のコミット識別子
# $2 : 変更後のコミット識別子（省略した場合は "HEAD" を代入）
function do_git_archive() {
    # コミット識別子をローカル変数へ代入
    local from_commit to_commit
    from_commit=$1           # 変更前のコミット
    to_commit="${2:-"HEAD"}" # 変更後のコミット。$2 が未定義の場合は "HEAD" を代入

    # git diff コマンドの標準出力を配列として保存
    if ! diff_files=( $(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR | sed -e "s/ /\\\\ /g") ); then
        print_cmd_error_exit "git diff"
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

    # 結果を表示する
    print_result_summary "$from_commit" "$to_commit" "$archive_path"
    print_result_files "$archive_path" "$repo_name"
}


###################################
# メイン処理
###################################
function main() {
    # ヘルプの表示判定処理
    print_help_exit "$@"

    # カレントディレクトリが Git リポジトリ内か検証
    validate_inside_repo

    # 引数の個数を検証
    validate_parameters_count "$@"

    # git archive コマンドを実行
    do_git_archive "$@"
}

# メイン処理を実行
main "$@"
