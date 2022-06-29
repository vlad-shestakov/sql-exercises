-- SqlLog SQL-задач LIFE 2022-06-28 v01
---------------------------------------------------------------
----  Задание на разработчика БД - Реализовать задачу Жизнь
---------------------------------------------------------------


/* 
Задания связаны с реализацией на SQL игры «Жизнь» Конвея.

Подробное описание игры «Жизнь» рекомендуем изучить по адресу https://ru.m.wikipedia.org/wiki/Игра_«Жизнь» или на других ресурсах.

Дана таблица Life, содержащая сведения о конфигурациях игры «Жизнь» Конвея на бесконечной плоскости, со структурой: 
1)  x – номер столбца (координата клетки по горизонтали);
2)  y – номер строки (координата клетки по вертикали);
3)	Gen – номер поколения.
Тип всех полей – целые числа.
Если в клетке с координатами x и y в поколении с номером gen существует жизнь, то в таблице Life существует запись {x, y, gen}. Клетки, в которых жизни нет, в таблице не отражены.


---------------------------------------------------------------
№1.1 - ОБЯЗАТЕЛЬНОЕ

Написать команду INSERT (1 штука :), которая выполнит следующее:
1)	Определит максимальный номер поколения жизни в таблице Life;
2)	Вставит в таблицу Life записи, описывающие следующее за найденным на 1 шаге поколением жизни.
Использовать хранимые процедуры нельзя.
Для проверки правильности реализации INSERT можно 41 раз применить разработанную Вами команду INSERT к таблице, содержащей следующую начальную конфигурацию (глайдер):

Результат команды Select SUM (x*y) from Life     при правильной реализации искомого INSERT должен быть равен -6949

УСЛОВИЯ РАСПРОСТРАНЕНИЯ КЛЕТОК НА КАРТЕ:

Распределение живых клеток в начале игры называется первым поколением. Каждое следующее поколение рассчитывается на основе предыдущего по таким правилам:
  * в пустой (мёртвой) клетке, с которой соседствуют три живые клетки, зарождается жизнь;
  + если у живой клетки есть две или три живые соседки, то эта клетка продолжает жить; в противном случае (если живых соседей меньше двух или больше трёх) клетка умирает («от одиночества» или «от перенаселённости»).
Игра прекращается, если
  * на поле не останется ни одной «живой» клетки;
  * конфигурация на очередном шаге в точности (без сдвигов и поворотов) повторит себя же на одном из более ранних шагов (складывается периодическая конфигурация)
  * при очередном шаге ни одна из клеток не меняет своего состояния (предыдущее правило действует на один шаг назад, складывается стабильная конфигурация)
/**/

---------------------------------------------------------------
-- РЕШЕНИЕ ЗАДАЧИ 
-- Используется ряд подзапросов для наглядности
-- Первый подзапрос (Q_LIFE_START) может использоваться для подстановки данных тестирования
-- Применимость БД: Oracle v11

