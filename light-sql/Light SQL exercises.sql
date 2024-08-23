-- SQL exercises 2022-12-06 v01.sql

---------------------------------------------------------------
-- Несколько небольших задач по пересечениям, сортировке, фильтрациям
---------------------------------------------------------------

---------------------------------------------------------------
/* 
Задача 1: Необходимо написать запрос, который позволит понять, идентичны ли данные в двух таблицах. Порядок хранения данных в таблицах значения не имеет.
create table t1(a number, b number);
create table t2(a number, b number);

/**/
 
/ ---------------------------------------------------------------
-- Для наборов с неповторяющимися данными
-- (Игнорирует дубли внутри таблицы)
select * from t1
minus 
select * from t2
union all
(
select * from t2
minus 
select * from t1
)
;

/* 
A	B
99	99
999	999

/**/
/ --------------------------------------------------------------- 
-- Для наборов с повторяющимися данными
select tabnm, a, b
from (
    select 'Table1' as tabnm, a, b, row_number() over (partition by a, b order by a, b) as rn from t1
    minus 
    select 'Table1' as tabnm, a, b, row_number() over (partition by a, b order by a, b) as rn from t2
    union all 
    (
    select 'Table2' as tabnm, t2.a, t2.b, row_number() over (partition by t2.a, t2.b order by t2.a, t2.b) as rn from t2 
    minus 
    select 'Table2' as tabnm, t1.a, t1.b, row_number() over (partition by t1.a, t1.b order by t1.a, t1.b) as rn from t1 
    )
    )
;
/* 
TABN	A	B
Table1	2	2
Table1	99	99
Table2	3	3
Table2	999	999

/**/

/*
-- drop table t1;
create table t1 (a integer, b integer);
 
insert into t1 (a, b) values (1, 1);
insert into t1 (a, b) values (2, 2);
insert into t1 (a, b) values (2, 2);
insert into t1 (a, b) values (3, 3);
insert into t1 (a, b) values (4, 4);
insert into t1 (a, b) values (99, 99);

--drop table t2;
create table t2 (a integer, b integer);
 
insert into t2 (a, b) values (1, 1);
insert into t2 (a, b) values (2, 2);
insert into t2 (a, b) values (3, 3);
insert into t2 (a, b) values (3, 3);
insert into t2 (a, b) values (4, 4);
insert into t2 (a, b) values (999, 999);
/**/


---------------------------------------------------------------
/* 
Задача 2: Имеется таблица без первичного ключа. 
Известно, что в таблице имеется задвоение данных. Необходимо удалить дубликаты из таблицы.

create table t (a number, b number);

Пример данных:
a b
1 1
2 2
2 2
3 3
3 3
3 3
Требуемый результат:
a b
1 1
2 2
3 3
/**/

