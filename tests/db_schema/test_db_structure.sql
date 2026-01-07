-- ТЕСТОВЫЙ СКРИПТ messenger

CREATE DATABASE IF NOT EXISTS messenger;
USE messenger;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notifications, attachments, messages, user_chats, chats, users;
SET FOREIGN_KEY_CHECKS = 1;

-- Структура
CREATE TABLE users (user_id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50) NOT NULL UNIQUE, password_hash TEXT NOT NULL, avatar_url TEXT, is_deleted BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);
CREATE TABLE chats (chat_id INT AUTO_INCREMENT PRIMARY KEY, chat_name VARCHAR(100), chat_type ENUM('private','group') NOT NULL, created_by INT NOT NULL, last_message_at TIMESTAMP NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE RESTRICT ON UPDATE CASCADE);
CREATE TABLE user_chats (user_chat_id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, chat_id INT NOT NULL, role ENUM('member','admin') DEFAULT 'member', joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY (user_id, chat_id), FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE ON UPDATE CASCADE);
CREATE TABLE messages (message_id INT AUTO_INCREMENT PRIMARY KEY, sender_id INT NOT NULL, chat_id INT NOT NULL, message_type ENUM('text','image','file') DEFAULT 'text', content TEXT, is_deleted BOOLEAN DEFAULT FALSE, status ENUM('sent','delivered','read') DEFAULT 'sent', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE RESTRICT ON UPDATE CASCADE, FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE ON UPDATE CASCADE);
CREATE TABLE attachments (attachment_id INT AUTO_INCREMENT PRIMARY KEY, message_id INT NOT NULL, file_type VARCHAR(50) NOT NULL, file_url TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (message_id) REFERENCES messages(message_id) ON DELETE CASCADE ON UPDATE CASCADE);
CREATE TABLE notifications (notification_id INT AUTO_INCREMENT PRIMARY KEY, user_id INT NOT NULL, type ENUM('message','invitation','reaction') NOT NULL, status ENUM('unread','read') DEFAULT 'unread', reference_id INT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE);

