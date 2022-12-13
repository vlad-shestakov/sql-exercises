prompt PL/SQL Developer Export User Objects for user SHEST2@XE
prompt Created by v.shestakov on 13 Декабрь 2022 г.
set define off
spool _test CREATE_ALL_OBJECTS.log

prompt
prompt Creating table ERROR_LOG
prompt ========================
prompt
create table ERROR_LOG
(
  id        NUMBER not null,
  err_level VARCHAR2(10) default 'ERROR' not null,
  log_date  DATE default sysdate not null,
  proc      VARCHAR2(255),
  err_msg   VARCHAR2(4000),
  err_code  VARCHAR2(255),
  obj_id    VARCHAR2(4000),
  obj_type  VARCHAR2(255)
)
nologging;
comment on table ERROR_LOG
  is 'Логирование ошибок.';
alter table ERROR_LOG
  add constraint PK_ERROR_LOG primary key (ID);
alter table ERROR_LOG
  add constraint CHK_ERROR_LOG_LEVEL
  check (ERR_LEVEL in ('ERROR','WARNING','DEBUG','TRACE'));

prompt
prompt Creating table ORDERS
prompt =====================
prompt
create table ORDERS
(
  id       NUMBER not null,
  n_doc    NUMBER,
  date_doc DATE,
  amount   NUMBER,
  discount NUMBER
)
;
comment on table ORDERS
  is 'Таблица содержащая заказы.';
comment on column ORDERS.id
  is 'Первичный ключ';
comment on column ORDERS.n_doc
  is '№ заказа.';
comment on column ORDERS.date_doc
  is 'Дата заказа.';
comment on column ORDERS.amount
  is 'Сумма заказа расчетное значение (сумма деталей заказа).';
comment on column ORDERS.discount
  is 'Скидка в процентах от 0 до 100.';
alter table ORDERS
  add constraint PK_ORDERS primary key (ID);

prompt
prompt Creating table SKU
prompt ==================
prompt
create table SKU
(
  id   NUMBER not null,
  name VARCHAR2(200) not null
)
;
comment on table SKU
  is 'Таблица каталог товаров.';
comment on column SKU.id
  is 'Первичный ключ';
comment on column SKU.name
  is 'Название товара.';
alter table SKU
  add constraint PK_SKU primary key (ID);

prompt
prompt Creating table ORDERS_DETAIL
prompt ============================
prompt
create table ORDERS_DETAIL
(
  id       NUMBER not null,
  id_order NUMBER not null,
  id_sku   NUMBER not null,
  price    NUMBER,
  qty      NUMBER,
  str_sum  NUMBER,
  idx      NUMBER
)
;
comment on table ORDERS_DETAIL
  is 'Таблица содержащая товары в заказах.';
comment on column ORDERS_DETAIL.id
  is 'Первичный ключ';
comment on column ORDERS_DETAIL.id_order
  is 'тдентификатор заказа';
comment on column ORDERS_DETAIL.id_sku
  is 'идентификатор товара';
comment on column ORDERS_DETAIL.price
  is 'Цена товара за единицу.';
comment on column ORDERS_DETAIL.qty
  is 'кол-во товара.';
comment on column ORDERS_DETAIL.str_sum
  is 'Сумма по строке с учетом скидки.';
comment on column ORDERS_DETAIL.idx
  is 'Порядковый номер строки заказа (не должно быть пропусков).';
alter table ORDERS_DETAIL
  add constraint PK_ORDERS_DETAIL primary key (ID);
alter table ORDERS_DETAIL
  add constraint FK_ORDERS_DETAIL_ORDER foreign key (ID_ORDER)
  references ORDERS (ID);
alter table ORDERS_DETAIL
  add constraint FK_ORDERS_DETAIL_SKU foreign key (ID_SKU)
  references SKU (ID);

prompt
prompt Creating sequence SEQ_ERROR_LOG
prompt ===============================
prompt
create sequence SEQ_ERROR_LOG
minvalue 1
maxvalue 100500
start with 1841
increment by 1
cache 20;

