# git版本回退相关问题

## 本地分支版本回退的方法

如果在本地做了错误提交，回退版本的方法为：

1. 使用git reflog命令查看历史提交记录的commit id
2. 使用git reset --hard commit_id，commit_id为你要回退版本的commit id的前几位

## 自己的远程分支版本回退的方法

1. 使用git reflog命令查看历史提交记录的commit id
2. 使用git reset --hard commit_id回退本地分支，commit_id为你要回退版本的commit id的前几位
3. 使用git push -f强制推送到远程分支

## 公共远程分支版本回退的方法

1. 使用git reflog命令查看历史提交记录的commit id
2. 使用git revert commit_id或者git revert HEAD~0/1/2指令撤销最近的提交
3. revert合并代码，主要是去掉新代码，解决冲突；如果没有冲突，使用使用git push -f强制推送到远程分支
4. 没有办法的办法
5. 从头再来，删仓重建

# 注意

1. 使用git reflog命令后，如果记录很长，可以在大写锁定状态下输入一次'Q'或者两次'Z'退出git log和git reflog状态
2. git revert指令注意事项
   1. revert是撤销一次提交，所以commit id是你要回滚到的版本的前一次提交
   2. 使用revert HEAD是撤销最近的一次提交，如果你最近一次提交是用revert命令产生的，那么再执行一次就相当于撤销了上次的撤销操作，即连续两次执行revert HEAD命令，相当于没有执行
   3. 使用revert HEAD~1表示撤销最近2次提交，后面的数字是从0开始的，即revert HEAD~n撤销n+1次提交
   4. 如果使用revert撤销的不是最近一次提交，那么一定会有代码冲突，需要合并代码，合并代码只需要把当前的代码全部取消，保留之前版本的代码即可。