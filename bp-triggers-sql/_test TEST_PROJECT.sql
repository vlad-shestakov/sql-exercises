-- _test TEST_PROJECT.sql

---------------------------------------------------------------
----               Тестовый сецнарий 
---------------------------------------------------------------


--------------------------------------------------------------- 
-- Тест кейс - ИНИЦИАЛИЗАЦИЯ
begin
  -- Чистим таблицы
  delete from ORDERS_DETAIL;
  delete from ORDERS;
  delete from SKU;
  
  -- Удаляем все логи
  PKG_LOG.DEL_LOGS;  
  commit;
  
  -- По-умолчанию пакет PKG_LOG логирует сообщения уровня - ERROR
  -- Проверка уровня логирования
  dbms_output.put_line('PKG_LOG.csERR_LEVEL - ' || PKG_LOG.csERR_LEVEL);
  -- Переопределим логирование вплоть до уровня TRACE, это типы сообщений ERROR -> WARNING -> DEBUG -> TRACE
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'TRACE'); -- Лог с отладкой
--   PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'ERROR'); -- Только ошибки в логе
  -- Проверка уровня логирования
  dbms_output.put_line('new PKG_LOG.GET_ERR_LEVEL - ' || PKG_LOG.GET_ERR_LEVEL); -- TRACE
  
  -- Добавляем товары...
  insert into SKU (ID, NAME)
    values (1, 'Карандаш твердый');
  insert into SKU (ID, NAME)
    values (2, 'Ручка шариковая');
    
  -- Добавляем заказы...
  insert into ORDERS (ID, N_DOC)
    values (1, 1);
  insert into ORDERS (ID, N_DOC)
    values (2, 2);
    
  -- Добавляем первичные товары в заказы...
  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (1, 1, 1, 10, 100);

  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (2, 1, 2, 20, 50);

  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (3, 2, 1, 10, 100);
  
  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (4, 2, 2, 20, 50);
  
  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (5, 2, 2, 20, 50);
  commit;
end; 
/
-- Вставлены 2 товара, 2 заказа и товары в них
-- Проверяем

/ ---------------------------------------------------------------       
-- Таблица товаров. (SKU)
select s.*
      ,s.rowid
  from SKU s
 where 1=1
 order by 1
;/**/ 

/ ---------------------------------------------------------------       
-- Таблица содержащая заказы. (ORDERS)
select o.*
      ,o.rowid
  from ORDERS o
 where 1=1
 order by 1
;/**/ 
-- Выставились AMOUNT, DATE_DOC
/* 
ID  N_DOC DATE_DOC  AMOUNT  DISCOUNT
---------------------------------------------------------------                  
1   1     13.12.2022  30  0
2   2     13.12.2022  50  0
/**/

/ ---------------------------------------------------------------       
-- Таблица товаров в заказах (ORDERS_DETAIL)
select od.*
      ,od.rowid
  from ORDERS_DETAIL od
 where 1=1
 order by od.id_order, od.idx
;/**/
-- Выставились цены STR_SUM и индексы IDX

/ ---------------------------------------------------------------
-- Лог ошибок и отладки (ERROR_LOG)
select *
  from ERROR_LOG el
 where 1=1
 order by 1 desc
;/**/ 
-- Содержит отладку всех процедур с их параметрами
-- Если будут ошибки выполнения, они будут записаны с err_level in ('ERROR')
/* 
ID  ERR_LEVEL LOG_DATE  PROC  ERR_MSG ERR_CODE  OBJ_ID  OBJ_TYPE
---------------------------------------------------------------              
1311  DEBUG 13.12.2022 22:17:57 TR_ORDERS_DETAIL_BA_IU_IDX      AFTER INS: 2 cnt=3  AFTER EACH sOP: nID_ORDER cnt=nCNT
1310  DEBUG 13.12.2022 22:17:57 TR_ORDERS_DETAIL_B_IUD      UPD: 5 prc-50 q-20 sm- qd-0 ix-3  sOP: new.ID - :new.PRICE - :new.QTY - nSTR_SUM - nQTY_DIFF
1309  DEBUG 13.12.2022 22:17:57 TR_ORDERS_DETAIL_B_IUD      UPD: 4 prc-50 q-20 sm- qd-0 ix-2  sOP: new.ID - :new.PRICE - :new.QTY - nSTR_SUM - nQTY_DIFF
1308  DEBUG 13.12.2022 22:17:57 TR_ORDERS_DETAIL_B_IUD      UPD: 3 prc-100 q-10 sm- qd-0 ix-1 sOP: new.ID - :new.PRICE - :new.QTY - nSTR_SUM - nQTY_DIFF
1307  DEBUG 13.12.2022 22:17:57 TR_ORDERS_DETAIL_B_IUD      INS: 5 prc-50 q-20 sm-1000 qd-20 ix-  sOP: new.ID - :new.PRICE - :new.QTY - nSTR_SUM - nQTY_DIFF
1306  DEBUG 13.12.2022 22:17:57 PKG_ORDERS_DETAIL.GET_SUM     2 - 50 * 20 * 0 * () = 1000 pnID_ORDER - pnPRICE * pnQTY * nDISCOUNT(pnDISCOUNT) = nRES
/**/ 

/ --------------------------------------------------------------- 
-- Добавим еще заказ
begin
  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (6, 1, 1, 15, 50);
end; 
/

-- Индексы в товарах пересчитались IDX
-- проверить ORDERS_DETAIL
-- Количество товаров пересчиталось AMOUNT
-- проверить ORDERS

/ --------------------------------------------------------------- 
-- Удалим товар из начала списка еще заказ
begin
  delete from ORDERS_DETAIL od
    where od.id = 1;
end; 
/
-- Индексы в товарах пересчитались IDX
-- проверить ORDERS_DETAIL
-- Количество товаров пересчиталось AMOUNT
-- проверить ORDERS

/ --------------------------------------------------------------- 
-- Обновим количество товара
begin
  update ORDERS_DETAIL od
     set od.qty = 10 -- 20 -> 10
    where od.id = 2;
end; 
/
-- Обновилась цена STR_SUM -- 1000 -> 500
-- проверить ORDERS_DETAIL

/ --------------------------------------------------------------- 
-- Установим неправильную скидку на 1 заказ
begin
  update ORDERS od
     set od.discount = -1 -- 1-100
    where od.id = 1;
exception
  when others then
    dbms_output.put_line(sqlcode || ' ' || sqlerrm); --< Для отладки 
end; 
/
-- ПОЯВИЛАСЬ ОШИБКА в консоли 
-- -20002 ORA-20002: Значение скидки должно быть в интервале 0 - 100
-- ORA-06512: at "SHEST2.TR_ORDERS_B_IU", line 48
-- ORA-04088: error during execution of trigger 'SHEST2.TR_ORDERS_B_IU'



/ --------------------------------------------------------------- 
-- Установим скидку 50% на 1 заказ
begin
  update ORDERS od
     set od.discount = 50
    where od.id = 1;
end; 
/
-- Обновилась цены STR_SUM в товарах заказа 1
-- проверить ORDERS_DETAIL

/ --------------------------------------------------------------- 
-- В конце тестов
/
commit;


/ --------------------------------------------------------------- 
-- Можно повторно прогнать инициализацию теста
-- заменив в скрипте режим логирования на фиксацию только ошибок
--   PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'ERROR'); -- Только ошибки в логе
