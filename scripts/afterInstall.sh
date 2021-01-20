#!/bin/sh
set -e #何らかのエラーが発生した時点で、それ以降の処理を中断する
set -u # 未定義変数をエラーにする
#set -x # デバッグ用に冗長に出力する

TARGETDIRS=${1:-'resilience-stg01'}
defaultTag=${2:-'production'}
defaultSlack=${3:-'true'}
defaultSlackURL=${4:-'https://hooks.slack.com/services/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'}
defaultSlackCHN=${5:-'#031_git-deploy'}

cd /var/www/html/
sudo chown -R ncdev. ${TARGETDIRS}

cd ${TARGETDIRS}

# パーミッション変更
sudo chmod 2775 -R storage
sudo chmod 777 -R bootstrap/cache

# composer & npm install
echo "composer install"
sudo rm -rf vendor node_modules
sudo -u ncdev /usr/local/bin/composer install
sudo -u ncdev /usr/local/bin/composer dump-autoload
echo "npm install"
sudo -u ncdev npm install
echo "npm run"
sudo -u ncdev npm run prod
php artisan key:generate


# resilience-stg01をコピーしてresilience-stg10まで作成
cd /var/www/html/
for FIGURE in `seq -w 2 10`
do
   sudo cp -pr ${TARGETDIRS} "resilience-stg${FIGURE}"
done

# envのコピー
for NUM in `seq -w 1 10`
do
   cp "resilience-stg${NUM}.env.staging${NUM}" .env
done


## Slack送信フラグ
SLACK_NOTICE_DEPLOYED_FLAG=${defaultSlack}

## Slackへ通知
if $SLACK_NOTICE_DEPLOYED_FLAG eq true; then
        WEBHOOKURL=${defaultSlackURL}
        CHANNEL=${defaultSlackCHN}
        BOTNAME="autoDeployBot"
        FACEICON=":codedeploy:"
        MESSAGE="ExcuteCodeDeploy:`hostname`=>${TARGETDIRS}:${defaultTag}　IP:`curl ifconfig.io`"
        /usr/local/bin/initscript/slack_send.sh -u $WEBHOOKURL -c $CHANNEL -n $BOTNAME -i $FACEICON -m $MESSAGE;
fi

sudo nginx -s reload
sudo systemctl restart php-fpm