prompt
prompt Creating package PKG_LOG
prompt ========================
prompt
create or replace package PKG_LOG is

  -- Author  : V.SHESTAKOV
  -- Created : 12.12.2022 22:59:54
  -- Purpose : Работа с таблицей логов ERROR_LOG

  -- Уровень логирования ошибок БД по-умолчанию - ERROR / WARNING / DEBUG / TRACE
  csERR_LEVEL constant varchar2(255) := 'ERROR';

---------------------------------------------------------------
/*
  -- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ:

  -- Сменить уровень логирования в БД для сессии
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'TRACE');
  -- или
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => PKG_LOG.csERR_LEVEL);


  -- Пример логирования отладки
  PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                psPROC     => 'PKG_ORDERS.UPD_AMOUNT');

  -- Пример логирования ошибок
  PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                psPROC     => 'PKG_ORDERS.UPD_AMOUNT');


  -- Удаление логов
  PKG_LOG.DEL_LOGS;
  commit;

/**/

---------------------------------------------------------------
-- Возвращает уровень логирования числом
function GET_ERR_LEVEL_NUM(
  psERR_LEVEL  varchar2
) return number;

------------------------------------------------------
-- Возвращает текущий уровень логирования
function GET_ERR_LEVEL
return varchar2;

------------------------------------------------------
-- Устанавливает текущий уровень логирования
procedure SET_ERR_LEVEL(
  psERR_LEVEL  varchar2
);

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме ошибки (ERROR)
procedure ERROR(
  psERR_MSG    varchar2,
  psERR_CODE   varchar2,
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме предупреждения (WARNING)
procedure WARNING(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме отладки (DEBUG)
procedure DEBUG(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме трассировки (TRACE)
procedure TRACE(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

------------------------------------------------------
-- Удаляет логи
procedure DEL_LOGS;

end PKG_LOG;
/

prompt
prompt Creating package PKG_ORDERS
prompt ===========================
prompt
create or replace package PKG_ORDERS is

  -- Author  : V.SHESTAKOV
  -- Created : 12.12.2022
  -- Purpose : Бизнес-логика работы с заказами

  ---------------------------------------------------------------
  -- Обновляет количество товара в заказе
  procedure UPD_AMOUNT(
    pnORDERS_DET_ID       ORDERS_DETAIL.id%type,        -- Код товара в заказе
    pnORDERS_DET_ID_ORDER ORDERS_DETAIL.id_order%type,  -- Код заказа
    pnORDERS_DET_QTY_DIFF ORDERS_DETAIL.qty%type        -- Изменение количества товара в заказе
  );

  ---------------------------------------------------------------
  -- Проверяет размер скидки на заказ
  procedure CHK_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- Код заказа
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- Новое значение скидки
  );

end PKG_ORDERS;
/

prompt
prompt Creating package PKG_ORDERS_DETAIL
prompt ==================================
prompt
create or replace package PKG_ORDERS_DETAIL is

  -- Author  : V.SHESTAKOV
  -- Created : 12.12.2022 12:58:04
  -- Purpose : Бизнес-логика работы с товарами в заказе

  ---------------------------------------------------------------
  -- Возвращает стоимость товара с учетом скидки заказа
  function GET_SUM(
    pnID_ORDER       ORDERS_DETAIL.id_order%type,  -- Код заказа
    pnQTY            ORDERS_DETAIL.qty%type,       -- Количество ед
    pnPRICE          ORDERS_DETAIL.price%type,     -- Цена за единицу
    pnDISCOUNT       ORDERS.DISCOUNT%type := null  -- Скидка заказа, если не указан - высчитывается
  ) return number;

  ---------------------------------------------------------------
  -- Обновляет цены товаров в заказе на основе скидки
  procedure UPD_ORD_SUM_BY_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- Код заказа
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- Новое значение скидки
  );

end PKG_ORDERS_DETAIL;
/

prompt
prompt Creating package body PKG_LOG
prompt =============================
prompt
create or replace package body PKG_LOG is

  sERR_LEVEL varchar2(255); -- Текущий уровень логирования

---------------------------------------------------------------
-- Возвращает уровень логирования числом
function GET_ERR_LEVEL_NUM(
  psERR_LEVEL  varchar2
) return number
is
begin
  return case
           when psERR_LEVEL = 'ERROR'   then 1
           when psERR_LEVEL = 'WARNING' then 2
           when psERR_LEVEL = 'DEBUG'   then 3
           when psERR_LEVEL = 'TRACE'   then 4
           else 5
         end;
end GET_ERR_LEVEL_NUM;

------------------------------------------------------
-- Возвращает текущий уровень логирования
function GET_ERR_LEVEL
return varchar2
is
begin
  return sERR_LEVEL;
end GET_ERR_LEVEL;

------------------------------------------------------
-- Устанавливает текущий уровень логирования
procedure SET_ERR_LEVEL(
  psERR_LEVEL  varchar2
)
is
begin
  sERR_LEVEL := psERR_LEVEL;
end SET_ERR_LEVEL;

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG
--   Автономная транзакция
procedure LOG_ERR(
  psERR_MSG    varchar2,
  psERR_CODE   varchar2,
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2,
  psERR_LEVEL  varchar2 -- Тип лога 'ERROR','WARNING','DEBUG','TRACE'
)
is
  pragma AUTONOMOUS_TRANSACTION;
begin
  -- Если уровень логирования вызова больше больше уровня логирования БД - не логируем
  if GET_ERR_LEVEL_NUM(psERR_LEVEL) > GET_ERR_LEVEL_NUM(sERR_LEVEL) then
    return;
  end if;

  insert into ERROR_LOG
    (err_level, proc, err_msg, err_code, obj_id, obj_type)
  values
    (psERR_LEVEL, psPROC, psERR_MSG, psERR_CODE, psOBJ_ID, psOBJ_TYPE);

  commit;
exception
  when others then
    rollback;
    raise;
end LOG_ERR;

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме ошибки (ERROR)
procedure ERROR(
  psERR_MSG    varchar2,
  psERR_CODE   varchar2,
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
)
is
begin
  LOG_ERR(psERR_MSG    => psERR_MSG,
          psERR_CODE   => psERR_CODE,
          psOBJ_ID     => psOBJ_ID,
          psOBJ_TYPE   => psOBJ_TYPE,
          psPROC       => psPROC,
          psERR_LEVEL  => 'ERROR');
end ERROR;

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме предупреждения (WARNING)
procedure WARNING(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
)
is
begin
  LOG_ERR(psERR_MSG    => '',
          psERR_CODE   => '',
          psOBJ_ID     => psOBJ_ID,
          psOBJ_TYPE   => psOBJ_TYPE,
          psPROC       => psPROC,
          psERR_LEVEL  => 'WARNING');
end WARNING;

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме отладки (DEBUG)
procedure DEBUG(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
)
is
begin
  LOG_ERR(psERR_MSG    => '',
          psERR_CODE   => '',
          psOBJ_ID     => psOBJ_ID,
          psOBJ_TYPE   => psOBJ_TYPE,
          psPROC       => psPROC,
          psERR_LEVEL  => 'DEBUG');
end DEBUG;

---------------------------------------------------------------
-- Выводит данные в лог ERROR_LOG в режиме трассировки (TRACE)
procedure TRACE(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
)
is
begin
  LOG_ERR(psERR_MSG    => '',
          psERR_CODE   => '',
          psOBJ_ID     => psOBJ_ID,
          psOBJ_TYPE   => psOBJ_TYPE,
          psPROC       => psPROC,
          psERR_LEVEL  => 'TRACE');
end TRACE;

------------------------------------------------------
-- Удаляет логи
procedure DEL_LOGS
is
begin
  delete from ERROR_LOG;
end DEL_LOGS;

---------------------------------------------------------------
begin
  -- ИНИЦИАЛИЗАЦИЯ ПАКЕТА

  -- Инициализация текущего уровня логирования
  SET_ERR_LEVEL(csERR_LEVEL);
end PKG_LOG;
/

prompt
prompt Creating package body PKG_ORDERS
prompt ================================
prompt
create or replace package body PKG_ORDERS is

  csPACKAGE constant varchar2(64) := 'PKG_ORDERS'; -- Имя пакета, для логирования

  -- КОДЫ ОШИБОК

  --    Код  | Описание
  -- -------------------------------------------
  --  -20001 | Значение скидки не может быть пустым
  --  -20002 | Значение скидки должно быть в интервале 0 - 100
  --  -20003 | Не найден заказ ORDERS.ID - ###

  ---------------------------------------------------------------
  -- Обновляет количество товара в заказе
  procedure UPD_AMOUNT(
    pnORDERS_DET_ID       ORDERS_DETAIL.id%type,        -- Код товара в заказе
    pnORDERS_DET_ID_ORDER ORDERS_DETAIL.id_order%type,  -- Код заказа
    pnORDERS_DET_QTY_DIFF ORDERS_DETAIL.qty%type        -- Изменение количества товара в заказе
  )
  is
    nCNT number;
  begin
    update ORDERS o
       set o.AMOUNT = coalesce(o.AMOUNT, 0) + coalesce(pnORDERS_DET_QTY_DIFF, 0)
     where o.id = pnORDERS_DET_ID_ORDER;

    nCNT := sql%rowcount; -- Сколько обновилось записей

    PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                  psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                  psPROC     => csPACKAGE || '.UPD_AMOUNT');

    if nCNT = 0 then
      raise_application_error(-20003, 'Не найден заказ ORDERS.ID - ' || to_char(pnORDERS_DET_ID_ORDER));
    end if;
  exception
    when others then
      PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                    psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                    psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                    psPROC     => csPACKAGE || '.UPD_AMOUNT');
      raise;
  end UPD_AMOUNT;

  ---------------------------------------------------------------
  -- Проверяет размер скидки на заказ
  procedure CHK_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- Код заказа
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- Новое значение скидки
  )
  is
  begin
    PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_ID) || ' - ' || to_char(pnORDERS_DISCOUNT) , 1, 4000),
                  psOBJ_TYPE => 'pnORDERS_ID - pnORDERS_DISCOUNT',
                  psPROC     => csPACKAGE || '.CHK_DISCOUNT');

    if pnORDERS_DISCOUNT is null then
      raise_application_error(-20001, 'Значение скидки не может быть пустым');
    end if;
    if not pnORDERS_DISCOUNT between 0 and 100 then
      raise_application_error(-20002, 'Значение скидки должно быть в интервале 0 - 100');
    end if;
  exception
    when others then
      PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                    psOBJ_ID   => substr(to_char(pnORDERS_ID) || ' - ' || to_char(pnORDERS_DISCOUNT) , 1, 4000),
                    psOBJ_TYPE => 'pnORDERS_ID - pnORDERS_DISCOUNT',
                    psPROC     => csPACKAGE || '.CHK_DISCOUNT');
      raise;
  end CHK_DISCOUNT;

