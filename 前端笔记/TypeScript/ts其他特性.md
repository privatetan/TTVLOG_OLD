# ts其他特性

- ##### 命令空间

- ##### 模块

- ##### 声明文件



## 命名空间

命名空间的目的就是**解决重名问题**。

##### 定义

```typescript
namespace SpaceName { 
   //如果我们需要在外部可以调用 NameSpaceName 中的类和接口，则需要在类和接口添加 export 关键字。
   export interface InterfaceName {   ...   }  
   export class ClassName {  ...    }  
}
```

##### 调用

1. ```typescript
   NameSpaceName.ClassName;
   ```

2. ```typescript
   //如果一个命名空间在一个单独的 TypeScript 文件中，则应使用三斜杠 /// 引用它，语法格式如下：
   /// <reference path = "SomeFileName.ts" />
   ```

#### 嵌套命名空间

定义

```typescript
namespace SpaceNameOuter { 
   //如果我们需要在外部可以调用 NameSpaceName 中的类和接口，则需要在类和接口添加 export 关键字。
   namespace SpaceNameInner {  
   		export class ClassName {  ...  }  
   }  
}
```



## 模块

导入模块：import

```typescript
import someInterfaceRef = require("./SomeInterface");
```

导出模块：export

```typescript
export interface SomeInterface { 
   // code
}
```



## 声明文件

声明文件以 **.d.ts** 为后缀；

定义声明文件或模块

```typescript
declare module Module_Name {
}
```

引入声明文件

```typescript
/// <reference path = " runoob.d.ts" />
```

