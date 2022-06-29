-- SqlLog SQL-задач LIFE 2022-06-28 v01
---------------------------------------------------------------
----  Задание на разработчика БД - Реализовать задачу Алхимия
---------------------------------------------------------------

/* 
№4
Даны таблицы
1.  Алхимические ингредиенты - Spices
  ID_spice  Name_of_spice
  --------------------------------------------------------------- 
  1 Жир тролля
  2 Уши эльфа
  3 Шерсть хоббита
  … …

2.  Эффекты зелий - Effects_of_potions

  ID_effect Name_of_Effect
  --------------------------------------------------------------- 
  1 Восстановление здоровья
  2 Увеличение силы
  3 Урон огнём
  … …

3.  Свойства ингредиентов -  mm_Spices_Effects

  ID_spice  ID_effect
  --------------------------------------------------------------- 
  … …

Таблица «Свойства ингредиентов» разрешает отношение многие-ко-многим между первыми двумя таблицами.  У одного ингредиента может быть от 1 до 4 потенциальных эффектов.

Правила алхимии. 
1.	При изготовлении зелья можно смешать до 3-х ингредиентов
2.	Если в какой-либо паре смешиваемых ингредиентов есть один или более совпадающих эффектов, то изготовленное зелье будет обладать соответствующим эффектом (эффектами)


---------------------------------------------------------------
№4.1 – ОБЯЗАТЕЛЬНОЕ
Написать SQL-запрос, который возвращает составы зелий, имеющих 5 или более эффектов
Каково максимально возможное количество эффектов в зелье?


/**/

/
---------------------------------------------------------------
-- РЕШЕНИЕ ЗАДАЧИ 
-- Используется ряд подзапросов для наглядности
-- Применимость БД: Oracle v11
-- Cоставы зелий, имеющих 5 или более эффектов

-- ДОПУЩЕНИЕ:
--   * В зелье не должно попадать два одинаковых ингредиента

-- EFFECTS_CNT -- Максимально возможное количество эффектов в зелье

