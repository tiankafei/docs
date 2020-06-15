#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e

java -jar node-1.0-SNAPSHOT-jar-with-dependencies.jar

# 生成静态文件
npm run docs:build

# 进入生成的文件夹
cd dist

# 如果是发布到自定义域名
echo 'tiankafei.top' > CNAME

git config --global user.email "weishuangshuang89@163.com"
git config --global user.name "tiankafei"
git init
git add -A
git commit -m 'deploy'

git push -f git@github.com:tiankafei/tiankafei.github.io.git master

cd -