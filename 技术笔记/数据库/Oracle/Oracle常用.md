## 1.查看oracle数据库全表扫描的sql

```sql
1. select * from v$sql_plan v where v.operation = 'TABLE ACCESS’ and v.OPTIONS = 'FULL' and v.OBJECT_OWNER='MS';--指定用户下
2. select s.SQL_TEXT from v$sqlarea s where s.SQL_ID = '4dpd97jh2gzsd' and s.HASH_VALUE = '1613233933' and s.PLAN_HASH_VALUE = '3592287464';
```

或者

```sql
select s.SQL_TEXT from v$sqlarea s where s.ADDRESS = '00000000A65D2318';
```

## 

## 二、oracle查询慢sql

```sql
select sa.SQL_TEXT,
 sa.SQL_FULLTEXT,
 sa.EXECUTIONS "执行次数",
 round(sa.ELAPSED_TIME / 1000000, 2) "总执行时间",
 round(sa.ELAPSED_TIME / 1000000 / sa.EXECUTIONS, 2) "平均执行时间",
 sa.COMMAND_TYPE,
 sa.PARSING_USER_ID "用户ID",
 u.username "用户名",
 sa.HASH_VALUE
from v$sqlarea sa
left join all_users u
on sa.PARSING_USER_ID = u.user_id
where sa.EXECUTIONS > 0
order by (sa.ELAPSED_TIME / sa.EXECUTIONS) desc
```



## 三、oracle查询执行最多的sql

```sql
select 
 s.SQL_TEXT,
 s.EXECUTIONS "执行次数", 
 s.PARSING_USER_ID "用户名",
 rank() over(order by EXECUTIONS desc) EXEC_RANK
from v$sql s left join all_users u
on u.USER_ID = s.PARSING_USER_ID
```



## 四、oracle查看执行计划sql

```sql
1st: explain plan for select * from dual;
2sd: select * from table(dbms_xplan.dispaly());
```



## 五、存在更新,不存在新增

### Oracle

```sql
merge into table_name t1
using (
select 
#{column1} as column1 
#{column2} as column2
from dual) t2
on  (t1.column1 = t2.column1)
when matched then 
update set t1.column2 = t2.column2 
when not matched 
then insert (column1,column2)
values (t2.column1,t2.column2)
```

### mysql

```sql
insert into emailverify  (1, 2) 
values (#{1},#{2}) 
on duplicate key update 2 = #{2}
```

## 六、存储过程

```sql
create or replace procedure proc_name as
begin 
    for temp in 
    (select column1,column2,column3 from table_name where column2 = #{abc} )
    loop 
      insert table_name2 (column1,column2) values (temp.column1,temp.column2);
     commit;
    end loop;
end proc_name;
/
execute proc_name;
commit;
```