-- Индексы
CREATE INDEX idx_messages_chat ON messages(chat_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_user_chats_user ON user_chats(user_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_attach_msg ON attachments(message_id);

-- Тест 1. Пользователи
INSERT INTO users (username, password_hash) VALUES ('krot','$2a$10$fake1'),('belka','$2a$10$fake2'),('enot','$2a$10$fake3');
SELECT 'Пользователи' AS test, (SELECT COUNT(*) FROM users WHERE username IN ('krot','belka','enot')) = 3 AS success;

-- Тест 2. Приватный чат
INSERT INTO chats (chat_name, chat_type, created_by) VALUES (NULL, 'private', 1);
SET @pchat = LAST_INSERT_ID();
INSERT INTO user_chats (user_id, chat_id) VALUES (1, @pchat), (2, @pchat);
SELECT 'Приватный чат' AS test,
    (SELECT chat_type FROM chats WHERE chat_id = @pchat) = 'private' AS type_ok,
    (SELECT COUNT(*) FROM user_chats WHERE chat_id = @pchat) = 2 AS members_count_ok,
    (SELECT COUNT(*) 
     FROM user_chats uc 
     JOIN users u ON uc.user_id = u.user_id 
     WHERE uc.chat_id = @pchat AND u.username IN ('krot', 'belka')) = 2 AS members_set_ok;

-- Тест 3. Сообщение
INSERT INTO messages (sender_id, chat_id, content) VALUES (1, @pchat, 'Привет, belka!');
SET @msg1 = LAST_INSERT_ID();
SELECT 'Сообщение' AS test,
    (SELECT content FROM messages WHERE message_id = @msg1) = 'Привет, belka!' AS content_ok,
    (SELECT username FROM users WHERE user_id = (SELECT sender_id FROM messages WHERE message_id = @msg1)) = 'krot' AS sender_ok;

-- Тест 4. Вложение
INSERT INTO attachments (message_id, file_type, file_url) VALUES (@msg1, 'image/png', 'https://ex.com/hello.png');
SELECT 'Вложение' AS test,
    (SELECT COUNT(*) FROM attachments WHERE message_id = @msg1) = 1 AS exists_ok,
    (SELECT file_type FROM attachments WHERE message_id = @msg1) = 'image/png' AS type_ok;

-- Тест 5. Группа + уведомления
INSERT INTO chats (chat_name, chat_type, created_by) VALUES ('Project Alpha', 'group', 1);
SET @gchat = LAST_INSERT_ID();
INSERT INTO user_chats (user_id, chat_id) VALUES (1, @gchat), (2, @gchat), (3, @gchat);
INSERT INTO messages (sender_id, chat_id, content) VALUES (1, @gchat, 'Всем привет!');
SET @gmsg = LAST_INSERT_ID();
INSERT INTO notifications (user_id, type, reference_id) VALUES (2, 'message', @gmsg), (3, 'message', @gmsg);
SELECT 'Группа + уведомления' AS test,
    (SELECT chat_name FROM chats WHERE chat_id = @gchat) = 'Project Alpha' AS name_ok,
    (SELECT COUNT(*) FROM user_chats WHERE chat_id = @gchat) = 3 AS members_ok,
    (SELECT COUNT(*) FROM notifications WHERE reference_id = @gmsg) = 2 AS notifs_ok;

-- Тест 6. UNIQUE дубль
INSERT IGNORE INTO user_chats (user_id, chat_id) VALUES (1, @pchat); -- первый раз (если ещё не добавлен)
INSERT IGNORE INTO user_chats (user_id, chat_id) VALUES (1, @pchat); -- второй раз — должен проигнорироваться
SELECT 'UNIQUE (user,chat)' AS test,
    (SELECT COUNT(*) FROM user_chats WHERE user_id = 1 AND chat_id = @pchat) = 1 AS only_one_record;

-- Тест 7. RESTRICT проверка
SELECT 'ON DELETE RESTRICT' AS test,
    (SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS 
     WHERE CONSTRAINT_SCHEMA = 'messenger' 
       AND REFERENCED_TABLE_NAME = 'users' 
       AND DELETE_RULE = 'RESTRICT'
       AND TABLE_NAME IN ('chats','messages')) = 2 AS count_ok;

-- Тест 8. CASCADE удаление чата
INSERT INTO chats (chat_name, chat_type, created_by) VALUES ('Temp', 'private', 1);
SET @tmp = LAST_INSERT_ID();
INSERT INTO user_chats (user_id, chat_id) VALUES (1, @tmp);
INSERT INTO messages (sender_id, chat_id, content) VALUES (1, @tmp, 'test');
SET @tmp_msg = LAST_INSERT_ID();
INSERT INTO attachments (message_id, file_type, file_url) VALUES (@tmp_msg, 'text/plain', '...');
DELETE FROM chats WHERE chat_id = @tmp;
SELECT 'ON DELETE CASCADE' AS test,
    (SELECT COUNT(*) FROM user_chats WHERE chat_id = @tmp) = 0 AS uc_gone,
    (SELECT COUNT(*) FROM messages WHERE chat_id = @tmp) = 0 AS msg_gone,
    (SELECT COUNT(*) FROM attachments WHERE message_id = @tmp_msg) = 0 AS att_gone;

-- Тест 9. Soft-delete
UPDATE users SET is_deleted = TRUE WHERE username = 'enot';
UPDATE messages SET is_deleted = TRUE WHERE message_id = @msg1;
SELECT 'Soft-delete' AS test,
    (SELECT is_deleted FROM users WHERE username = 'enot') = 1 AS enot_deleted,
    (SELECT is_deleted FROM messages WHERE message_id = @msg1) = 1 AS msg_deleted;

-- Тест 10. Индексы
SELECT 'Индексы существуют' AS test,
    (SELECT COUNT(*) FROM information_schema.STATISTICS 
     WHERE TABLE_SCHEMA = 'messenger' 
       AND TABLE_NAME = 'messages' 
       AND INDEX_NAME = 'idx_messages_chat') = 1 AS idx_chat_ok,
    (SELECT COUNT(*) FROM information_schema.STATISTICS 
     WHERE TABLE_SCHEMA = 'messenger' 
       AND TABLE_NAME = 'messages' 
       AND INDEX_NAME = 'idx_messages_sender') = 1 AS idx_sender_ok,
    (SELECT COUNT(*) FROM information_schema.STATISTICS 
     WHERE TABLE_SCHEMA = 'messenger' 
       AND TABLE_NAME = 'user_chats' 
       AND INDEX_NAME = 'idx_user_chats_user') = 1 AS idx_uc_user_ok,
    (SELECT COUNT(*) FROM information_schema.STATISTICS 
     WHERE TABLE_SCHEMA = 'messenger' 
       AND TABLE_NAME = 'attachments' 
       AND INDEX_NAME = 'idx_attach_msg') = 1 AS idx_att_ok,
	(SELECT COUNT(*) FROM information_schema.STATISTICS 
     WHERE TABLE_SCHEMA = 'messenger' 
       AND TABLE_NAME = 'notifications' 
       AND INDEX_NAME = 'idx_notifications_user') = 1 AS idx_notif_user_ok;
       
-- Тест 11. ON UPDATE CASCADE (метаданные)
SELECT 'ON UPDATE CASCADE' AS test,
    (SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS 
     WHERE CONSTRAINT_SCHEMA = 'messenger'
       AND REFERENCED_TABLE_NAME = 'users'
       AND UPDATE_RULE = 'CASCADE'
       AND TABLE_NAME IN ('chats', 'messages')) = 2 AS count_ok;
    
-- Тест 12. ENUM валидация (универсальный)
INSERT IGNORE INTO chats (chat_name, chat_type, created_by) 
VALUES ('BadChat', 'invalid_type', 1);
SET @bad_id = LAST_INSERT_ID();

SELECT 'ENUM валидация' AS test,
    (SELECT COUNT(*) FROM chats WHERE chat_id = @bad_id 
       AND chat_type NOT IN ('private', 'group') 
       AND chat_type != 'invalid_type') = 1 AS rejected_ok;
    
-- Тест 13. last_message_at обновление
UPDATE chats SET last_message_at = '2020-01-01 00:00:00' WHERE chat_id = @gchat;
SET @before = (SELECT last_message_at FROM chats WHERE chat_id = @gchat);
UPDATE chats SET last_message_at = NOW() WHERE chat_id = @gchat;

SELECT 'last_message_at' AS test,
    (SELECT last_message_at FROM chats WHERE chat_id = @gchat) > @before AS updated_ok;