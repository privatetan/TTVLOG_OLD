# git使用笔记

1. ##### 查看远程仓库地址

git remote -v

2. ##### 删除远程仓库

git remote rm origin

3. ##### 添加远程仓库

git remote add origin https://xxx.com/aaa.git

4. ##### 解决git push 发生HTTP2.0错误

git config --global http.version HTTP/1.1

5. ##### 设置/取消代理

设置：

git config --global http.proxy 'socks5://127.0.0.1:7890'     //7890是代理端口

git config --global https.proxy 'socks5://127.0.0.1:7890'   

取消：

git config --global --unset http.proxy

git config --global --unset https.proxy

