CREATE DATABASE IF NOT EXISTS messenger;
USE messenger;

DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS attachments;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS user_chats;
DROP TABLE IF EXISTS chats;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,

    -- Имя отображаемое в системе
    username VARCHAR(50) NOT NULL UNIQUE,

    password_hash TEXT NOT NULL,

    avatar_url TEXT,

    -- Пользователь может "удалить себя" — soft delete
    is_deleted BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE chats (
    chat_id INT AUTO_INCREMENT PRIMARY KEY,

    chat_name VARCHAR(100),

    chat_type ENUM('private', 'group') NOT NULL,

    created_by INT NOT NULL,

    -- Для сортировки списка чатов по активности
    last_message_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (created_by)
        REFERENCES users(user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE user_chats (
    user_chat_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,
    chat_id INT NOT NULL,

    -- Минимальная ролевая модель
    role ENUM('member', 'admin') DEFAULT 'member',

    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY (user_id, chat_id),

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (chat_id)
        REFERENCES chats(chat_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,

    sender_id INT NOT NULL,
    chat_id INT NOT NULL,

    -- Тип сообщения
    message_type ENUM('text', 'image', 'file') DEFAULT 'text',

    -- Текст (если text message)
    content TEXT,

    -- Можно скрывать удалённые сообщения
    is_deleted BOOLEAN DEFAULT FALSE,

    status ENUM('sent', 'delivered', 'read') DEFAULT 'sent',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (chat_id)
        REFERENCES chats(chat_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE attachments (
    attachment_id INT AUTO_INCREMENT PRIMARY KEY,

    message_id INT NOT NULL,

    file_type VARCHAR(50) NOT NULL,
    file_url TEXT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (message_id)
        REFERENCES messages(message_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    type ENUM('message', 'invitation', 'reaction') NOT NULL,

    status ENUM('unread', 'read') DEFAULT 'unread',

    reference_id INT NULL,  -- например id сообщения или чата

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_messages_chat       ON messages(chat_id);
CREATE INDEX idx_messages_sender     ON messages(sender_id);
CREATE INDEX idx_user_chats_user     ON user_chats(user_id);
CREATE INDEX idx_notifications_user  ON notifications(user_id);
CREATE INDEX idx_attach_msg          ON attachments(message_id);
