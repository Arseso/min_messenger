## Логи тестирования

| Файл | Описание |
|------|----------|
| `backend_startup.log` | Запуск бэкенда **до** установки `websockets` — 404 на WS |
| `backend_with_websockets.log` | После установки `websockets==15.0.1` — соединение принимается, но падает в CRUD |
| `flutter_web_startup.log` | Запуск Flutter Web — ошибка подключения к WS |
| `ui_offline_behavior.log` | Поведение UI при отключённом бэкенде |

Все логи очищены от дублей и технического мусора.