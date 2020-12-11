# git命令

## git同时连接多个远程仓库的配置

1. 查看远程仓库

   ```shell
   git remote -v
   ```

2. 添加远程仓库

   ```shell
   # git remote add 别名 远程仓库地址
   git remote add origin git@gitee.com:tiankafei/tiankafei.git
   ```

3. 如果此时一直pull不下去，也push不上去，可以使用以下命令使远程仓库和本地同步，消除差异

   ```shell
   # git pull 别名 分支名 --allow-unrelated-histories
   git pull origin master --allow-unrelated-histories
   ```

4. 消除远程仓库与本地仓库的差异之后，执行推送

   ```shell
   #git push 别名 分支名
   git push origin master
   ```

5. 多个远程分值的提交记录，必须一致才能够一起push远程仓库，如果有一个不一致的就不能同步进行。如果发现有不一致的，重复上述操作。一直到所有远程仓库的提交记录一致为止。

6. 删除所有远程仓库的配置

   ```shell
   #git remote remove 别名
   git remote remove origin
   ```

7. 选择一个主仓库，用来拉取

   ```shell
   #git remote add 别名 分支名
   git remote add origin git@gitee.com:tiankafei/tiankafei.git
   ```

8. 把其他仓库加进来

   ```shell
   # git remote set-url --add 别名 远程仓库地址
   git remote set-url --add origin git@github.com:tiankafei/tiankafei.git
   ```

9. 使用以上加入远程仓库命令的好处是：当执行 git push origin master时，会直接把代码一起push到多个远程仓库。

## 码云、GitHub如何更新fork后的代码

1. clone 自己的fork分支到本地

   ```shell
   git clone git@gitee.com:tiankafei/RuoYi.git
   ```

2. 增加源分支地址到你项目远程分支列表中(此处是关键)，先得将原来的仓库指定为upstream，命令为

   ```shell
   git remote add upstream https://gitee.com/y_project/RuoYi.git
   git remote add upstream https://gitee.com/geekidea/spring-boot-plus.git
   ```

   此处可使用git remote -v查看远程分支列表

   ```shell
   git remote -v
   ```

3. fetch源分支的新版本到本地

   ```shell
   git fetch upstream
   ```

4. 合并两个版本的代码

   ```shell
   git merge upstream/master
   ```

5. 将合并后的代码push到码云或github上去

   ```shell
   git push origin master
   ```


## git版本回退相关问题

### 本地分支版本回退的方法

如果在本地做了错误提交，回退版本的方法为：

1. 使用git reflog命令查看历史提交记录的commit id
2. 使用git reset --hard commit_id，commit_id为你要回退版本的commit id的前几位

### 自己的远程分支版本回退的方法

1. 使用git reflog命令查看历史提交记录的commit id
2. 使用git reset --hard commit_id回退本地分支，commit_id为你要回退版本的commit id的前几位
3. 使用git push -f强制推送到远程分支

### 公共远程分支版本回退的方法

1. 使用git reflog命令查看历史提交记录的commit id
2. 使用git revert commit_id或者git revert HEAD~0/1/2指令撤销最近的提交
3. revert合并代码，主要是去掉新代码，解决冲突；如果没有冲突，使用使用git push -f强制推送到远程分支
4. 没有办法的办法
5. 从头再来，删仓重建

### 需要注意的点

1. 使用git reflog命令后，如果记录很长，可以在大写锁定状态下输入一次'Q'或者两次'Z'退出git log和git reflog状态
2. git revert指令注意事项
   1. revert是撤销一次提交，所以commit id是你要回滚到的版本的前一次提交
   2. 使用revert HEAD是撤销最近的一次提交，如果你最近一次提交是用revert命令产生的，那么再执行一次就相当于撤销了上次的撤销操作，即连续两次执行revert HEAD命令，相当于没有执行
   3. 使用revert HEAD~1表示撤销最近2次提交，后面的数字是从0开始的，即revert HEAD~n撤销n+1次提交
   4. 如果使用revert撤销的不是最近一次提交，那么一定会有代码冲突，需要合并代码，合并代码只需要把当前的代码全部取消，保留之前版本的代码即可。

## git for windows下的Filename too long

```shell
git config --global core.longpaths true
```

## git的标签

### git查看所有的标签

```shell
git tag
```

### git查看标签代码

```shell
git checkout tag_name
```

> 但是，这时候 git 可能会提示你当前处于一个“detached HEAD” 状态。因为 tag 相当于是一个快照，是不能更改它的代码的。如果要在 tag 代码的基础上做修改，你需要一个分支

### git切换到某个tag

```sh
git checkout -b branch_name tag_name
```

