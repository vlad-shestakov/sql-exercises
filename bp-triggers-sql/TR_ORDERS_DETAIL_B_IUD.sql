create or replace trigger TR_ORDERS_DETAIL_B_IUD
  before INSERT or UPDATE or DELETE on ORDERS_DETAIL
  for each row
    
  -- ������� ��������� ���� ORDERS_DETAIL
  --   STR_SUM - ��������� ����� ������ � ������ ������ ������
  -- ��������� ���� ORDERS
  --   AMOUNT - ���������� ������� � ������
  -- �������� ������� � ������ � ERROR_LOG
  
declare
  nQTY_DIFF   ORDERS_DETAIL.QTY%type;     -- ������� � ����������
  nSTR_SUM    ORDERS_DETAIL.STR_SUM%type; -- ����� ����
  sOPERATION  varchar2(255);
begin
  sOPERATION := case when INSERTING then 'INS'
                     when UPDATING then 'UPD'
                     when DELETING then 'DEL'
                     else 'NULL' end;

  if INSERTING or UPDATING then

    nQTY_DIFF := coalesce(:new.QTY, 0) - coalesce(:old.QTY, 0);
    :new.QTY := coalesce(:new.QTY, 0);

    -- ���� ���������� ����������
    if coalesce(:old.QTY, 0) <> coalesce(:new.QTY, 0) then
      -- ��������� ���������� ������ � ������
      PKG_ORDERS.UPD_AMOUNT(pnORDERS_DET_ID       => :new.ID,
                            pnORDERS_DET_ID_ORDER => :new.ID_ORDER,
                            pnORDERS_DET_QTY_DIFF => nQTY_DIFF);
    end if;

    -- ���� ���������� ��� ���� ������ ����������
    if coalesce(:old.QTY, 0) <> coalesce(:new.QTY, 0)
        or coalesce(:old.PRICE, 0) <> coalesce(:new.PRICE, 0) then
      -- ��������� ����� ������
      nSTR_SUM := PKG_ORDERS_DETAIL.GET_SUM(pnID_ORDER => :new.ID_ORDER,
                                            pnQTY      => :new.QTY,
                                            pnPRICE    => :new.PRICE);
      :new.STR_SUM := nSTR_SUM;
    end if;

  elsif DELETING then

    nQTY_DIFF := -1 * coalesce(:old.QTY, 0);
    -- ��������� ���������� ������ � ������
    PKG_ORDERS.UPD_AMOUNT(pnORDERS_DET_ID       => :old.ID,
                          pnORDERS_DET_ID_ORDER => :old.ID_ORDER,
                          pnORDERS_DET_QTY_DIFF => nQTY_DIFF);
  end if; -- DELETING

  -- �������
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
