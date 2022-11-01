# ts数据类型



## 数据类型

|           类型           |  类型名  |                 描述                  |                             备注                             |
| :----------------------: | :------: | :-----------------------------------: | :----------------------------------------------------------: |
|        **number**        |   数字   |          双精度 64 位浮点值           | 它可以用来表示整数和分数。<br />TypeScript 和 JavaScript 没有整数类型。 |
|        **string**        |  字符串  |             一个字符系列              | 使用单引号（**'**）或双引号（**"**）来表示字符串类型。<br />反引号（**`**）来定义多行文本和内嵌表达式。 |
|       **boolean**        |   布尔   |       表示逻辑值：true 和 false       |                                                              |
| **type[]｜Array\<type>** |   数组   |            声明变量为数组             | 在元素类型后面加上[] `let arr: number[] = [1, 2]`<br />or使用数组泛型 `let arr: Array<number> = [1, 2]` |
|  **[type1,type2,...]**   |   元组   |     表示已知元素数量和类型的数组      |        各元素的类型不必相同，对应位置的类型需要相同。        |
|         **enum**         |   枚举   |             定义数值集合              |                                                              |
|         **void**         |  无返回  |          表示方法没有返回值           |                         常作用于方法                         |
|         **any**          |   任意   | 声明为 any 的变量可以赋予任意类型的值 |                                                              |
|         **null**         |  值缺失  |              对象值缺失               |                      表示一个空对象引用                      |
|      **undefined**       |  未定义  |      初始化变量为一个未定义的值       |                                                              |
|        **never**         |   其他   |            从不会出现的值             |      never 是其它类型（包括 null 和 undefined）的子类型      |
|         **Map**          |   集合   |      保存键值对，并保持插入顺序       |                     new 关键字来创建 Map                     |
|     **type1｜type2**     | 联合类型 |   通过管道（\|）将变量设置多种类型    |                                                              |

## 详解

### 数组

定义：`type[]`  或者 `Array<type>`

```typescript
var arr: number[] = [1, 2];
或者
var arr: Array<number> = [1,2];
```

### 元组

定义：`[type1,type2,...]`

```typescript
var data: [string, number];
data = ['typeValue', 1];    // 运行正常
data = [1, 'typeValue'];    // 报错
```

### 枚举

定义：`enum`

```typescript
enum Color {Red, Green, Blue}
var colorIndex : Color = Color.Green;
console.log(colorIndex)    //1，返回元素索引，默认从0开始
```

枚举元素索引，默认从0开始，也可以指定索引

```typescript
//指定开始值
enum Color {Red=1, Green, Blue}
//指定所有值
enum Color {Red=1, Green=3, Blue=6}
```

获取枚举元素值

```typescript
enum Color {Red, Green, Blue}
var colorValue : string = Color[1];
console.log(colorValue)    //Green，通过索引访问，返回元素值
```

### void

定义：`void`

void，常作用于方法，表无返回值。

```typescript
function voidMethod(): void {
    console.log('say hello');
}
```

void，作用于变量，无意义。

```typescript
var voidValue: void = undefined;
```

### any

定义：`any`

表示任意类型

```typescript
var any_string: any = 'any_string';
console.log('any string :' + any_string);

var any_number: any = 123;
console.log('any number :' + any_number);

var any_value: any = 123001;
console.log('any value number :' + any_value);
any_value = 'any_value_string';
console.log('any value string :' + any_value);
any_value = true;
console.log('any value boolean :' + any_value);
```

### null

定义：`null`

表示对象值缺失，空的对象引用

```typescript
var nullValue: null;
nullValue = 123;       //Type '123' is not assignable to type 'null'.
nullValue = undefined; //Type 'undefined' is not assignable to type 'null'.
```

可以使用`null`来清空对象

```typescript
var person = null;
```

`typeof`检测`null`是`object`类型

```typescript
console.log(typeof null);  //输出 object
```

### undefined

定义：`undefined`

表示一个没有设值的变量

```typescript
var undefinedValue:undefined;
console.log(undefinedValue);  //输出 undefined
```

可以使用`undefined`来清空对象

```typescript
var person = undefined;
```

`typeof`检测`undefined`变量会返回`undefined`

```typescript
var undefinedValue:undefined;
console.log(typeof undefinedValue);
```

### never

定义：`never`

其它类型（包括 null 和 undefined）的子类型，代表从不会出现的值，

**变量**：声明为 never 类型的变量只能被 never 类型所赋值；

```typescript
let x: never;
let y: number;

x = 123; // 编译错误，数字类型不能转为 never 类型

x = (()=>{ throw new Error('exception')})(); // 运行正确，never 类型可以赋值给 never类型

y = (()=>{ throw new Error('exception')})(); // 运行正确，never 类型可以赋值给 数字类型
```

**函数**：通常表现为抛出异常或无法执行到终止点（例如无限循环）。

```typescript
// 返回值为 never 的函数可以是抛出异常的情况
function error(message: string): never {
    throw new Error(message);
}

// 返回值为 never 的函数可以是无法被执行到的终止点的情况
function loop(): never {
    while (true) {}
}
```