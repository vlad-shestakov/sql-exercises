create or replace package PKG_LOG is

  -- Author  : V.SHESTAKOV
  -- Created : 12.12.2022 22:59:54
  -- Purpose : ������ � �������� ����� ERROR_LOG
  
  -- ������� ����������� ������ �� ��-��������� - ERROR / WARNING / DEBUG / TRACE
  csERR_LEVEL constant varchar2(255) := 'ERROR'; 
  
--------------------------------------------------------------- 
/*
  -- ������� �������������:
  
  -- ������� ������� ����������� � �� ��� ������
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => 'TRACE');  
  -- ���
  PKG_LOG.SET_ERR_LEVEL(psERR_LEVEL => PKG_LOG.csERR_LEVEL); 
  
  
  -- ������ ����������� �������
  PKG_LOG.DEBUG(psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                psPROC     => 'PKG_ORDERS.UPD_AMOUNT');
                
  -- ������ ����������� ������
  PKG_LOG.ERROR(psERR_MSG  => sqlerrm, psERR_CODE => sqlcode, 
                psOBJ_ID   => substr(to_char(pnORDERS_DET_ID_ORDER) || ' - ' || to_char(pnORDERS_DET_QTY_DIFF) , 1, 4000),
                psOBJ_TYPE => 'pnORDERS_DET_ID_ORDER - pnORDERS_DET_QTY_DIFF',
                psPROC     => 'PKG_ORDERS.UPD_AMOUNT');
                
                
  -- �������� �����
  PKG_LOG.DEL_LOGS;
  commit;
  
/**/

--------------------------------------------------------------- 
-- ���������� ������� ����������� ������
function GET_ERR_LEVEL_NUM(
  psERR_LEVEL  varchar2
) return number;

------------------------------------------------------ 
-- ���������� ������� ������� �����������
function GET_ERR_LEVEL 
return varchar2;

------------------------------------------------------ 
-- ������������� ������� ������� �����������
procedure SET_ERR_LEVEL(
  psERR_LEVEL  varchar2
);

--------------------------------------------------------------- 
-- ������� ������ � ��� ERROR_LOG � ������ ������ (ERROR)
procedure ERROR(
  psERR_MSG    varchar2,
  psERR_CODE   varchar2,
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

--------------------------------------------------------------- 
-- ������� ������ � ��� ERROR_LOG � ������ �������������� (WARNING)
procedure WARNING(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

--------------------------------------------------------------- 
-- ������� ������ � ��� ERROR_LOG � ������ ������� (DEBUG)
procedure DEBUG(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

--------------------------------------------------------------- 
-- ������� ������ � ��� ERROR_LOG � ������ ����������� (TRACE)
procedure TRACE(
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2
);

------------------------------------------------------ 
-- ������� ����
procedure DEL_LOGS;

end PKG_LOG;
/
create or replace package body PKG_LOG is

  sERR_LEVEL varchar2(255); -- ������� ������� �����������
  
--------------------------------------------------------------- 
-- ���������� ������� ����������� ������
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
-- ���������� ������� ������� �����������
function GET_ERR_LEVEL
return varchar2
is 
begin
  return sERR_LEVEL;
end GET_ERR_LEVEL; 

------------------------------------------------------ 
-- ������������� ������� ������� �����������
procedure SET_ERR_LEVEL(
  psERR_LEVEL  varchar2
)
is 
begin
  sERR_LEVEL := psERR_LEVEL;
end SET_ERR_LEVEL; 
 
---------------------------------------------------------------
-- ������� ������ � ��� ERROR_LOG
--   ���������� ����������
procedure LOG_ERR(
  psERR_MSG    varchar2,
  psERR_CODE   varchar2,
  psOBJ_ID     varchar2,
  psOBJ_TYPE   varchar2,
  psPROC       varchar2,
  psERR_LEVEL  varchar2 -- ��� ���� 'ERROR','WARNING','DEBUG','TRACE'
) 
is
  pragma AUTONOMOUS_TRANSACTION;
begin
  -- ���� ������� ����������� ������ ������ ������ ������ ����������� �� - �� ��������
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
-- ������� ������ � ��� ERROR_LOG � ������ ������ (ERROR)
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
-- ������� ������ � ��� ERROR_LOG � ������ �������������� (WARNING)
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
-- ������� ������ � ��� ERROR_LOG � ������ ������� (DEBUG)
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
-- ������� ������ � ��� ERROR_LOG � ������ ����������� (TRACE)
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
-- ������� ����
procedure DEL_LOGS
is 
begin
  delete from ERROR_LOG;
end DEL_LOGS; 

--------------------------------------------------------------- 
begin 
  -- ������������� ������
  
  -- ������������� �������� ������ �����������
  SET_ERR_LEVEL(csERR_LEVEL);
end PKG_LOG;
/
