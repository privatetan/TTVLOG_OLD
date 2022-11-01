# BeanPostProcessor

BeanPostProcessor

- 允许自定义修改Bean，比如：我们可以修改bean的属性，可以给Bean生成一个动态代理实例等等；
- Spring AOP的底层的一些处理也是通过实现BeanPostProcessor来执行代理包装逻辑的。

## 定义

```java
public interface BeanPostProcessor {
  //bean初始化方法调用前被调用
	@Nullable
	default Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}
  //bean初始化方法调用后被调用
	@Nullable
	default Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}
}
```



