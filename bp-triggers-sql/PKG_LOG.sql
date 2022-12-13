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
