-- Create table
create table ERROR_LOG
(
  id        NUMBER not null,
  err_level VARCHAR2(10) default 'ERROR' not null,
  log_date  DATE default sysdate not null,
  proc      VARCHAR2(255),
  err_msg   VARCHAR2(4000),
  err_code  VARCHAR2(255),
  obj_id    VARCHAR2(4000),
  obj_type  VARCHAR2(255)
)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  )
nologging;
-- Add comments to the table 
comment on table ERROR_LOG
  is 'Логирование ошибок.';
-- Create/Recreate primary, unique and foreign key constraints 
alter table ERROR_LOG
  add constraint PK_ERROR_LOG primary key (ID)
  using index 
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate check constraints 
alter table ERROR_LOG
  add constraint CHK_ERROR_LOG_LEVEL
  check (ERR_LEVEL in ('ERROR','WARNING','DEBUG','TRACE'));
