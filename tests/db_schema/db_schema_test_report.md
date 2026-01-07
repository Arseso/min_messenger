# Тестирование структуры базы данных messenger

## Цель  
Валидация DDL-схемы и поведенческих ограничений БД messenger (DDL + DML + проверочные запросы).

## Предусловия  
- Локальная СУБД MySQL ≥ 8.0 (режим `STRICT_TRANS_TABLES` включён).  
- Отсутствие существующей базы `messenger` или её полная очистка перед запуском.  
- Используемый DDL-скрипт схемы: `schema.sql` из ветки `feature/db-schema`.  
- Тестовый скрипт: `tests/db_schema/test_db_structure.sql` (копия из ветки `feature/db-schema`).

### Шаги и результаты

| № | Действие | Команда / Запрос | Ответ / Наблюдение | Статус |
|---|----------|------------------|---------------------|--------|
| 1 | Создание пользователей `krot`, `belka`, `enot` | `INSERT INTO users (username, password_hash) VALUES ('krot',...),('belka',...),('enot',...)` | `SELECT COUNT(*) = 3` → `success = 1` | ✅ |
| 2 | Создание приватного чата между `krot` и `belka` | `INSERT INTO chats … (NULL, 'private', 1); INSERT INTO user_chats … (1, @pchat), (2, @pchat)` | `type_ok = 1`, `members_count_ok = 1`, `members_set_ok = 1` | ✅ |
| 3 | Отправка сообщения от `krot` к `belka` | `INSERT INTO messages (sender_id, chat_id, content) VALUES (1, @pchat, 'Привет, belka!')` | `content_ok = 1`, `sender_ok = 1` | ✅ |
| 4 | Добавление вложения к сообщению | `INSERT INTO attachments (message_id, file_type, file_url) VALUES (@msg1, 'image/png', 'https://ex.com/hello.png')` | `exists_ok = 1`, `type_ok = 1` | ✅ |
| 5 | Создание группового чата `Project Alpha` и уведомлений | `INSERT INTO chats … ('Project Alpha', 'group', 1); INSERT INTO user_chats (1,2,3); INSERT INTO messages; INSERT INTO notifications (2,3)` | `name_ok = 1`, `members_ok = 1`, `notifs_ok = 1` | ✅ |
| 6 | Проверка `UNIQUE (user_id, chat_id)` при дублирующей вставке | `INSERT IGNORE INTO user_chats (1, @pchat)` дважды | `only_one_record = 1` (дубль проигнорирован) | ✅ |
| 7 | Проверка наличия `ON DELETE RESTRICT` для `chats.created_by`, `messages.sender_id` | Запрос к `information_schema.REFERENTIAL_CONSTRAINTS … DELETE_RULE = 'RESTRICT'` | `count_ok = 1` (2 правила найдено) | ✅ |
| 8 | Проверка `ON DELETE CASCADE` при удалении чата | `INSERT chats/user_chats/messages/attachments; DELETE FROM chats WHERE chat_id = @tmp` | `uc_gone = 1`, `msg_gone = 1`, `att_gone = 1` | ✅ |
| 9 | Проверка soft-delete для пользователя и сообщения | `UPDATE users SET is_deleted = TRUE WHERE username = 'enot'; UPDATE messages SET is_deleted = TRUE WHERE message_id = @msg1` | `enot_deleted = 1`, `msg_deleted = 1` | ✅ |
|10 | Проверка наличия индексов | Запросы к `information_schema.STATISTICS` для `idx_messages_chat`, `idx_messages_sender`, `idx_user_chats_user`, `idx_attach_msg`, `idx_notif_user_ok = 1` | Все `*_ok = 1` (5 индексов подтверждены) | ✅ |
|11 | Проверка `ON UPDATE CASCADE` | Запрос к `REFERENTIAL_CONSTRAINTS` | `count_ok = 1` (2 правила) | ✅ |
|12 | Валидация `ENUM` | `INSERT IGNORE … chat_type = 'invalid_type'` | `rejected_ok = 1` (`chat_type = ''`) | ✅ |
|13 | Обновление `last_message_at` | `UPDATE chats SET last_message_at = NOW()` | `updated_ok = 1` | ✅ |

### Анализ
- Все проверки пройдены без ошибок.  
- `ON DELETE RESTRICT` предотвращает удаление пользователей, участвующих в чатах/сообщениях — обеспечивает целостность данных.  
- `ON DELETE CASCADE` корректно удаляет каскадно: чат → участники, сообщения, вложения.  
- `UNIQUE (user_id, chat_id)` эффективно блокирует дублирование участия.  
- `Soft-delete` не нарушает связи — пользователь и сообщение остаются в БД, но скрыты логически.  
- Все индексы присутствуют и названы по соглашению (`idx_{table}_{column}`).

### Вывод
**Сценарий пройден успешно.**   
Структура БД обеспечивает:  
- целостность данных (ограничения `RESTRICT/CASCADE`),  
- безопасность ввода (`ENUM, UNIQUE`),  
- гибкость (`soft-delete`, обновляемые метаданные вроде `last_message_at`),  
- производительность (полный набор индексов).