end PKG_ORDERS;
/

prompt
prompt Creating package body PKG_ORDERS_DETAIL
prompt =======================================
prompt
create or replace package body PKG_ORDERS_DETAIL is

  csPACKAGE constant varchar2(64) := 'PKG_ORDERS_DETAIL';

  ---------------------------------------------------------------
  -- Возвращает стоимость товара с учетом скидки заказа
  function GET_SUM(
    pnID_ORDER       ORDERS_DETAIL.id_order%type,  -- Код заказа
    pnQTY            ORDERS_DETAIL.qty%type,       -- Количество ед
    pnPRICE          ORDERS_DETAIL.price%type,     -- Цена за единицу
    pnDISCOUNT       ORDERS.DISCOUNT%type := null  -- Скидка заказа, если не указан - высчитывается
  ) return number
  is
    nRES       number;
    nDISCOUNT  ORDERS.DISCOUNT%type := pnDISCOUNT;
  begin
    -- Скидка заказа
    if nDISCOUNT is null then
      select min(o.DISCOUNT) as ord_discount
        into nDISCOUNT
        from ORDERS o
       where o.ID = pnID_ORDER;
    end if;

    -- цена(orders_detail.price) * количество(orders_detail.qty) * (1-скидка(orders.descount)/100)
    nRES := coalesce(coalesce(pnPRICE, 0) * coalesce(pnQTY, 0) * (1 - coalesce(nDISCOUNT, 0) / 100), 0);


    PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnID_ORDER)
                                || ' - ' || to_char(pnPRICE)
                                || ' * ' || to_char(pnQTY)
                                || ' * ' || to_char(nDISCOUNT)
                                || ' * (' || to_char(pnDISCOUNT) || ')'
                                || ' = ' || to_char(nRES), 1, 4000),
                  psOBJ_TYPE => 'pnID_ORDER - pnPRICE * pnQTY * nDISCOUNT(pnDISCOUNT) = nRES',
                  psPROC     => csPACKAGE || '.GET_SUM');

    return nRES;
  exception
    when others then
      PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                    psOBJ_ID   => substr(to_char(pnID_ORDER)
                                  || ' - ' || to_char(pnPRICE)
                                  || ' - ' || to_char(pnQTY)
                                  || ' - ' || to_char(nDISCOUNT)
                                  || ' - ' || to_char(nRES), 1, 4000),
                    psOBJ_TYPE => 'pnID_ORDER - pnPRICE - pnQTY - nDISCOUNT - nRES',
                    psPROC     => csPACKAGE || '.GET_SUM');
      raise;
  end GET_SUM;

  ---------------------------------------------------------------
  -- Обновляет цены товаров в заказе на основе скидки
  procedure UPD_ORD_SUM_BY_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- Код заказа
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- Новое значение скидки
  )
  is
    nCNT number;
  begin
    -- Обновляем скидку на заказ у всех товаров
    update ORDERS_DETAIL od
       set od.str_sum = PKG_ORDERS_DETAIL.GET_SUM(pnID_ORDER => od.ID_ORDER,
                                                  pnQTY      => od.QTY,
                                                  pnPRICE    => od.PRICE,
                                                  pnDISCOUNT => pnORDERS_DISCOUNT)
     where od.id_order = pnORDERS_ID;

    nCNT := sql%rowcount;

    PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_ID)
                                || ' - ' || to_char(pnORDERS_DISCOUNT)
                                || ' cnt=' || to_char(nCNT), 1, 4000),
                  psOBJ_TYPE => 'pnORDERS_ID - pnORDERS_DISCOUNT cnt=nCNT',
                  psPROC     => csPACKAGE || '.UPD_ORD_SUM_BY_DISCOUNT');
  exception
    when others then
      PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                    psOBJ_ID   => substr(to_char(pnORDERS_ID)
                                  || ' - ' || to_char(pnORDERS_DISCOUNT)
                                  || ' cnt=' || to_char(nCNT), 1, 4000),
                    psOBJ_TYPE => 'pnORDERS_ID - pnORDERS_DISCOUNT cnt=nCNT',
                    psPROC     => csPACKAGE || '.UPD_ORD_SUM_BY_DISCOUNT');
      raise;
  end UPD_ORD_SUM_BY_DISCOUNT;