/
---------------------------------------------------------------
-- Добавить поколение LIFE
insert into LIFE 
with
Q_LIFE_START as ( 
-- Первоначальное состояние карты клеток Игры "LIFE"
-- Координаты включенных клеток (X, Y), Поколение карты (GEN)

-- Все поколения из таблицы
select  p.* from LIFE p 

/*
-- ИЛИ ОТЛАДКА - Данные из DUAL
  select -1 as x  ,0 as y  , 1 as gen   from dual union all 
  select  0 as x  ,0 as y  , 1 as gen   from dual union all 
  select  1 as x  ,0 as y  , 1 as gen   from dual union all 
  select  1 as x  ,1 as y  , 1 as gen   from dual union all 
  select  0 as x  ,2 as y  , 1 as gen   from dual

/*  
 union all 
-- плюс еще поколение для теста
  select -1 as x  ,0 as y  , 2 as gen   from dual union all 
  select  0 as x  ,0 as y  , 2 as gen   from dual union all 
  select  1 as x  ,0 as y  , 2 as gen   from dual union all 
  select  1 as x  ,1 as y  , 2 as gen   from dual union all  
  select  0 as x  ,2 as y  , 2 as gen   from dual 
/**/
       
) -- Q_LIFE_START
,Q_LIFE_START2 as ( 
-- Возьмем только последнее поколение из выборки Q_LIFE_START
select p.* 
  from DUAL
 cross join Q_LIFE_START p
 where p.gen in (select max(c.gen) from Q_LIFE_START c)
) -- Q_LIFE_START2
,Q_LIFE_START3 as ( 
-- Добавляем соседние незаполненные поля - 1 этап
-- Добавляем несколько матриц соседних пустых ячеек со сдвигом по всем восьми сторонам
-- Изначальные данные в статусе Заполнено (ST_EX = 1)
select p.x, p.y, p.gen, 1 as st_ex from DUAL cross join Q_LIFE_START2 p
-- Добавляем туже матрицу ячеек по всем восьми сторонам в статусе - Незаполнено (ST_EX = 0)
union select p.x - 1 as x, p.y     as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева
union select p.x + 1 as x, p.y     as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа
union select p.x     as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Снизу
union select p.x     as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Сверху
union select p.x - 1 as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева снизу
union select p.x + 1 as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа снизу
union select p.x - 1 as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева Сверху
union select p.x + 1 as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа Сверху
--order by gen, y, x, st_ex desc --< для отладки 
) -- Q_LIFE_START3
,Q_LIFE_START4 as ( 
-- Добавляем соседние незаполненные поля - 2 этап
-- Удалим дублирующиеся адреса 
select p.x, p.y, p.gen
      ,max(st_ex) as st_ex -- В приоритете заполненные ячейки
  from DUAL
 cross join Q_LIFE_START3 p
 group by p.x, p.y, p.gen
--order by gen, y, x --< для отладки 
) -- Q_LIFE_START4
,Q_LIFE_CALC as (
-- Посчитаем клетки вокруг живущих (NEARS)
select p.*
      ,(-- Сколько вокруг текущей живых клеток (NEARS)
          coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x - 1 and c.y = p.y), 0) -- Слева
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x + 1 and c.y = p.y), 0) -- Справа
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x and c.y = p.y - 1), 0) -- Снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x and c.y = p.y + 1), 0) -- Сверху
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x - 1 and c.y = p.y - 1), 0) -- Слева снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x + 1 and c.y = p.y - 1), 0) -- Справа снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x - 1 and c.y = p.y + 1), 0) -- Слева сверху
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x + 1 and c.y = p.y + 1), 0) -- Справа сверху
       ) as nears
  from DUAL
 cross join Q_LIFE_START4 p
 where 1 = 1
--order by gen, y, x, st_ex desc --< для отладки 
) -- Q_LIFE_CALC
,Q_LIFE_CALC2 as (
-- Фильтр для клеток, кто остается жить - (STAND) - 0,1
select p.*
      ,1 as stand
  from DUAL
 cross join Q_LIFE_CALC p
 where 1 = 1
       -- Для живых клеток условие выживание 2-3 клетки
       -- Для пустых условие выживание 3 клетки
   and ((p.st_ex = 1 and p.nears = 2) 
    or (p.nears = 3))
-- order by p.gen, p.y, p.x, p.nears --< для отладки 
) -- Q_LIFE_CALC2
-- Выборка клеток на вставку
select p.x, p.y
      ,p.gen + 1 as gen -- Код нового поколения
      --,(case when gen = trunc(gen) and gen > 0 then 1 else 0 end) as chk_gen
     -- ,p.*
  from DUAL
 cross join Q_LIFE_CALC2 p
 where 1 = 1
-- order by p.y, p.x, p.gen, p.nears, p.stand --< для отладки 
;     


---------------------------------------------------------------
-- Просмотр таблицы LIFE
select p.*
      ,sum(p.x * p.y) over () as check_sum 
      --,(case when gen = trunc(gen) and gen > 0 then 1 else 0 end) as chk_gen
      ,p.rowid
  from LIFE p
 where 1 = 1
 order by gen desc, y, x
;/**/

---------------------------------------------------------------
-- Инициализация таблицы
/*
-- Drop table
drop table LIFE cascade constraints;

-- Создание таблицы
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


-- Вставка данных 
    insert into LIFE (X, Y, GEN)
    values (-1, 0, 1);

    insert into LIFE (X, Y, GEN)
    values (0, 0, 1);

    insert into LIFE (X, Y, GEN)
    values (1, 0, 1);

    insert into LIFE (X, Y, GEN)
    values (1, 1, 1);

    insert into LIFE (X, Y, GEN)
    values (0, 2, 1);

*/

/

---------------------------------------------------------------

