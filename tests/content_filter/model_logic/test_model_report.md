# Тестирование логики модели ContentFilter

| ID | Текст | Ожидаемо | Фактически | Результат |
|----|-------|----------|-------------|-----------|
| `ok_01` | `Спасибо` | `OK` | `OK` | PASSED |
| `ok_02` | `Да` | `OK` | `OK` | PASSED |
| `ok_03` | `Нет` | `OK` | `OK` | PASSED |
| `ok_04` | `Можно?` | `OK` | `OK` | PASSED |
| `ok_05` | `Хорошо` | `OK` | `OK` | PASSED |
| `ok_06` | `Отлично` | `OK` | `OK` | PASSED |
| `ok_07` | `Пожалуйста` | `OK` | `OK` | PASSED |
| `ok_08` | `Спасибо большое` | `OK` | `OK` | PASSED |
| `ok_09` | `Вы молодец` | `OK` | `OK` | PASSED |
| `ok_10` | `Мне нравится` | `OK` | `OK` | PASSED |
| `ok_11` | `Хорошая погода сегодня` | `OK` | `OK` | PASSED |
| `spam_01` | `Купи курс всего за 1000 р...` | `SPAM` | `SPAM` | PASSED |
| `spam_02` | `t.me/fake` | `SPAM` | `SPAM` | PASSED |
| `spam_03` | `bit.ly/zxc` | `SPAM` | `SPAM` | PASSED |
| `spam_04` | `Переведи 500, верну завтр...` | `SPAM` | `SPAM` | PASSED |
| `spam_05` | `Подпишись на канал` | `SPAM` | `SPAM` | PASSED |
| `spam_06` | `Выиграй айфон! Жми →` | `SPAM` | `SPAM` | PASSED |
| `spam_07` | `Бесплатно! Только сегодня` | `SPAM` | `SPAM` | PASSED |
| `spam_08` | `Срочно! Ваш счёт заблокир...` | `SPAM` | `SPAM` | PASSED |
| `spam_09` | `Free iPhone! bit.ly/fake` | `SPAM` | `SPAM` | PASSED |
| `spam_10` | `Get rich quick! t.me/scam` | `SPAM` | `SPAM` | PASSED |
| `spam_12` | `Ваш заказ готов. Оплатите...` | `SPAM` | `SPAM` | PASSED |
| `toxic_01` | `Дурак` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_02` | `Иди нахер` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_03` | `Тварь` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_04` | `Сдохни` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_05` | `Гнида` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_06` | `Ёб*ный` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_07` | `Ты ничего не понимаешь` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_08` | `Заткнись` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_09` | `Ты реально думаешь, что э...` | `TOXIC` | `TOXIC` | PASSED |
| `toxic_10` | `Yебаn` | `TOXIC` | `TOXIC` | PASSED |
| `edge_01` | ` ` | `OK` | `OK` | PASSED |
| `edge_02` | `...` | `OK` | `OK` | PASSED |
| `edge_03` | `123` | `OK` | `OK` | PASSED |
| `edge_04` | `OK` | `OK` | `OK` | PASSED |
| `edge_05` | `спасибо, лох` | `TOXIC` | `TOXIC` | PASSED |
| `edge_06` | `хорошо, мудила` | `TOXIC` | `TOXIC` | PASSED |
| `edge_07` | `спам` | `OK` | `TOXIC` | FAILED |
| `edge_08` | `toxic` | `OK` | `OK` | PASSED |
| `edge_09` | `е` | `OK` | `OK` | PASSED |
| `edge_10` | `з` | `OK` | `OK` | PASSED |
| `soft_spam_01` | `Звони по номеру` | `SPAM` | `SPAM` | PASSED |
| `soft_spam_02` | `Скинь почту` | `SPAM` | `SPAM` | PASSED |
| `soft_spam_03` | `Я знаю, как увеличить про...` | `SPAM` | `SPAM` | PASSED |
| `soft_spam_04` | `Марина, 200 метров от вас` | `SPAM` | `TOXIC` | FAILED |
| `soft_spam_05` | `Напиши в телегу @fake""` | `SPAM` | `SPAM` | PASSED |
| `soft_spam_06` | `Ваш заказ №023 ждёт оплат...` | `SPAM` | `SPAM` | PASSED |
| `sarc_01` | `Какая умная мысль, браво` | `TOXIC` | `OK` | FAILED |
| `sarc_02` | `Ты гений, конечно` | `TOXIC` | `TOXIC` | PASSED |
| `sarc_03` | `Опять ты блистаешь` | `TOXIC` | `TOXIC` | PASSED |
| `sarc_04` | `Молодец, что додумался` | `TOXIC` | `TOXIC` | PASSED |
| `sarc_05` | `Конечно, верю` | `TOXIC` | `OK` | FAILED |
| `neutral_toxic_01` | `Слово 'дурак' происходит ...` | `OK` | `TOXIC` | FAILED |
| `neutral_toxic_02` | `В словаре есть слово 'муд...` | `OK` | `TOXIC` | FAILED |
| `neutral_toxic_03` | `Фильм 'Бесславные ублюдки...` | `OK` | `OK` | PASSED |
| `mix_01` | `Привет, how are you?` | `OK` | `SPAM` | FAILED |
| `mix_02` | `Buy курс за $1` | `SPAM` | `SPAM` | PASSED |
| `mix_03` | `Ты такой dumb` | `TOXIC` | `SPAM` | FAILED |
| `mix_04` | `Спасибо, thx` | `OK` | `SPAM` | FAILED |
| `long_01` | `Этот текст представляет с...` | `OK` | `OK` | PASSED |
| `long_02` | `Этот текст — просто кусок...` | ` TOXIC` | `TOXIC` | FAILED |

Итого: 52 / 62
Точность: 83%
Результат: требуется анализ ошибок.
