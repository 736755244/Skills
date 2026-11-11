#!/bin/bash
# ==============================================================================
# fetch_prototype.sh — 下载受密码保护的 HTML 原型页面
#
# 原理：
#   1. POST /s/{shareId}/unlock 提交密码，获取认证 Cookie
#   2. GET  /s/{shareId}/?v=2 带 Cookie，获取真实 HTML 页面
#
# 用法：
#   ./fetch_prototype.sh LOGIN_URL [OUTPUT_FILE]
#
# LOGIN_URL   共享链接，可包含 ?pwd=密码，例如 https://host/s/share-id/?pwd=密码
# OUTPUT_FILE 输出文件路径，默认 ./.middleproduct/prototype.html
#
# 密码：URL 含 pwd 参数时直接截取使用；否则交互式终端中隐藏询问，
#       非交互模式使用 --password-stdin 或 PROTOTYPE_PASSWORD_FILE。
# ==============================================================================

set -euo pipefail

LOGIN_URL=""
OUTPUT_FILE="./.middleproduct/prototype.html"
PASSWORD_STDIN=false
PASSWORD_FILE="${PROTOTYPE_PASSWORD_FILE:-}"
PASSWORD_FROM_URL=""
COOKIE_FILE=""
TEMP_OUTPUT=""
PASSWORD=""

usage() {
    sed -n '2,18p' "$0"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --password-stdin)
            PASSWORD_STDIN=true
            shift
            ;;
        --)
            shift
            if [ "$#" -gt 0 ] && [ -z "$LOGIN_URL" ]; then
                LOGIN_URL="$1"
                shift
            fi
            if [ "$#" -gt 0 ]; then
                OUTPUT_FILE="$1"
                shift
            fi
            ;;
        -* )
            echo "ERROR: 未知参数：$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [ -z "$LOGIN_URL" ]; then
                LOGIN_URL="$1"
            elif [ "$OUTPUT_FILE" = "./.middleproduct/prototype.html" ]; then
                OUTPUT_FILE="$1"
            else
                echo "ERROR: 参数过多" >&2
                usage >&2
                exit 2
            fi
            shift
            ;;
    esac
done

if [ -z "$LOGIN_URL" ]; then
    echo "ERROR: 必须提供 LOGIN_URL" >&2
    usage >&2
    exit 2
fi

if printf '%s' "$LOGIN_URL" | grep -Eq '(^|[?&])pwd='; then
    PASSWORD_FROM_URL=$(printf '%s' "$LOGIN_URL" | sed -nE 's#.*(^|[?&])pwd=([^&]*).*#\2#p')
    LOGIN_URL=$(printf '%s' "$LOGIN_URL" | sed -E 's|([?&])pwd=[^&]*&?|\1|; s|[?&]$||; s|\?&|\?|')
fi

BASE_URL=$(printf '%s' "$LOGIN_URL" | sed -E 's|^(https?://[^/]+).*|\1|')
SHARE_ID=$(printf '%s' "$LOGIN_URL" | sed -E 's|.*/s/([^/?]+).*|\1|')

if [ -z "$BASE_URL" ] || [ "$BASE_URL" = "$LOGIN_URL" ] || [ -z "$SHARE_ID" ] || [ "$SHARE_ID" = "$LOGIN_URL" ]; then
    echo "ERROR: 无法从 URL 解析主机或 share ID" >&2
    echo "用法：$0 https://host/s/share-id/ [OUTPUT_FILE]" >&2
    exit 2
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

cleanup() {
    rm -f "$COOKIE_FILE" "$TEMP_OUTPUT"
    PASSWORD=""
}
trap cleanup EXIT

if [ -n "$PASSWORD_FROM_URL" ]; then
    PASSWORD="$PASSWORD_FROM_URL"
elif [ "$PASSWORD_STDIN" = true ]; then
    if [ -n "$PASSWORD_FILE" ]; then
        echo "ERROR: --password-stdin 与 PROTOTYPE_PASSWORD_FILE 不能同时使用" >&2
        exit 2
    fi
    if [ -t 0 ]; then
        echo "ERROR: --password-stdin 需要通过标准输入提供密码" >&2
        exit 2
    fi
    IFS= read -r PASSWORD || true
elif [ -n "$PASSWORD_FILE" ]; then
    if [ ! -f "$PASSWORD_FILE" ] || [ ! -r "$PASSWORD_FILE" ]; then
        echo "ERROR: PROTOTYPE_PASSWORD_FILE 不存在或不可读" >&2
        exit 2
    fi
    IFS= read -r PASSWORD < "$PASSWORD_FILE" || true
elif [ -t 0 ]; then
    read -r -s -p "请输入共享页面密码：" PASSWORD
    printf '\n'
else
    echo "ERROR: 非交互模式需要 --password-stdin 或 PROTOTYPE_PASSWORD_FILE" >&2
    exit 2
fi

if [ -z "$PASSWORD" ]; then
    echo "ERROR: 密码不能为空" >&2
    exit 2
fi

echo "[1/2] 正在验证共享页面..."
COOKIE_FILE=$(mktemp)
chmod 600 "$COOKIE_FILE"
printf '%s' "$PASSWORD" | curl -sS -c "$COOKIE_FILE" -o /dev/null \
    -X POST "${BASE_URL}/s/${SHARE_ID}/unlock" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: ${BASE_URL}" \
    -H "Referer: ${LOGIN_URL}" \
    --data-urlencode password@-

if ! grep -q "sv_preview_${SHARE_ID}" "$COOKIE_FILE" 2>/dev/null; then
    echo "ERROR: 验证失败，未获取到预期认证 Cookie（请检查密码）" >&2
    exit 1
fi

TEMP_OUTPUT=$(mktemp "${OUTPUT_FILE}.tmp.XXXXXX")
echo "[2/2] 正在下载 HTML..."
HTTP_CODE=$(curl -sS -b "$COOKIE_FILE" -o "$TEMP_OUTPUT" -w "%{http_code}" \
    "${BASE_URL}/s/${SHARE_ID}/?v=2")

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: 获取页面失败，HTTP ${HTTP_CODE}" >&2
    exit 1
fi

if ! grep -qiE '<!DOCTYPE[[:space:]]+html|<html([[:space:]>])' "$TEMP_OUTPUT"; then
    echo "ERROR: 响应不是有效 HTML，未覆盖输出文件" >&2
    exit 1
fi

mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
TEMP_OUTPUT=""
echo "下载完成：$OUTPUT_FILE"
