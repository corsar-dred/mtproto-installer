# 🚀 MTProto Telegram Proxy (Docker + Fake-TLS Auto-installer)

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Bash](https://img.shields.io/badge/shell-bash-%234EAA25.svg?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Telegram](https://img.shields.io/badge/telegram-blue?style=flat&logo=telegram&logoColor=white)](https://telegram.org)

Интерактивный Bash-скрипт для быстрой установки официального прокси-сервера **MTProto** для Telegram в Docker-контейнере с автоматической маскировкой под **Fake-TLS (префикс `ee`)** для обхода блокировок и систем глубокого анализа пакетов (DPI).

---

## ✨ Особенности скрипта
* **Полная автоматизация**: Скрипт сам проверит наличие Docker и установит его при необходимости.
* **Умное определение IP**: Автоматически определяет внешний IP-адрес вашего сервера.
* **Кастомный порт**: Возможность задать любой удобный порт (по умолчанию `2053`).
* **Защита от DPI**: Автоматически извлекает сгенерированный секрет из логов Docker и добавляет префикс `ee` (Fake-TLS).
* **Готовые ссылки**: На выходе генерирует кликабельные ссылки `https://t.me/...` и `tg://...` для быстрой настройки на телефоне или компьютере.

---

## 🛠 Быстрый запуск на сервере

Вам не нужно вручную скачивать или создавать файлы. Просто подключитесь к вашему серверу под учётной записью `root` и запустите команду установки в одну строчку:

```bash
curl -sL https://raw.githubusercontent.com/corsar-dred/mtproto-installer/main/deploy_mtproto.sh https://raw.githubusercontent.com/corsar-dred/mtproto-installer/main/deploy_mtproto.sh -o deploy_mtproto.sh && chmod +x deploy_mtproto.sh && ./deploy_mtproto.sh

---

## Второй вариант с добавлением выбора сервера SNI и выводом ссылки MTProto для IPhone

```bash
curl -sL https://raw.githubusercontent.com/corsar-dred/mtproto-installer/main/deploy_mtproto-1.sh -o deploy_mtproto-1.sh && chmod +x deploy_mtproto-1.sh && ./deploy_mtproto-1.sh