with
Q_SPICES_TWO as (
  -- Смешивание ДВУХ ингредиентов
  select -- Смешивание ДВУХ ингредиентов
         s.id_spice as id_spice1
        ,s2.id_spice as id_spice2
         -- Допполя сортировки, для исключения повторов
        ,case when s.id_spice < s2.id_spice then s.id_spice else s2.id_spice end as id_spice_min 
        ,case when s.id_spice > s2.id_spice then s.id_spice else s2.id_spice end as id_spice_max
    from SPICES s
    left join (--
          select t.id_spice
            from SPICES t
         ) s2
      on s2.id_spice != s.id_spice -- Без повторов 
--   order by id_spice1 nulls first, id_spice2 nulls first
) -- /Q_SPICES_TWO
,Q_SPICES_TWO2 as (
  -- Смешивание ДВУХ ингредиентов без повторов
  select distinct id_spice_min as id_spice1
        ,id_spice_max          as id_spice2
    from Q_SPICES_TWO s
--   order by 1 nulls first, 2 nulls first
) -- /Q_SPICES_TWO2
, Q_SPICES as (
  -- Смешивание ДВУХ, ТРЕХ ингредиентов
  select -- Смешивание ДВУХ ингредиентов
         s.id_spice1
        ,s.id_spice2
        ,null        as id_spice3
        ,null        as id_spice_min
        ,s.id_spice2 as id_spice_max
    from Q_SPICES_TWO2 s
  -- order by 1,2,3 
  union
  select -- Смешивание ТРЕХ ингредиентов
         s.id_spice1
        ,s.id_spice2
        ,s3.id_spice as id_spice3
         -- Поля сортировки ингредиентов для исключения повторов
        ,case when s.id_spice1 < s.id_spice2 and s.id_spice1 < s3.id_spice 
              then s.id_spice1 
              else 
                case when s.id_spice2 < s.id_spice1 and s.id_spice2 < s3.id_spice 
                      then s.id_spice2 
                      else s3.id_spice  
                 end
         end as id_spice_min
        ,case when s.id_spice1 > s.id_spice2 and s.id_spice1 > s3.id_spice 
              then s.id_spice1 
              else 
                case when s.id_spice2 > s.id_spice1 and s.id_spice2 > s3.id_spice 
                      then s.id_spice2 
                      else s3.id_spice  
                 end
         end as id_spice_max 
    from SPICES s3
    join (--
          select -- Смешивание ДВУХ ингредиентов
                 s.id_spice1
                ,s.id_spice2
                ,null as id_spice3
            from Q_SPICES_TWO2 s
         ) s
      on (s.id_spice1) not in ((s3.id_spice)) -- Исключить пересечение дублей ингредиентов
     and (s.id_spice2) not in ((s3.id_spice)) -- Исключить пересечение дублей ингредиентов
-- order by 1 nulls first, 2 nulls first, 3 nulls first
) -- /Q_SPICES
,Q_POTIONS as (
  -- Список зелий
  -- Смешивание уникальных ДВУХ, ТРЕХ ингредиентов БЕЗ ПОВТОРОВ
  select distinct 
         --s.*,
         id_spice_min as id_spice1
        ,case when s.id_spice1 > nvl(s.id_spice_min, -100) and s.id_spice1 < s.id_spice_max 
              then s.id_spice1 
              else 
                case when s.id_spice2 > nvl(s.id_spice_min, -100) and s.id_spice2 < s.id_spice_max 
                      then s.id_spice2 
                      else s.id_spice3 
                 end
         end as id_spice2 -- id_spice_avg
        ,id_spice_max as id_spice3
    from Q_SPICES s
--   order by 1,2,3
) -- /Q_POTIONS
,Q_EFFS as (
  -- Пересечение ингредиентов с их эффектами
  select xs.*
        ,e1.id_effect as id_effect1
        ,e2.id_effect as id_effect2
        ,e3.id_effect as id_effect3
        ,case when e1.id_effect = e2.id_effect 
                or e1.id_effect = e3.id_effect 
              then e1.id_effect
              when e2.id_effect = e3.id_effect
              then e2.id_effect
              else 0 
         end as match_effect -- Совпадающий эффект
    from Q_POTIONS xs
    left join MM_SPICES_EFFECTS e1
      on e1.id_spice = xs.id_spice1
    left join MM_SPICES_EFFECTS e2
      on e2.id_spice = xs.id_spice2
    left join MM_SPICES_EFFECTS e3
      on e3.id_spice = xs.id_spice3
--   order by id_spice1 nulls first, id_spice2 nulls first, id_spice3 nulls first, id_effect1 nulls first, id_effect2 nulls first, id_effect3 nulls first
) -- /Q_EFFS
,Q_EFFS_CALC as (
  -- Ингредиенты с совпадающими эффектами
  select distinct ID_SPICE1, ID_SPICE2, ID_SPICE3, MATCH_EFFECT
    from Q_EFFS ef
   where match_effect > 0 -- Только с совпадениями
) -- /Q_EFFS_CALC
,Q_EFFS_CALC3 as (
  -- Ингредиенты и максимальный эффект
  select id_spice1, id_spice2, id_spice3
        ,count(*) as MATCHES_CNT
    from Q_EFFS_CALC ef
  group by ID_SPICE1, ID_SPICE2, ID_SPICE3
--  order by MATCHES_CNT desc, ID_SPICE1, ID_SPICE2, ID_SPICE3
) -- /Q_EFFS_CALC3
-- Cоставы зелий, имеющих 5 или более эффектов
select -- x.id_spice1, x.id_spice2, x.id_spice3,
      s.name_of_spice as spicenm1
      ,s2.name_of_spice as spicenm2
      ,s3.name_of_spice as spicenm3
      ,matches_cnt as EFFECTS_CNT -- Максимально возможное количество эффектов в зелье?
  from Q_EFFS_CALC3 x
  left join SPICES s
    on s.id_spice = x.id_spice1
  left join SPICES s2
    on s2.id_spice = x.id_spice2
  left join SPICES s3
    on s3.id_spice = x.id_spice3
 where x.matches_cnt >= 5 -- имеющих 5 или более эффектов
 order by ID_SPICE1, ID_SPICE2, ID_SPICE3, matches_cnt desc
;/**/ 



---------------------------------------------------------------

select t.*, t.rowid
  from SPICES t;