-- Редактирование таблицы LIFE
select t.*, t.rowid
  from LIFE  t
 where 1 = 1
 order by 3 desc,2,1
;/**/




---------------------------------------------------------------
-- Проверка результата
select sum(p.x * p.y) as check_sum 
     -- ,p.*
  from LIFE p
;

---------------------------------------------------------------
/
-- Скрипт тестирования игры LIFE
declare
  v_cnt         number;
  v_i           number;
  v_check_sum   number;
begin
  v_cnt := 41;
  
  -- Чистим таблицу
  delete from LIFE;
  --truncate table LIFE;
  
  -- Инициализационные данные 
  insert into LIFE (X, Y, GEN)
  values (-1, 0, 1);

  insert into LIFE (X, Y, GEN)
  values (0, 0, 1);

  insert into LIFE (X, Y, GEN)
  values (1, 0, 1);

  insert into LIFE (X, Y, GEN)
  values (1, 1, 1);

  insert into LIFE (X, Y, GEN)
  values (0, 2, 1);
  
  
  v_i := 1;
  dbms_output.put_line('v_i = ' || v_i); --< Для отладки  
        
          
  -- Проверка результата
  select sum(p.x * p.y) as check_sum 
    into v_check_sum
    from LIFE p;
  /* 
  -- Old
  select distinct  sum(p.x * p.y) over (partition by gen order by gen) as check_sum 
    into v_check_sum
    from LIFE p
   where 1 = 1
     and p.gen = (select max(c.gen) from LIFE c);
  /**/
     
  dbms_output.put_line('v_check_sum = ' || v_check_sum); --< Для отладки  
        
   -- Перебираем
   while (v_i <= v_cnt )
   loop


-- Добавить поколение LIFE
insert into LIFE 
with
Q_LIFE_START as ( 
-- Первоначальное состояние карты клеток Игры "LIFE"
-- Координаты включенных клеток (X, Y), Поколение карты (GEN)

-- Все поколения из таблицы
select  p.* from LIFE p 

/*
-- ИЛИ ОТЛАДКА - Данные из DUAL
  select -1 as x  ,0 as y  , 1 as gen   from dual union all 
  select  0 as x  ,0 as y  , 1 as gen   from dual union all 
  select  1 as x  ,0 as y  , 1 as gen   from dual union all 
  select  1 as x  ,1 as y  , 1 as gen   from dual union all 
  select  0 as x  ,2 as y  , 1 as gen   from dual

/*  
 union all 
-- плюс еще поколение для теста
  select -1 as x  ,0 as y  , 2 as gen   from dual union all 
  select  0 as x  ,0 as y  , 2 as gen   from dual union all 
  select  1 as x  ,0 as y  , 2 as gen   from dual union all 
  select  1 as x  ,1 as y  , 2 as gen   from dual union all  
  select  0 as x  ,2 as y  , 2 as gen   from dual 
/**/
       
) -- Q_LIFE_START
,Q_LIFE_START2 as ( 
-- Возьмем только последнее поколение из выборки Q_LIFE_START
select p.* 
  from DUAL
 cross join Q_LIFE_START p
 where p.gen in (select max(c.gen) from Q_LIFE_START c)
) -- Q_LIFE_START2
,Q_LIFE_START3 as ( 
-- Добавляем соседние незаполненные поля - 1 этап
-- Добавляем несколько матриц соседних пустых ячеек со сдвигом по всем восьми сторонам
-- Изначальные данные в статусе Заполнено (ST_EX = 1)
select p.x, p.y, p.gen, 1 as st_ex from DUAL cross join Q_LIFE_START2 p
-- Добавляем туже матрицу ячеек по всем восьми сторонам в статусе - Незаполнено (ST_EX = 0)
union select p.x - 1 as x, p.y     as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева
union select p.x + 1 as x, p.y     as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа
union select p.x     as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Снизу
union select p.x     as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Сверху
union select p.x - 1 as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева снизу
union select p.x + 1 as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа снизу
union select p.x - 1 as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева Сверху
union select p.x + 1 as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа Сверху
--order by gen, y, x, st_ex desc --< для отладки 
) -- Q_LIFE_START3
,Q_LIFE_START4 as ( 
-- Добавляем соседние незаполненные поля - 2 этап
-- Удалим дублирующиеся адреса 
select p.x, p.y, p.gen
      ,max(st_ex) as st_ex -- В приоритете заполненные ячейки
  from DUAL
 cross join Q_LIFE_START3 p
 group by p.x, p.y, p.gen
--order by gen, y, x --< для отладки 
) -- Q_LIFE_START4
,Q_LIFE_CALC as (
-- Посчитаем клетки вокруг живущих (NEARS)
select p.*
      ,(-- Сколько вокруг текущей живых клеток (NEARS)
          coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x - 1 and c.y = p.y), 0) -- Слева
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x + 1 and c.y = p.y), 0) -- Справа
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x and c.y = p.y - 1), 0) -- Снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x and c.y = p.y + 1), 0) -- Сверху
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x - 1 and c.y = p.y - 1), 0) -- Слева снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x + 1 and c.y = p.y - 1), 0) -- Справа снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x - 1 and c.y = p.y + 1), 0) -- Слева сверху
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen and c.st_ex = 1 and c.x = p.x + 1 and c.y = p.y + 1), 0) -- Справа сверху
       ) as nears
  from DUAL
 cross join Q_LIFE_START4 p
 where 1 = 1
