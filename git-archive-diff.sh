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

# 出力結果（差分ファイル）を表示する関数
function print_result_files() {
    echo
    echo " Files"
    echo "-------"
    for file in "$@"; do
        echo "    $file"
    done
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

    # NOTE:
    # 「git diff コマンドの実行確認」～「git archive コマンドを実行」の処理は以下のワンライナーで書くともっと短く書ける。
    # ----------------------------------------------------------------------------------------------
    # git archive revision `git diff --name-only origin/master revision` -o archive.zip
    # ----------------------------------------------------------------------------------------------
    #
    # ただしこの記述で実行した場合、以下の問題が発生する。
    # - git diff の実行に失敗した場合でも git archive コマンドが実行されファイルが生成されてしまう。
    # - ファイル名にスペースが含まれたファイルが差分に存在した場合、変数展開時別ファイルとして扱われてコマンドの実行に失敗する。
    #
    # 以上の理由により、このスクリプトでは
    # 1. git diff の実行確認 → 2. git diff の標準出力を配列として保存 → 3. git archive で配列を展開して実行
    # という処理工程にしている（とはいえもっと簡潔に書きたい……）。

    # git diff コマンドの実行確認
    if ! git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR > /dev/null; then
        # コマンド実行でエラーが発生した場合はコマンドエラーを出力して異常終了
        print_cmd_error_exit "git diff"
    fi

    # git diff コマンドの標準出力を配列として保存
    local diff_files
    mapfile -t diff_files < <(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR)

    # NOTE:
    # 以下だと 1. git diff の実行確認 → 2. git diff の標準出力を配列として保存 の処理をまとめて書けるが、
    # この記述方法だと前述のファイル名にスペースが含まれていた場合の問題が発生してしまう。
    # ----------------------------------------------------------------------------------------------
    # if ! diff_files=( $(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR) ); then
    #     print_cmd_error_exit "git diff"
    # fi
    # ----------------------------------------------------------------------------------------------
    #
    # mapfile コマンドを使用した以下の構文だとファイル名を正しく保持できる。
    # ----------------------------------------------------------------------------------------------
    # if ! mapfile -t diff_files < <(git diff --name-only "$from_commit" "$to_commit" --diff-filter=ACMR); then
    #     print_cmd_error_exit "git diff"
    # fi
    # ----------------------------------------------------------------------------------------------
    #
    # しかし後者の構文の場合、存在しないコミットが渡ってきて git diff がエラー終了しても if 文では真にならない。
    # if 文で行いたい git diff コマンドの異常終了ステータスが mapfile の正常終了ステータスで上書きされてしまうため。
    #
    # 以上の理由で 1. git diff の実行確認 → 2. git diff という2段階に分けた処理順序にしている。
    # こちらも改善したい。

    # ファイル名を定義
    local export_path
    export_path="$(basename "$PWD")-$(date '+%Y%m%d_%H%M%S').zip" # ディレクトリ名-yyyymmdd_hhmmss.zip

    # git archive コマンドを実行
    if ! git archive --format=zip --prefix=root/ "$to_commit" "${diff_files[@]}" -o "$export_path"; then
        # コマンド実行でエラーが発生した場合はコマンドエラーを出力して異常終了
        print_cmd_error_exit "git archive"
    fi

    # 結果を表示する
    print_result_summary "$from_commit" "$to_commit" "$export_path"
    print_result_files "${diff_files[@]}"
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
