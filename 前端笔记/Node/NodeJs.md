# Node.js

## 一、Node.js

Node.js，可以让JavaScript运行在服务端的开发平台。

Node.js的JavaScript引擎是V8。

## 二、Node.js架构

Node.js采用“**异步I/O**”与“**事件驱动**”架构设计，这也是Node.js最大的特性。

Node.js架构包括

- Node标准库
- Node下层接口
- V8引擎
- libuv库
- Libeio库
- Libev库
- IOCP机制

Libuv库通过封装Libeio库、Libev库来使用epoll或者kqueue，从而支持事件驱动和异步I/O。

Libuv库使用Windows的IOCP机制，以在不同平台实现同样的高性能。

## 三、异步I/O与事件驱动

与多线程模型一样，事件驱动模型也是高并发的解决方案

Node.js采用**异步I/O**与**事件驱动**处理请求；

Node.js使用的单线程，对于所有的请求，都采用异步方式处理；

Node.js在执行时，会维护一个事件队列，程序在执行时进入事件循环等待下一个事件的到来，每个异步IO的请求完成后会被推送到事件队列，等待进行进行处理。

## 四、CommomJS规范

CommonJS规范是为了统一JavaScript在浏览器之外的实现而制定的一套规范。

CommonJS不参与标准库的实现，具体实现交由类似NodeJs之类的项目完成；

CommonJS规范包括：

- 模块（modules）
- 包（packages）
- 系统（system）
- 二进制（binary）
- 控制台（console）
- 编码（encoding）
- 文件系统（filesystems）
- 套接字（sockets）
- 单元测试（unit testing）等

NodeJs是CommonJS规范最热门的实现。