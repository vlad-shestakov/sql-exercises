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
