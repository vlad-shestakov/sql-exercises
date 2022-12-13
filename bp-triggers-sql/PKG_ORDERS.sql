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
