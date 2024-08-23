create or replace trigger TR_ERROR_LOG_B_I
  before INSERT on ERROR_LOG
  for each row
  -- Триггер инициализирует ID
declare
begin
  if :new.ID is null then
    :new.ID := SEQ_ERROR_LOG.nextval;
  end if;
exception when others then
  null;
end TR_ERROR_LOG_B_I;
/
