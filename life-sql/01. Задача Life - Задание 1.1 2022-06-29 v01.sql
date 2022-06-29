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
insert into LIFE (gen, x, y)
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
       
) -- /Q_LIFE_START
,Q_LIFE_START2 as ( 
-- Возьмем только последнее поколение из выборки Q_LIFE_START
select p.* 
  from DUAL
 cross join Q_LIFE_START p
 where p.gen in (select max(c.gen) from Q_LIFE_START c)
) -- /Q_LIFE_START2
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
) -- /Q_LIFE_START3
,Q_LIFE_START4 as ( 
-- Добавляем соседние незаполненные поля - 2 этап
-- Удалим дублирующиеся адреса 
select p.x, p.y, p.gen
      ,max(st_ex) as st_ex -- В приоритете заполненные ячейки
  from DUAL
 cross join Q_LIFE_START3 p
 group by p.x, p.y, p.gen
--order by gen, y, x --< для отладки 
) -- /Q_LIFE_START4
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
) -- /Q_LIFE_CALC
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
) -- /Q_LIFE_CALC2
-- Выборка клеток на вставку
select p.gen + 1 as gen -- Код нового поколения
      ,p.x, p.y
      --,p.*
  from DUAL
 cross join Q_LIFE_CALC2 p
 where 1 = 1
--order by p.gen desc, p.y, p.x, p.nears, p.stand --< для отладки 
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
