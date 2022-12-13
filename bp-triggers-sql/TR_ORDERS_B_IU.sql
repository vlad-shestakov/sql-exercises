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
