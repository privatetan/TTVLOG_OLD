# ts接口&类&对象

- ##### 接口

- ##### 类

- ##### 对象

## 接口

##### 定义

```typescript
interface interface_name { 
}
```

##### 例子

接口：

```typescript
interface IAnimal { 
    type:string, 
    name:string, 
    behavior: ()=>string 
} 
```

类型

```typescript
var dog:IAnimal = { 
    type:"dog",
    name:"Tom", 
    behavior: ():string =>{return "汪汪"} 
} 
```

需要注意接口不能转换为 JavaScript，它只是 TypeScript 的一部分。

#### 接口继承（extends）

Typescript 允许接口继承多个接口。

定义

```typescript
interface interface_name extends interface_father1,interface_father2 { 
}
```

#### 多态



## 类

##### 定义

```typescript
class class_name { 
}
```

例子

```typescript
class Car { 
    // 字段 
    engine:string; 
    // 构造函数 
    constructor(engine:string) { 
        this.engine = engine;
    }  
    // 方法 
    disp():void { 
        console.log("发动机为 :   "+this.engine) 
    } 
}
```

#### 类的实例化对象

```typescript
var obj = new Car("Engine 1");

//访问数据
obj.engine;
obj.disp();
```

#### 类继承（extends）

支持单继承，多重继承。

#### 类实现接口（implements）

定义

```typescript
class class_name implements interface_name { 
}
```

#### 访问控制

- **public（默认）** : 公有，可以在任何地方被访问。
- **protected** : 受保护，可以被其自身以及其子类访问。
- **private** : 私有，只能被其定义所在的类访问。



## 对象

对象是包含一组键值对的实例

例子

```typescript
var object_name = { 
    key1: "value1", // 标量
    key2: "value",  
    key3: function() {
        // 函数
    }, 
    key4:["content1", "content2"] //集合
}
```

#### 