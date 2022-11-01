# Node基础

## Node入门

1. ###### 执行Node文件

   命令：node  script.js

2. ###### Node的REPL模式

   REPL模式：read-eval-print loop，输入-求值-输出循环；

   运行无参的node命令，会启动一个JS的交互式Shell；

   两次Ctrl+C即可退出REPL模式。

3. ##### Node包管理工具：npm

   npm，是nodejs官方提供的第三方包管理工具

   Npm config:

   ```shell
   home = "https://npm.taobao.org" 
   https-proxy = "http://127.0.0.1:7890" 
   proxy = "http://127.0.0.1:7890" 
   registry = "https://registry.npmjs.org/" 
   ```

   

4. ###### Node多版本管理器：nvm

   nvm，是nodejs社区开发的多版本管理器，用于维护多个版本的nodejs实例；

   nvm，通常指creationix/nvm或者visionmedia/n；

   安装visionmedia/n命令：npm install -g n；

   使用指定版本运行命令：n use 版本号 script.js。

5. ###### 自动重启NodeJS工具：supervisor

   nodejs只有在第一次引用到某部分时才会解析脚本文件，之后会直接访问内存，避免重复载入；在开发时，修改代码后，必须重新运行nodejs才生效。

   supervisor，会监视代码的改动并自动重启nodejs；

   安装命令：npm install -g supervisor



## 异步式IO与事件编程

### 异步式IO

###### 阻塞与非阻塞

|     阻塞（同步式IO）      |    非阻塞（异步式IO）    |
| :-----------------------: | :----------------------: |
|    多线程实现高吞吐量     |    单线程实现高吞吐量    |
| 由操作系统调度使用多核CPU |   单进程绑定到单核CPU    |
|    难以充分使用CPU资源    |    可充分使用CPU资源     |
| 内存轨迹大，数据局部性弱  | 内存轨迹小，数据局部性强 |
|     符合线性编程思维      |    不符合线性编程思维    |

### 回调函数

Readfile.js

```javascript
var fs = require('fs');
fs.readFile('file.txt','utf-8',function(err,data){
  if(err){
    console.error(err);
  }else{
    console.log(data);
  }
});
console.log('end. ');
```

运行结果：

```
end.
Contents of the file.
```

fs.readFile方法接收3个参数：文件名、编码方式、回调函数。

nodejs中，并不是所有的API都提供了同步和异步版本，nodejs不鼓励使用同步IO。

### 事件

nodejs的异步IO操作完成时，都会发送一个事件到事件队列。

###### EventEmitter

在开发者看来，事件都是由EventEmitter对象提供。

###### 事件循环机制

事件循环：nodejs程序由事件循环开始，到事件循环结束，所有逻辑都是事件的回调函数。

在事件循环中，程序的入口就是事件循环第一个事件的回调函数。

nodejs的事件循环对开发者是不可见的，由libev库实现；

libev事件循环的每一次迭代，在nodejs中就是一次Tick，libev会不断检查是否有活动的、可提供检测的事件监听器，知道检测不到时才退出事件循环，进程结束。

## 模块与包

模块（module）和包（package）是nodejs的重要组成部分，两者没有本质区别，一般不作区分；

nodejs提供require函数来调用其他模块，模块都是基于文件的；

nodejs的模块和包机制的实现参照了CommonJS标准，但并未完全遵循。

### 模块（Module）

##### 模块分类

- ##### 内置模块

- ##### 自定义模块

- ##### 第三方模块（包）

模块，是nodejs应用基本组成，文件和模块一一对应：一个nodejs文件就是一个模块。

查看js文件的模块信息

```javascript
console.log(module);  #显示当前文件的模块信息
```

##### 创建模块

exports：公开模块接口 

注意：默认下，exports指向的是module.exports指向对象，require()结果永远是module.exports指向对象。

##### 获取模块

require：获取模块接口

注意：requrie获取的永远是module.exports指向对象

##### 模块的加载机制

1. **模块优先从缓存中加载**：模块在第一次加载后就会被缓存，即多次require()不会导致模块代码的重复执行。

2. ##### 内置模块加载优先级最高

3. ##### 加载自定义模块时，须以`./`或者`../`开头的路径名。

4. ##### require()加载自定义模块时未指定文件扩展名的加载顺序：

   - 按确切文件名
   - 补全`.js`
   - 补全`.json`
   - 补全`.node`
   - 加载失败，报错

5. ##### 在内置模块、自定义模块找不到时，会尝试从父目录开始到磁盘根目录，在`/node_modules`文件夹加载第三方模块。

6. `require(‘目录’)`时，有三种加载方式：

   - 在被加载目录下查找`package.json`文件，并以`main`属性，作为加载入口；
   - 如果`package.json`文件不存在，或者`main`属性不存在时，则试图加载目录下`index.js`文件；
   - 如果都找不到，则报错。

   

### 包（Package）

包，是在模块基础上更深一步的抽象，类似于java的包（package）；

包，通常是一些模块的集合，对模块完成抽象封装，并对外提供接口的函数库。

包将某个独立的功能封装起来，用于发布、更新、依赖管理和版本控制。

##### 文件夹的模块

最简单的包，就是一个作为文件夹的模块。

##### package.json

package.json 位于模块的目录下，用于定义包的属性。

##### package.json 属性说明

- **name - 包名。**
- **version - 包的版本号。**
- description - 包的描述。
- homepage - 包的官网 url 。
- author - 包的作者姓名。
- contributors - 包的其他贡献者姓名。
- dependencies - 依赖包列表。如果依赖包没有安装，npm 会自动将依赖包安装在 node_module 目录下。
- repository - 包代码存放的地方的类型，可以是 `git` 或` svn`，`git `可在 Github 上。
- **main - main 字段指定了程序的主入口文件**，`require('moduleName')` 就会加载这个文件。这个字段的默认值是模块根目录下面的 `index.js`。
- keywords - 关键字。

##### 规范的包需满足三个条件

1. 包必须以单独的目录存在；
2. 包的顶级目录须有`package.json`包配置文件；
3. `package.json`文件中必须包含`name`、`version`、`main`三个属性。

##### 开发包

1. 新建包目录：`node-tools`
2. 在包目录下新建三个文件：
   - `package.json`：包配置文件
   - `index.js`：包的入口文件，require()导入包时，默认加载该文件
   - `README.md`：包说明文档

##### 发布包

1. 注册npm账户
2. 终端登录npm账户（npm官方地址）
3. `npm publish` 命令发布

##### 删除发布的包

```shell
npm unpublish 包名 --force
```

注意：

1. 只能删除72小时内发布的包
2. 删除的包，24小时内不能再次发布
3. 发布包时需慎重



## Node包管理器-npm

npm，是nodejs官方提供的第三方包管理工具

### 获取包

命令：npm [install/i] [package_name]

### 本地模式与全局模式

npm安装包的模式：本地模式和全局模式；

默认情况下，npm install，采用本地安装模式，并将包安装到当前项目的node_modules子目录下；