select t.*, t.rowid
  from EFFECTS_OF_POTIONS t;
  
select t.*, t.rowid
  from MM_SPICES_EFFECTS t
order by 1,2 
  ;
  
select t.*, t.rowid
  from V_MM_SPICES_EFFECTS t;

-------------------------------------------------------
-- Инициализация таблицы
/*
-- Создание таблицы
-- Drop table
drop table MM_SPICES_EFFECTS cascade constraints;
drop table SPICES cascade constraints;
drop table EFFECTS_OF_POTIONS cascade constraints;

--------------------------------------------------------------- 
-- Create table
-- Create table
create table SPICES
(
  id_spice      NUMBER not null,
  name_of_spice VARCHAR2(200) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table SPICES
  add constraint PK_SPICES primary key (ID_SPICE)
  using index;



--------------------------------------------------------------- 
-- Create table
create table EFFECTS_OF_POTIONS
(
  id_effect      NUMBER not null,
  name_of_effect VARCHAR2(200) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table EFFECTS_OF_POTIONS
  add constraint PK_EFFECTS_OF_POTIONS primary key (ID_EFFECT)
  using index;
;

--------------------------------------------------------------- 
-- Create table
create table MM_SPICES_EFFECTS
(
  id_spice  NUMBER not null,
  id_effect NUMBER not null
)
tablespace HOMEBUH_DATA
  pctfree 10
  initrans 1
  maxtrans 255;
-- Create/Recreate primary, unique and foreign key constraints 
alter table MM_SPICES_EFFECTS
  add constraint PK_MM_SPICES_EFFECTS primary key (ID_SPICE, ID_EFFECT);
alter table MM_SPICES_EFFECTS
  add constraint FK_MM_SPICES_EFFECTS_EF foreign key (ID_EFFECT)
  references EFFECTS_OF_POTIONS (ID_EFFECT);
alter table MM_SPICES_EFFECTS
  add constraint FK_MM_SPICES_EFFECTS_SP foreign key (ID_SPICE)
  references SPICES (ID_SPICE);



---------------------------------------------------------------

select t.*, t.rowid
  from SPICES t
  order by 1;
  
-- prompt Importing table SPICES...
set feedback off
set define off

insert into SPICES (ID_SPICE, NAME_OF_SPICE)
values (1, 'Жир тролля');

insert into SPICES (ID_SPICE, NAME_OF_SPICE)
values (2, 'Уши эльфа');

insert into SPICES (ID_SPICE, NAME_OF_SPICE)
values (3, 'Шерсть хоббита');

insert into SPICES (ID_SPICE, NAME_OF_SPICE)
values (4, 'Мясо хрюна');

insert into SPICES (ID_SPICE, NAME_OF_SPICE)
values (5, 'Огузок осла');

insert into SPICES (ID_SPICE, NAME_OF_SPICE)
values (6, 'Петух бобра');


--------------------------------------------------------------- 
select t.*, t.rowid
  from EFFECTS_OF_POTIONS t
  order by 1;

-- prompt Importing table EFFECTS_OF_POTIONS...
set feedback off
set define off

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (1, 'Восстановление здоровья');

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (2, 'Увеличение силы');

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (3, 'Урон огнём');

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (4, 'Быстрое харакири');

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (5, 'Обезглавливание мыслью');

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (6, 'Прыжок с переворотом');

insert into EFFECTS_OF_POTIONS (ID_EFFECT, NAME_OF_EFFECT)
values (7, 'Ярость покоя');

prompt Done.


--------------------------------------------------------------- 
select t.*, t.rowid
  from MM_SPICES_EFFECTS t
order by 1,2 
  ;
  


-- prompt Importing table MM_SPICES_EFFECTS...
set feedback off
set define off

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (1, 1);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (1, 3);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (1, 4);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (1, 5);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (2, 1);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (2, 3);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (2, 5);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (2, 6);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (3, 1);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (3, 2);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (3, 3);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (3, 5);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (4, 1);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (4, 3);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (5, 1);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (5, 2);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (5, 3);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (5, 6);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (6, 1);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (6, 2);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (6, 4);

insert into MM_SPICES_EFFECTS (ID_SPICE, ID_EFFECT)
values (6, 5);

prompt Done.

/**/