end PKG_ORDERS_DETAIL;
/

prompt
prompt Creating trigger TR_ERROR_LOG_B_I
prompt =================================
prompt
create or replace trigger TR_ERROR_LOG_B_I
  before INSERT on ERROR_LOG
  for each row
  -- Триггер инициализирует ID
declare
begin
  if :new.ID is null then
    :new.ID := SEQ_ERROR_LOG.nextval;
  end if;
exception when others then
  null;
end TR_ERROR_LOG_B_I;
/

prompt
prompt Creating trigger TR_ORDERS_B_IU
prompt ===============================
prompt
create or replace trigger TR_ORDERS_B_IU
  before INSERT or UPDATE on ORDERS
  for each row

  -- Триггер обновляет поля ORDERS
  -- * Инициализирует DATE_DOC, AMOUNT
  -- * При обновлении DISCOUNT
  --   - Проверяет DISCOUNT на валидность (PKG_ORDERS.CHK_DISCOUNT)
  --   - Обновляет цены STR_SUM на товары заказа в ORDERS_DETAIL
  --     с учетом новой скидки (PKG_ORDERS_DETAIL.UPD_ORD_SUM_BY_DISCOUNT)
  -- Логирует отладку и ошибки в ERROR_LOG

declare
  sOPERATION varchar2(255);
