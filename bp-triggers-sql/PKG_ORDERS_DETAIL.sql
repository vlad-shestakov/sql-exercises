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
