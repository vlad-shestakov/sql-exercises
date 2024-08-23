-- _sql SqlLog.sql
---------------------------------------------------------------
-- Запросы для задачи

/ ---------------------------------------------------------------
-- Таблица каталог товаров (SKU)
/*
ID  N NUMBER  N     Первичный ключ
NAME  N VARCHAR2(200) N     Название товара.
/**/ 
select s.*
      ,s.rowid
  from SKU s
 where 1=1
 order by 1
;/**/ 
/* 
-- prompt Importing table SKU...
insert into SKU (ID, NAME)
  values (1, 'Карандаш твердый');
insert into SKU (ID, NAME)
  values (2, 'Ручка шариковая');
/**/

/ ---------------------------------------------------------------
-- Таблица содержащая заказы. (ORDERS)
/*
ID          N NUMBER  N     Первичный ключ
N_DOC       N NUMBER  Y     № заказа.
DATE_DOC    N DATE    Y     Дата заказа.
AMOUNT      N NUMBER  Y     Сумма заказа расчетное значение (сумма деталей заказа).
DISCOUNT    N NUMBER  Y     Скидка в процентах от 0 до 100.
/**/ 
select o.*
      ,o.rowid
  from ORDERS o
 where 1=1
 order by 1
;/**/ 
/* 
ORA-04091: table SHEST.ORDERS is mutating, trigger/function may not see it
ORA-06512: at "SHEST.TR_ORDERS_DETAIL_B_IUD", line 54
ORA-04088: error during execution of trigger 'SHEST.TR_ORDERS_DETAIL_B_IUD'
ORA-06512: at "SHEST.TR_ORDERS_B_IU", line 46
ORA-04088: error during execution of trigger 'SHEST.TR_ORDERS_B_IU'
/**/ 
/* 
-- prompt Importing table ORDERS...
insert into ORDERS (ID, N_DOC)
  values (1, 1);
insert into ORDERS (ID, N_DOC)
  values (2, 2);
/**/

/ ---------------------------------------------------------------
-- Таблица содержащая заказы. (ORDERS)
/*
ID  N NUMBER  N     Первичный ключ
ID_ORDER      N NUMBER  N     тдентификатор заказа
ID_SKU        N NUMBER  N     идентификатор товара
PRICE         N NUMBER  Y     Цена товара за единицу.
QTY           N NUMBER  Y     кол-во товара.
STR_SUM       N NUMBER  Y     Сумма по строке с учетом скидки.
IDX           N NUMBER  Y     Порядковый номер строки заказа (не должно быть пропусков).

Primary  ID  Y  
Foreign  ID_ORDER  Y  ORDERS
Foreign  ID_SKU    Y  SKU
/**/
select od.*
--       ,PKG_ORDERS_DETAIL.GET_SUM(pnID_ORDER => od.ID_ORDER,
--                                  pnQTY      => od.QTY,
--                                  pnPRICE    => od.PRICE) as calc_sum
      ,od.rowid
  from ORDERS_DETAIL od
 where 1=1
 order by od.id_order, od.idx
;/**/

/* 
-- prompt Importing table ORDERS_DETAIL...

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
  
  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (8, 1, 1, 15, 50);
/**/

/ ---------------------------------------------------------------
-- Лог ошибок и отладки (ERROR_LOG)
select *
  from ERROR_LOG el
 where 1=1
 order by 1 desc
;/**/ 

/
--------------------------------------------------------------- 
/*
begin
  -- Удаляем все логи
  PKG_LOG.DEL_LOGS;  
end;/**/
/

--
---------------------------------------------------------------
/* 
-- Add comments to the table 
comment on table ORDERS_DETAIL
  is 'Таблица содержащая товары в заказах.';
/**/

-- Create sequence 
create sequence SEQ_ERROR_LOG
  minvalue 1
  maxvalue 100500
  start with 1
  increment by 1;

select SEQ_ERROR_LOG.nextval from dual; 


CREATE TABLE error_log
(
  ID         NUMBER not null,--  default SEQ_ERROR_LOG.nextval,
  LOG_DATE   DATE   default sysdate not null ,
  PROC       VARCHAR2(255),
  ERR_MSG    VARCHAR2(4000),
  ERR_CODE   VARCHAR2(255),
  OBJ_ID     VARCHAR2(4000),
  OBJ_TYPE   VARCHAR2(255)
) nologging;


COMMENT ON TABLE error_log IS 'Логирование ошибок.';


-- Create/Recreate check constraints 
alter table ERROR_LOG
  add constraint CHK_ERROR_LOG_LEVEL
  check (ERR_LEVEL in ('ERROR','WARNING','DEBUG','TRACE'));


ALTER TABLE error_log ADD (
  CONSTRAINT pk_error_log
  PRIMARY KEY
  (id));
  
select *
  from ERROR_LOG el
 where 1=1
 order by 1 desc
;/**/ 

/
/
begin
  -- Установка уровня логирования
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'TRACE'); 
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'DEBUG');  
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => PKG_LOG.csERR_LEVEL); 
end; 
/

select PKG_LOG.GET_ERR_LEVEL,
       PKG_LOG.GET_ERR_LEVEL_NUM(123),
       PKG_LOG.GET_ERR_LEVEL_NUM(''),
       PKG_LOG.GET_ERR_LEVEL_NUM('DEBUG'),
       PKG_LOG.GET_ERR_LEVEL_NUM('ERROR')
from dual; 


---------------------------------------------------------------
/
-- Cкрипт тестирования LOG_ERR()
/*
declare
  nRES   number;
  nFOO   number := 0;
begin
  PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(nFOO) || ' - ' || to_char(nRES), 1, 4000),
                psOBJ_TYPE => 'nFOO - nRES',
                psPROC     => 'TEST_LOG_ERR');
  nRES := 1 / nFOO;
exception
  when others then
    PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                  psOBJ_ID   => substr(to_char(nFOO) || ' - ' || to_char(nRES), 1, 4000),
                  psOBJ_TYPE => 'nFOO - nRES',
                  psPROC     => 'TEST_LOG_ERR');
end; 
/**/