--order by gen, y, x, st_ex desc --< для отладки 
) -- Q_LIFE_CALC
,Q_LIFE_CALC2 as (
-- Фильтр для клеток, кто остается жить - (STAND) - 0,1
select p.*
      ,1 as stand
  from DUAL
 cross join Q_LIFE_CALC p
 where 1 = 1
       -- Для живых клеток условие выживание 2-3 клетки
       -- Для пустых условие выживание 3 клетки
   and ((p.st_ex = 1 and p.nears = 2) 
    or (p.nears = 3))
-- order by p.gen, p.y, p.x, p.nears --< для отладки 
) -- Q_LIFE_CALC2
-- Выборка клеток на вставку
select p.x, p.y
      ,p.gen + 1 as gen_new -- Код нового поколения
     -- ,p.*
  from DUAL
 cross join Q_LIFE_CALC2 p
 where 1 = 1
-- order by p.y, p.x, p.gen, p.nears, p.stand --< для отладки 
;     
   
      dbms_output.put_line('v_i = ' || v_i); --< Для отладки  
      
        
      -- Проверка результата
      select sum(p.x * p.y) as check_sum 
        into v_check_sum
        from LIFE p;
      /* 
      
      select distinct  sum(p.x * p.y) over (partition by gen order by gen) as check_sum 
        into v_check_sum
        from LIFE p
       where 1 = 1
         and p.gen = (select max(c.gen) from LIFE c);
      /**/
         
      dbms_output.put_line('v_check_sum = ' || v_check_sum); --< Для отладки  
       
      v_i := v_i + 1;
   end loop;

  -- dbms_output.put_line('v_cnt = ' || v_cnt); --< Для отладки  
end; 
/




---------------------------------------------------------------
-- ДРУГИЕ ЭКСПЕРИМЕНТЫ
 

