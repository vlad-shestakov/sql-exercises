create or replace package PKG_ORDERS_DETAIL is

  -- Author  : V.SHESTAKOV
  -- Created : 12.12.2022 12:58:04
  -- Purpose : ������-������ ������ � �������� � ������

  ---------------------------------------------------------------
  -- ���������� ��������� ������ � ������ ������ ������
  function GET_SUM(
    pnID_ORDER       ORDERS_DETAIL.id_order%type,  -- ��� ������
    pnQTY            ORDERS_DETAIL.qty%type,       -- ���������� ��
    pnPRICE          ORDERS_DETAIL.price%type,     -- ���� �� �������
    pnDISCOUNT       ORDERS.DISCOUNT%type := null  -- ������ ������, ���� �� ������ - �������������
  ) return number;

  ---------------------------------------------------------------
  -- ��������� ���� ������� � ������ �� ������ ������
  procedure UPD_ORD_SUM_BY_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- ��� ������
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- ����� �������� ������ 
  );
  
end PKG_ORDERS_DETAIL;
/
create or replace package body PKG_ORDERS_DETAIL is

  csPACKAGE constant varchar2(64) := 'PKG_ORDERS_DETAIL';
  
  ---------------------------------------------------------------
  -- ���������� ��������� ������ � ������ ������ ������
  function GET_SUM(
    pnID_ORDER       ORDERS_DETAIL.id_order%type,  -- ��� ������
    pnQTY            ORDERS_DETAIL.qty%type,       -- ���������� ��
    pnPRICE          ORDERS_DETAIL.price%type,     -- ���� �� �������
    pnDISCOUNT       ORDERS.DISCOUNT%type := null  -- ������ ������, ���� �� ������ - �������������
  ) return number
  is 
    nRES       number;
    nDISCOUNT  ORDERS.DISCOUNT%type := pnDISCOUNT;
  begin
    -- ������ ������
    if nDISCOUNT is null then
      select min(o.DISCOUNT) as ord_discount
        into nDISCOUNT
        from ORDERS o
       where o.ID = pnID_ORDER;
    end if;
     
    -- ����(orders_detail.price) * ����������(orders_detail.qty) * (1-������(orders.descount)/100)
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
  -- ��������� ���� ������� � ������ �� ������ ������
  procedure UPD_ORD_SUM_BY_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- ��� ������
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- ����� �������� ������ 
  )
  is
    nCNT number;
  begin
    -- ��������� ������ �� ����� � ���� �������
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
