# План: API Smoke Testing  
**Цель**: проверить базовую работоспособность API.

**Объект тестирования**:  
- `POST /register`, `POST /login`  
- `POST /chats/create`, `GET /chats/{user_id}`  
- `POST /messages/send`, `GET /messages/{chat_id}`  

**Критерии успеха**:  
- ✅ Все основные сценарии возвращают `200 OK`,  
- ✅ Ошибки ввода → `4xx`, не `500`,  
- ✅ Данные корректно сохраняются в БД.  

**Выходные данные**:  
- `api_smoke_test_report.md` — результаты,  
- Рекомендации по улучшению API.