begin
  sOPERATION := case when INSERTING then 'INS'
                     when UPDATING then 'UPD'
                     when DELETING then 'DEL'
                     else 'NULL' end;
  :new.DISCOUNT := coalesce(:new.DISCOUNT, 0);
  :new.AMOUNT := coalesce(:new.AMOUNT, 0);

  if INSERTING then
    -- INSERTING

    if :new.DATE_DOC is null then
      :new.DATE_DOC := trunc(sysdate);
    end if;

  elsif UPDATING then
    -- UPDATING

    -- Если скидка заказа изменилась
    if coalesce (:old.DISCOUNT, 0) != coalesce(:new.DISCOUNT, 0) then
      -- Проверим правильность скидки
      PKG_ORDERS.CHK_DISCOUNT(pnORDERS_ID       => :new.ID,
                              pnORDERS_DISCOUNT => coalesce (:new.DISCOUNT, 0));
      -- Обновим цены товаров
      PKG_ORDERS_DETAIL.UPD_ORD_SUM_BY_DISCOUNT(pnORDERS_ID       => :new.ID,
                                                pnORDERS_DISCOUNT => coalesce (:new.DISCOUNT, 0));
    end if;

  end if; -- UPDATING

  PKG_LOG.DEBUG(psOBJ_ID   => substr(sOPERATION || ': ' || to_char(coalesce(:new.ID, :old.ID))
                              || ' - ' || to_char(:new.DISCOUNT)
                              || ' - ' || to_char(:new.AMOUNT), 1, 4000),
                psOBJ_TYPE => ':ID - :new.DISCOUNT - :new.AMOUNT',
                psPROC     => 'TR_ORDERS_B_IU');