/ ---------------------------------------------------------------    
-- Удаление дубликатов в таблице (решение через ROWID
delete from T1
 where t1.rowid in (select t.rowid
                      from (select p.a ,p.b ,p.rowid
                                  ,ROW_NUMBER() over(partition by a, b order by a, b) grp_rn -- Номер повторяющейся записи 
                              from T1 p) t
                     where t.grp_rn > 1);
                                                      
/* 
CREATE TABLE T1 (A INTEGER, B INTEGER) NOLOGGING;

insert into T1 (A, B)
values (1, 1);

insert into T1 (A, B)
values (1, 1);

insert into T1 (A, B)
values (2, 2);

insert into T1 (A, B)
values (2, 2);

insert into T1 (A, B)
values (3, 3);

/**/

---------------------------------------------------------------
/* 
Задача 3: Есть таблица с данными в виде дерева. Необходимо написать запрос для получения дерева от корневого узла, узел 5 и все его потомки не должны попасть в результат,  нужно вывести для каждого узла имя его родителя, данные отсортировать в порядке возрастания ID с учетом иерархии 
create table t (id number, -- идентификатор узла
 pid number, -- идентификатор родительского узла
 nam varchar2(255))-- наименование

/**/

/ --------------------------------------------------------------- 
-- Данные дерева (кроме узла 5
select t.id, t.pid,
       t.nam,
       PRIOR t.cxnam                                    as parent_nam,
       ltrim(SYS_CONNECT_BY_PATH(t.nam, ' → '),' → ') as full_path,   -- Опционально, полный путь
       level                                          as lev          -- Опционально, уровень
  from T
 START WITH t.pid is null 
 CONNECT BY PRIOR t.id = t.pid -- Обход всех пунктов
   and t.id != 5 -- Кроме пятого
 order siblings by t.nam;
 
 
/* 
create table t (id number, -- идентификатор узла
 pid number, -- идентификатор родительского узла
 nam varchar2(255))-- наименование
;


insert into t (id, pid, nam)
values (1, null, 'Корень');

insert into t (id, pid, nam)
values (2, 1, 'Узел2');

insert into t (id, pid, nam)
values (3, 1, 'Узел3');

insert into t (id, pid, nam)
values (4, 2, 'Узел4');

insert into t (id, pid, nam)
values (5, 4, 'Узел5');

insert into t (id, pid, nam)
values (6, 5, 'Узел6');

insert into t (id, pid, nam)
values (7, 4, 'Узел7');

select * from t;
/**/


   

---------------------------------------------------------------
/* 

Задача 4: Имеется таблица курсов валют следующей структуры:
create table RATES(curr_id number, -- ид валюты
                   date_rate DATE, -- дата курса
                   rate NUMBER) -- значение курса 
Курс валюты устанавливается не на каждую календарную дату и действует до следующей смены курса
Уникальный ключ: curr_id + date_rate.

Напишите запрос, который покажет действующее значение курса заданной валюты на любую заданную календарную дату.

/**/


/ --------------------------------------------------------------- 
-- Получить последний курс валюты на заданную дату
select last_rate 
from ( -- Курсы валюты и последние значения курса до финальной даты 
        select curr_id, date_rate, rate
              ,last_value(rate) over (partition by curr_id order by curr_id, date_rate range between unbounded preceding and unbounded following) as last_rate
          from RATES r
          where 1=1
            and r.curr_id = 2
            and r.date_rate <= to_date('10.01.2010', 'dd.mm.yyyy')
    )
where rownum = 1;


/* 
create table RATES
(CURR_ID     integer,
 DATE_RATE   date,
 RATE        number
) ;
/
insert into RATES
  (curr_id, date_rate, rate)
values
  (1, to_date('01.01.2010', 'dd.mm.yyyy'), 30);
 
insert into RATES
  (curr_id, date_rate, rate)
values
  (1, to_date('02.01.2010', 'dd.mm.yyyy'), 32);
 
insert into RATES
  (curr_id, date_rate, rate)
values
  (1, to_date('05.01.2010', 'dd.mm.yyyy'), 33);
 
 
insert into RATES
  (curr_id, date_rate, rate)
values
  (2, to_date('01.01.2010', 'dd.mm.yyyy'), 40);
  
insert into RATES
  (curr_id, date_rate, rate)
values
  (2, to_date('08.01.2010', 'dd.mm.yyyy'), 41);
 
insert into RATES
  (curr_id, date_rate, rate)
values
  (2, to_date('15.01.2010', 'dd.mm.yyyy'), 42);
/**/



/ ---------------------------------------------------------------
/* 
Задача 5: Дана таблица валют (справочник), необходимо написать запрос, который возвращает отсортированный список валют в алфавитном порядке по столбцу ISO_CODE, причем первыми должны идти основные валюты, с которыми работает банк: RUR, USD, EUR.
create table tbl_currency_dict (iso_code varchar2(255), iso_name varchar2(255));
*/


/ ---------------------------------------------------------------   
-- Список валют с сортировкой 
select cd.iso_code, cd.iso_name
  from TBL_CURRENCY_DICT cd
order by decode(cd.iso_code
    , 'RUR', 100
    , 'USD', 100
    , 'EUR', 100
    , 1000), cd.iso_code;
    
/*
-- Таблица TBL_CURRENCY_DICT
create table TBL_CURRENCY_DICT (
  ISO_CODE varchar2(255), 
  ISO_NAME varchar2(255)
);

-- Данные TBL_CURRENCY_DICT
INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('USD', 'Доллар США');

INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('CHF', 'Швейцарский франк');

INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('AED', 'Дирхам (ОАЭ)');

INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('RUR', 'Российский Рубль');

INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('ETB', 'Эфиопский быр');

INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('MXN', 'Мексиканское песо');

INSERT INTO tbl_currency_dict
  (iso_code, iso_name)
VALUES
  ('EUR', 'ЕВРО');
/**/
