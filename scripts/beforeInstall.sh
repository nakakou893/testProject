#!/bin/sh
set -e #何らかのエラーが発生した時点で、それ以降の処理を中断する
set -u # 未定義変数をエラーにする
#set -x # デバッグ用に冗長に出力する

cd /var/www/html/
sudo mkdir -p resilience-stg01
