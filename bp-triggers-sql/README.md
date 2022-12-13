## 04. Бизнес-логика через триггеры, механизм логирования

## Задача

### Дано
Есть три таблицы:
```
  -- Таблица товаров
  CREATE TABLE SKU(
    ID          NUMBER,
    NAME        VARCHAR2(200) not null
  );
  COMMENT ON TABLE sku IS 'Таблица каталог товаров.';
  
  
  -- Таблица заказа
  CREATE TABLE ORDERS(
    ID          NUMBER,
    N_DOC       NUMBER,
    DATE_DOC    DATE,
    AMOUNT      NUMBER,
    DISCOUNT    NUMBER
  );
  COMMENT ON TABLE orders IS 'Таблица содержащая заказы.';

  CREATE TABLE ORDERS_DETAIL(
    ID          NUMBER,
    ID_ORDER    NUMBER not null,
    ID_SKU      NUMBER not null,
    PRICE       NUMBER,
    QTY         NUMBER,
    STR_SUM     NUMBER,
    IDX         NUMBER 
  );
  COMMENT ON TABLE orders_detail IS 'Таблица содержащая товары в заказах.';

```

### Задание

Необходимо спроектировать триггера которые будут обрабатывать логику и целостность данных в данных таблицах.
 
*Функциональные требования:*
1) При изменении поля скидка (ORDERS.DESCOUNT) должны пересчитываться суммы по строкам заказа (ORDERS_DETAIL.STR_SUM).
2) При добавлении строки заказа, удалении строки заказа  или изменении цены или количества по строке заказа должна изменяться сумма заказа (ORDERS.AMOUNT).
3) При изменении цены или количества по строке заказа должна автоматом пересчитываться сумма по строке заказа (ORDERS_DETAIL.STR_SUM).
4) Поле в строке заказа ORDERS_DETAIL.IDX  порядковый номер должен формироваться автоматически и в нумерации строк заказа не должно быть пропусков. Последовательность должна быть строго 1,2, … количество строк заказа.
5) Значение скидки (ORDERS.DISCOUNT) может иметь значение от 0 до 100
6) Сумма по строке вычисляется следующим образом = цена(orders_detail.price) * количество(orders_detail.qty) * (1-скидка(orders.descount)/100)
 
*Ограничения:*
  Изменять можно только следующие поля
```
    orders.N_DOC
    orders.DATE_DOC
    orders.DISCOUNT
    orders_detail.ID_ORDER
    orders_detail.PRICE
    orders_detail.QTYD
    orders_detail.SKU
```
остальные пересчитываются автоматически.


### Решение


*Реализованы:*
- триггеры, выполняющие все требования технического задания
-- дополнительно реализован механизм логирования ошибок и отладки через новую таблицу ERROR_LOG
-- основная бизнес-логика реализована через пакеты PKG_ORDERS, PKG_ORDERS_DETAIL, PKG_LOG
- Создан тестовый сценарий:
-- Скрипт создания объектов  - [_test CREATE_ALL_OBJECTS.sql](./_test CREATE_ALL_OBJECTS.sql)
-- Тестовый сецнарий         - [_test TEST_PROJECT.sql](./_test TEST_PROJECT.sql)

```
ДОБАВЛЕНЫ ОБЪЕКТЫ:
  Таблица [ERROR_LOG.sql](./ERROR_LOG.sql) - Логирование ошибок и отладки
  Сиквенс [SEQ_ERROR_LOG.sql](./SEQ_ERROR_LOG.sql) 
  Пакеты
    [PKG_LOG.sql](./PKG_LOG.sql)            - Работа с таблицей логов ERROR_LOG
    [PKG_ORDERS.sql](./PKG_ORDERS.sql)         - Пакет бизнес-логики для таблицы заказов ORDERS
    [PKG_ORDERS_DETAIL.sql](./PKG_ORDERS_DETAIL.sql)  - Пакет бизнес-логики для таблицы товаров в заказах ORDERS_DETAIL
  Триггеры 
    [TR_ERROR_LOG_B_I.sql](./TR_ERROR_LOG_B_I.sql)             - Инициализация значений ключа 
    [TR_ORDERS_B_IU.sql](./TR_ORDERS_B_IU.sql)               - Обработка изменений в таблице Заказы
    [TR_ORDERS_DETAIL_B_IUD.sql](./TR_ORDERS_DETAIL_B_IUD.sql)       - Обработка изменений в таблице Товары заказов
    [TR_ORDERS_DETAIL_BA_IU_IDX.sql](./TR_ORDERS_DETAIL_BA_IU_IDX.sql)   - Обработка индексов товаров в таблице Товары заказов
```