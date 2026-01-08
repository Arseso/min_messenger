# Отчёт: UI Testing (Android)

## Статус тестирования
**Тестирование не выполнено** из-за технической ошибки ADB.

## Детали
- Попытка запуска через **Android Emulator** (Pixel 4, API 31) завершилась ошибкой:  
  `The emulator process for AVD Pixel_4 has terminated`.  
  Причина: конфликт гипервизоров Windows (Hyper-V / WHPX vs Intel HAXM), не разрешённый после отключения `VirtualMachinePlatform`.
- Попытка запуска на **реальном устройстве**. 

### Что было сделано:
- Включён «Режим разработчика» на устройстве,  
- Активирована «Отладка по USB»,  
- Подтверждено разрешение на подключение при появлении запроса,  
- Выполнены команды:
  ```bash
  flutter devices  # → показывает устройство как "unauthorized"
  adb kill-server && adb start-server

**Ошибка:** 
adb.exe: device unauthorized.
This adb server's $ADB_VENDOR_KEYS is not set