with
Q_LIFE_START as ( 
-- Первоначальное состояние карты клеток Игры "LIFE"
-- Координаты включенных клеток (X, Y), Поколение карты (GEN)

-- Все поколения из таблицы
--select  p.* from LIFE p 

-- ОТЛАДКА - Данные из DUAL
  select -1 as x  ,0 as y  , 1 as gen   from dual union all 
  select  0 as x  ,0 as y  , 1 as gen   from dual union all 
  select  1 as x  ,0 as y  , 1 as gen   from dual union all 
  select  1 as x  ,1 as y  , 1 as gen   from dual union all 
  select  0 as x  ,2 as y  , 1 as gen   from dual 
/*  
  union all 
-- плюс еще поколение для теста
  select -1 as x  ,0 as y  , 2 as gen   from dual union all 
  select  0 as x  ,0 as y  , 2 as gen   from dual union all 
  select  1 as x  ,0 as y  , 2 as gen   from dual union all 
  select  1 as x  ,1 as y  , 2 as gen   from dual union all  
  select  0 as x  ,2 as y  , 2 as gen   from dual 
/**/
 
) -- Q_LIFE_START
,Q_LIFE_START2 as ( 
-- Возьмем последнее поколение из выборки Q_LIFE_START
select p.* 
  from DUAL
 cross join Q_LIFE_START p
 where p.gen in (select max(c.gen) from Q_LIFE_START c)
) -- Q_LIFE_START2
,Q_LIFE_START3 as ( 
-- Добавляем к выборке матрицу соседних пустых ячеек
-- Изначальные данные 
select p.x, p.y, p.gen, 1 as st_ex
  from DUAL
 cross join Q_LIFE_START2 p
-- Добавляем туже матрицу ячеек по всем восьми сторонам в статусе - Незаполнено
union select p.x - 1 as x, p.y     as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева
union select p.x + 1 as x, p.y     as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа
union select p.x     as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Снизу
union select p.x     as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Сверху
union select p.x - 1 as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева снизу
union select p.x + 1 as x, p.y - 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа снизу
union select p.x - 1 as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Слева Сверху
union select p.x + 1 as x, p.y + 1 as y, p.gen, 0 as st_ex from Q_LIFE_START2 p  -- Справа Сверху
--order by gen, y, x, st_ex desc
) -- Q_LIFE_START3
--,Q_LIFE_START4 as ( 
-- Фильтруем матрицу соседних пустых ячеек
select p.x, p.y, p.gen
      ,max(st_ex) as st_ex
  from DUAL
 cross join Q_LIFE_START3 p
 group by p.x, p.y, p.gen
--order by gen, y, x
) -- Q_LIFE_START4
,Q_LIFE_CALC1 as (
-- Посчитаем клетки вокруг живущих
select p.*
       /* 
       -- Старое решение
      ,(-- Сколько вокруг текущей живых клеток (NEARS)
          coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x - 1 and c.y = p.y), 0) -- Слева
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x + 1 and c.y = p.y), 0) -- Справа
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x and c.y = p.y - 1), 0) -- Снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x and c.y = p.y + 1), 0) -- Сверху
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x - 1 and c.y = p.y - 1), 0) -- Слева снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x + 1 and c.y = p.y - 1), 0) -- Справа снизу
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x - 1 and c.y = p.y + 1), 0) -- Слева сверху
        + coalesce((select sum(1) from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x + 1 and c.y = p.y + 1), 0) -- Справа сверху
       ) as nears
       /**/
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x - 1 and c.y = p.y) then 1 else 0 end as st_l -- Статус слева 
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x + 1 and c.y = p.y) then 1 else 0 end as st_r -- Справа
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x and c.y = p.y - 1) then 1 else 0 end as st_d -- Снизу
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x and c.y = p.y + 1) then 1 else 0 end as st_u -- Сверху
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x - 1 and c.y = p.y - 1) then 1 else 0 end as st_ld -- Слева снизу
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x + 1 and c.y = p.y - 1) then 1 else 0 end as st_rd -- Справа снизу
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x - 1 and c.y = p.y + 1) then 1 else 0 end as st_lu -- Слева сверху
      ,case when exists (select 1 from Q_LIFE_START4 c where c.gen = p.gen  and c.x = p.x + 1 and c.y = p.y + 1) then 1 else 0 end as st_ru -- Справа сверху
  from DUAL
 cross join Q_LIFE_START4 p
 where 1 = 1
-- order by p.gen, p.y, p.x
) -- Q_LIFE_CALC1
,Q_LIFE_CALC2 as (
-- Посчитаем клетки вокруг живущих
select p.*
       -- Сколько вокруг текущей живых клеток (NEARS)
      ,p.st_l + p.st_r + p.st_d + p.st_u + p.st_ld + p.st_rd + p.st_lu + p.st_ru as NEARS
  from DUAL
 cross join Q_LIFE_CALC1 p
 where 1 = 1
-- order by p.gen, p.y, p.x
) -- Q_LIFE_CALC2
-- Увеличить таблицу пустыми клетками вокруг заполенных 
-- (В зависимости от пустых клеток наростить количество строк в таблице с новыми координатами)
select t.*
      --,(case when t.st_l = 0 then 2 else 1 end) as nears3
      --,t.skey
      --,to_char(t.field_values) as field_values
      ,column_value as col_num -- Номер добавляемой клетки
      ,case when column_value > 1 then 'new' else 'old' end as new_
      ,s.*
   from Q_LIFE_CALC2 t
      ,table(cast(multiset (-- Сгенерируем столько строк, сколько было спецсимволов в исслед. строке
                            select level
                               from dual
                             connect by level <= (8 - t.nears + 1) -- Сколько новых строк надо добавить, в зависимости от количества пустых клеток + 1 для старой
                            ) as sys.odcinumberlist
                 )
             ) s;