exception
  when others then
    PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                  psOBJ_ID   => substr(sOPERATION || ': ' || to_char(coalesce(:new.ID, :old.ID))
                                || ' - ' || to_char(:new.DISCOUNT)
                                || ' - ' || to_char(:new.AMOUNT), 1, 4000),
                  psOBJ_TYPE => ':ID - :new.DISCOUNT - :new.AMOUNT',
                  psPROC     => 'TR_ORDERS_B_IU');
    raise;
end TR_ORDERS_B_IU;
/

prompt
prompt Creating trigger TR_ORDERS_DETAIL_BA_IU_IDX
prompt ===========================================
prompt
create or replace trigger TR_ORDERS_DETAIL_BA_IU_IDX
  for INSERT or DELETE on ORDERS_DETAIL
  compound trigger
  -- Триггер обновляет поле ORDERS_DETAIL.IDX
  -- Для операций ВСТАВКИ и УДАЛЕНИЯ
  -- все строки товаров получают новый индекс IDX=1,2,3... с сортировкой ID_ORDER, ID
  -- Операция ОБНОВЛЕНИЯ данных строки игнорируется триггером

  -- ПРОТЕСТИРОВАТЬ:
  --   Поведение при каскадном удалении записей товаров,
  --   если будет настроен каскадный форейжн ключ на таблицу ORDERS
  --
  --   Причина:
  --     "использование составных триггеров связано с документированным багом СУБД"
  --     https://community.oracle.com/tech/developers/discussion/3823651/compound-trigger-and-global-variable
  --     https://habr.com/ru/post/306280/

  nID_ORDER   number;
  nID         number;
  sOPERATION  varchar2(255);

  ---------------------------------------------------------------
  BEFORE EACH ROW IS
  begin
    sOPERATION := case when INSERTING then 'INS'
                       when UPDATING then 'UPD'
                       when DELETING then 'DEL'
                       else 'NULL' end;
    nID_ORDER := :new.ID_ORDER;
    nID := :new.ID;
    if DELETING then
      nID_ORDER := :old.ID_ORDER;
      nID       := :old.ID;
    end if;

    -- Отладка
    PKG_LOG.DEBUG(psOBJ_ID   => substr('  BEFORE EACH ' || sOPERATION || ': '
                             || to_char(nID) || ' - '
                             || to_char(nID_ORDER) , 1, 4000),
                  psOBJ_TYPE => '  BEFORE EACH sOP: nID - nID_ORDER',
                  psPROC     => 'TR_ORDERS_DETAIL_BA_IU_IDX');

  exception
    when others then
      PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                    psOBJ_ID   => substr('  BEFORE EACH ' || sOPERATION || ': '
                               || to_char(nID) || ' - '
                               || to_char(nID_ORDER) , 1, 4000),
                    psOBJ_TYPE => '  BEFORE EACH sOP: nID - nID_ORDER',
                    psPROC     => 'TR_ORDERS_DETAIL_BA_IU_IDX');
      raise;
  END BEFORE EACH ROW;

  ---------------------------------------------------------------
  AFTER STATEMENT IS
    nCNT number := 0;
  begin
    if sOPERATION in ('INS', 'DEL') and nID_ORDER is not null  then
      -- Обновляем индексы у строк заказа
      merge into ORDERS_DETAIL t
      using (-- Выберем все строки заказа
             select od.ID,
                    -- od.ID_ORDER,
                    od.IDX,
                    ROW_NUMBER() over (partition by od.id_order order by id_order, id)
                      as CALC_IDX -- Новый номер строки
               from ORDERS_DETAIL od
              where od.ID_ORDER = nID_ORDER
            ) rec
      on (t.ID = rec.ID)
      when matched then
        update
           set t.IDX = rec.CALC_IDX;

      nCNT := sql%rowcount;
    end if;

    -- Отладка
    PKG_LOG.DEBUG(psOBJ_ID   => substr('AFTER ' || sOPERATION || ': '
                             || to_char(nID_ORDER)  || ' cnt='
                             || to_char(nCNT) , 1, 4000),
                  psOBJ_TYPE => 'AFTER EACH sOP: nID_ORDER cnt=nCNT',
                  psPROC     => 'TR_ORDERS_DETAIL_BA_IU_IDX');

    nID_ORDER := null;
  exception
    when others then
      PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                    psOBJ_ID   => substr('AFTER ' || sOPERATION || ': '
                               || to_char(nID_ORDER)  || ' cnt='
                               || to_char(nCNT) , 1, 4000),
                    psOBJ_TYPE => 'AFTER EACH sOP: nID_ORDER cnt=nCNT',
                    psPROC     => 'TR_ORDERS_DETAIL_BA_IU_IDX');
      raise;
  END AFTER STATEMENT;

