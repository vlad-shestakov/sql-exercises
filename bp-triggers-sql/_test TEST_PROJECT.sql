-- _test TEST_PROJECT.sql

---------------------------------------------------------------
----               �������� �������� 
---------------------------------------------------------------


/ --------------------------------------------------------------- 
-- ���� ���� - �������������
begin
  -- ������ �������
  delete from ORDERS_DETAIL;
  delete from ORDERS;
  delete from SKU;
  
  -- ������� ��� ����
  PKG_LOG.DEL_LOGS;  
  commit;
  
  -- ��-��������� ����� PKG_LOG �������� ��������� ������ - ERROR
  -- �������� ������ �����������
  dbms_output.put_line('PKG_LOG.csERR_LEVEL - ' || PKG_LOG.csERR_LEVEL);
  -- ������������� ����������� ������ �� ������ TRACE, ��� ���� ��������� ERROR -> WARNING -> DEBUG -> TRACE
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'TRACE'); 
  -- �������� ������ �����������
  dbms_output.put_line('new PKG_LOG.GET_ERR_LEVEL - ' || PKG_LOG.GET_ERR_LEVEL); -- TRACE
  
  -- ��������� ������...
  insert into SKU (ID, NAME)
    values (1, '�������� �������');
  insert into SKU (ID, NAME)
    values (2, '����� ���������');
    
  -- ��������� ������...
  insert into ORDERS (ID, N_DOC)
    values (1, 1);
  insert into ORDERS (ID, N_DOC)
    values (2, 2);
    
  -- ��������� ��������� ������ � ������...
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
-- ��������� 2 ������, 2 ������ � ������ � ���
-- ���������

/ ---------------------------------------------------------------       
-- ������� �������. (SKU)
select s.*
      ,s.rowid
  from SKU s
 where 1=1
 order by 1
;/**/ 

/ ---------------------------------------------------------------       
-- ������� ���������� ������. (ORDERS)
select o.*
      ,o.rowid
  from ORDERS o
 where 1=1
 order by 1
;/**/ 
-- ����������� AMOUNT, DATE_DOC
/* 
ID  N_DOC DATE_DOC  AMOUNT  DISCOUNT
---------------------------------------------------------------                  
1   1     13.12.2022  30  0
2   2     13.12.2022  50  0
/**/

/ ---------------------------------------------------------------       
-- ������� ������� � ������� (ORDERS_DETAIL)
select od.*
      ,od.rowid
  from ORDERS_DETAIL od
 where 1=1
 order by od.id_order, od.idx
;/**/
-- ����������� ���� STR_SUM � ������� IDX

/ ---------------------------------------------------------------
-- ��� ������ � ������� (ERROR_LOG)
select *
  from ERROR_LOG el
 where 1=1
 order by 1 desc
;/**/ 
-- �������� ������� ���� �������� � �� �����������
-- ���� ����� ������ ����������, ��� ����� �������� � err_level in ('ERROR')
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
-- ������� ��� �����
begin
  insert into ORDERS_DETAIL (ID, ID_ORDER, ID_SKU, QTY, PRICE)
  values (6, 1, 1, 15, 50);
end; 
/

-- ������� � ������� ������������� IDX
-- ��������� ORDERS_DETAIL
-- ���������� ������� ������������� AMOUNT
-- ��������� ORDERS

/ --------------------------------------------------------------- 
-- ������ ����� �� ������ ������ ��� �����
begin
  delete from ORDERS_DETAIL od
    where od.id = 1;
end; 
/
-- ������� � ������� ������������� IDX
-- ��������� ORDERS_DETAIL
-- ���������� ������� ������������� AMOUNT
-- ��������� ORDERS

/ --------------------------------------------------------------- 
-- ������� ���������� ������
begin
  update ORDERS_DETAIL od
     set od.qty = 10 -- 20 -> 10
    where od.id = 2;
end; 
/
-- ���������� ���� STR_SUM -- 1000 -> 500
-- ��������� ORDERS_DETAIL

/ --------------------------------------------------------------- 
-- ��������� ������������ ������ �� 1 �����
begin
  update ORDERS od
     set od.discount = -1 -- 1-100
    where od.id = 1;
end; 
/
-- ��������� ������ - ORA-20002: �������� ������ ������ ���� � ��������� 0 - 100


/ --------------------------------------------------------------- 
-- ��������� ������ 50% �� 1 �����
begin
  update ORDERS od
     set od.discount = 50
    where od.id = 1;
end; 
/
-- ���������� ���� STR_SUM � ������� ������ 1
-- ��������� ORDERS_DETAIL
