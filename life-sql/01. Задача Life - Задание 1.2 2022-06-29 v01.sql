-- SqlLog SQL-задач LIFE 2022-06-28 v01
---------------------------------------------------------------
----  Задание на разработчика БД - Реализовать задачу Жизнь
---------------------------------------------------------------

/* 

---------------------------------------------------------------
№1.2 - ОБЯЗАТЕЛЬНОЕ
Напишите DDL- команды, при помощи которых Вы бы описали естественные для игры «Жизнь» ограничения на таблицу Life.

/**/

---------------------------------------------------------------
-- РЕШЕНИЕ ЗАДАЧИ 
/*
-- Кроме ограничений:
  PK_LIFE
  CHK_LIFE_GEN
  CHK_LIFE_X
  CHK_LIFE_Y

привожу DDL код создания таблицы.
Расчитываем на небольшую загрузку данными.
/**/

-- Drop table
drop table LIFE cascade constraints;
-- Create table
create table LIFE
(
  x   NUMBER not null,
  y   NUMBER not null,
  gen NUMBER not null
);
-- Add comments to the table 
comment on table LIFE
  is 'Карта поколений LIFE';
-- Add comments to the columns 
comment on column LIFE.x
  is 'Координата X';
comment on column LIFE.y
  is 'Координата Y';
comment on column LIFE.gen
  is 'Код генерации карты';
-- Create/Recreate primary, unique and foreign key constraints 
alter table LIFE
  add constraint PK_LIFE primary key (GEN, X, Y)
  using index;
-- Create/Recreate check constraints 
alter table LIFE
  add constraint CHK_LIFE_GEN
  check (gen = trunc(gen) and gen > 0);
alter table LIFE
  add constraint CHK_LIFE_X
  check (x = trunc(x));
alter table LIFE
  add constraint CHK_LIFE_Y
  check (y = trunc(y));
;     


---------------------------------------------------------------
-- Просмотр таблицы LIFE
select p.*
      ,sum(p.x * p.y) over () as check_sum 
      ,p.rowid
  from LIFE p
 where 1 = 1
 order by gen desc, y, x
;/**/
