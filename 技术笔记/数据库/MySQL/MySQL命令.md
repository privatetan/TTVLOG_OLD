# MySQL命令

1. show engine innodb status; 观察LRU列表及Free列表的使用情况。
2. show variables like 'AUTOCOMMIT'; 查看事务是否自动提交
3. set autocommit = 1; 开启自动提交事务，1:开启，0关闭
4. set session transaction isolation level read commit; 设置隔离级别
5. show table status like 'table_name'; 显示表的相关信息