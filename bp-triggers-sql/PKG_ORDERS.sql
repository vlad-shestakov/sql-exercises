create or replace package PKG_ORDERS is

  -- Author  : V.SHESTAKOV
  -- Created : 12.12.2022
  -- Purpose : ������-������ ������ � ��������

  ---------------------------------------------------------------
  -- ��������� ���������� ������ � ������
  procedure UPD_AMOUNT(
    pnORDERS_DET_ID       ORDERS_DETAIL.id%type,        -- ��� ������ � ������
    pnORDERS_DET_ID_ORDER ORDERS_DETAIL.id_order%type,  -- ��� ������
    pnORDERS_DET_QTY_DIFF ORDERS_DETAIL.qty%type        -- ��������� ���������� ������ � ������ 
  );
  
  ---------------------------------------------------------------
  -- ��������� ������ ������ �� �����
  procedure CHK_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- ��� ������
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- ����� �������� ������ 
  );
  
end PKG_ORDERS;
/
create or replace package body PKG_ORDERS is
  
  csPACKAGE constant varchar2(64) := 'PKG_ORDERS'; -- ��� ������, ��� �����������
  
  -- ���� ������
  
  --    ���  | ��������
  -- -------------------------------------------
  --  -20001 | �������� ������ �� ����� ���� ������
  --  -20002 | �������� ������ ������ ���� � ��������� 0 - 100
  --  -20003 | �� ������ ����� ORDERS.ID - ###
      
  ---------------------------------------------------------------
  -- ��������� ���������� ������ � ������
  procedure UPD_AMOUNT(
    pnORDERS_DET_ID       ORDERS_DETAIL.id%type,        -- ��� ������ � ������
    pnORDERS_DET_ID_ORDER ORDERS_DETAIL.id_order%type,  -- ��� ������
    pnORDERS_DET_QTY_DIFF ORDERS_DETAIL.qty%type        -- ��������� ���������� ������ � ������ 
  )
  is
    nCNT number;
  begin
    update ORDERS o
       set o.AMOUNT = coalesce(o.AMOUNT, 0) + coalesce(pnORDERS_DET_QTY_DIFF, 0)
     where o.id = pnORDERS_DET_ID_ORDER;
    
    nCNT := sql%rowcount; -- ������� ���������� �������
    
    PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                  psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                  psPROC     => csPACKAGE || '.UPD_AMOUNT');
            
    if nCNT = 0 then 
      raise_application_error(-20003, '�� ������ ����� ORDERS.ID - ' || to_char(pnORDERS_DET_ID_ORDER)); 
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
  -- ��������� ������ ������ �� �����
  procedure CHK_DISCOUNT(
    pnORDERS_ID         ORDERS.ID%type,      -- ��� ������
    pnORDERS_DISCOUNT   ORDERS.DISCOUNT%type -- ����� �������� ������ 
  )
  is
  begin
    PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_ID) || ' - ' || to_char(pnORDERS_DISCOUNT) , 1, 4000),
                  psOBJ_TYPE => 'pnORDERS_ID - pnORDERS_DISCOUNT',
                  psPROC     => csPACKAGE || '.CHK_DISCOUNT');
            
    if pnORDERS_DISCOUNT is null then
      raise_application_error(-20001, '�������� ������ �� ����� ���� ������'); 
    end if;
    if not pnORDERS_DISCOUNT between 0 and 100 then
      raise_application_error(-20002, '�������� ������ ������ ���� � ��������� 0 - 100'); 
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