end TR_ORDERS_DETAIL_BA_IU_IDX;
/

prompt
prompt Creating trigger TR_ORDERS_DETAIL_B_IUD
prompt =======================================
prompt
create or replace trigger TR_ORDERS_DETAIL_B_IUD
  before INSERT or UPDATE or DELETE on ORDERS_DETAIL
  for each row

  -- Триггер обновляет поля ORDERS_DETAIL
  --   STR_SUM - Считается сумма товара с учетом скидки заказа
  -- Обновляет поля ORDERS
  --   AMOUNT - Количество товаров в заказе
  -- Логирует отладку и ошибки в ERROR_LOG

declare
  nQTY_DIFF   ORDERS_DETAIL.QTY%type;     -- Разница в количестве
  nSTR_SUM    ORDERS_DETAIL.STR_SUM%type; -- Новая цена
  sOPERATION  varchar2(255);
begin
  sOPERATION := case when INSERTING then 'INS'
                     when UPDATING then 'UPD'
                     when DELETING then 'DEL'
                     else 'NULL' end;

  if INSERTING or UPDATING then

    nQTY_DIFF := coalesce(:new.QTY, 0) - coalesce(:old.QTY, 0);
    :new.QTY := coalesce(:new.QTY, 0);

    -- Если количество изменилось
    if coalesce(:old.QTY, 0) <> coalesce(:new.QTY, 0) then
      -- Обновляем количество товара в заказе
      PKG_ORDERS.UPD_AMOUNT(pnORDERS_DET_ID       => :new.ID,
                            pnORDERS_DET_ID_ORDER => :new.ID_ORDER,
                            pnORDERS_DET_QTY_DIFF => nQTY_DIFF);
    end if;

    -- Если количество или цена товара изменились
    if coalesce(:old.QTY, 0) <> coalesce(:new.QTY, 0)
        or coalesce(:old.PRICE, 0) <> coalesce(:new.PRICE, 0) then
      -- Обновляем сумму товара
      nSTR_SUM := PKG_ORDERS_DETAIL.GET_SUM(pnID_ORDER => :new.ID_ORDER,
                                            pnQTY      => :new.QTY,
                                            pnPRICE    => :new.PRICE);
      :new.STR_SUM := nSTR_SUM;
    end if;

  elsif DELETING then

    nQTY_DIFF := -1 * coalesce(:old.QTY, 0);
    -- Обновляем количество товара в заказе
    PKG_ORDERS.UPD_AMOUNT(pnORDERS_DET_ID       => :old.ID,
                          pnORDERS_DET_ID_ORDER => :old.ID_ORDER,
                          pnORDERS_DET_QTY_DIFF => nQTY_DIFF);
  end if; -- DELETING

  -- Отладка
  PKG_LOG.DEBUG(psOBJ_ID   => substr(sOPERATION || ': ' || to_char(:new.ID)
                              || ' prc-' || to_char(:new.PRICE)
                              || ' q-'   || to_char(:new.QTY)
                              || ' sm-'  || to_char(nSTR_SUM)
                              || ' qd-'  || to_char(nQTY_DIFF)
                              || ' ix-'  || to_char(:new.IDX), 1, 4000),
                psOBJ_TYPE => 'sOP: new.ID - :new.PRICE - :new.QTY - nSTR_SUM - nQTY_DIFF',
                psPROC     => 'TR_ORDERS_DETAIL_B_IUD');

exception
  when others then
    PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode,
                  psOBJ_ID   => substr(sOPERATION || ': ' || to_char(:new.ID)
                                || ' prc-' || to_char(:new.PRICE)
                                || ' q-'   || to_char(:new.QTY)
                                || ' sm-'  || to_char(nSTR_SUM)
                                || ' qd-'  || to_char(nQTY_DIFF)
                                || ' ix-'  || to_char(:new.IDX), 1, 4000),
                  psOBJ_TYPE => 'sOP: new.ID - :new.PRICE - :new.QTY - nSTR_SUM - nQTY_DIFF',
                  psPROC     => 'TR_ORDERS_DETAIL_B_IUD');
    raise;
end TR_ORDERS_DETAIL_B_IUD;
/


prompt Done
spool off
set define on
