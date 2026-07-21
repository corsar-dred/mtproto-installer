#!/bin/bash

# ==============================================================================
# Скрипт автоматической установки MTProto Proxy (Official Docker + Fake-TLS)
# ==============================================================================

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================================${NC}"
echo -e "${CYAN}    Автоматическая установка MTProto Telegram Proxy (Docker)${NC}"
echo -e "${BLUE}==================================================================${NC}"

# Проверка прав суперпользователя
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Ошибка: Пожалуйста, запустите скрипт с правами sudo/root.${NC}"
  exit 1
fi

# 1. Проверка и установка Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker не найден. Устанавливаем Docker...${NC}"
    apt-get update -y && apt-get install -y curl xxd
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    echo -e "${GREEN}Docker успешно установлен!${NC}"
else
    echo -e "${GREEN}Docker уже установлен.${NC}"
fi

if ! command -v xxd &> /dev/null; then
    apt-get update -y && apt-get install -y xxd
fi

# 2. Определение внешнего IP-адреса сервера
DEFAULT_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
echo -e "\n${CYAN}Шаг 1: Определение IP-адреса сервера${NC}"
read -p "Введите IP-адрес сервера [по умолчанию: $DEFAULT_IP]: " SERVER_IP
SERVER_IP=${SERVER_IP:-$DEFAULT_IP}

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Не удалось автоматически определить IP. Пожалуйста, укажите его вручную.${NC}"
    read -p "Введите IP-адрес сервера: " SERVER_IP
fi

# 3. Определение порта
echo -e "\n${CYAN}Шаг 2: Настройка порта${NC}"
read -p "Введите порт для прокси [по умолчанию: 2053]: " PORT
PORT=${PORT:-2053}

# Проверка, не занят ли порт
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Предупреждение: Порт $PORT уже используется другим процессом!${NC}"
    read -p "Вы хотите продолжить или ввести другой порт? [y/новый_порт]: " PORT_CHOICE
    if [[ "$PORT_CHOICE" =~ ^[0-9]+$ ]]; then
        PORT=$PORT_CHOICE
    fi
fi

# 3.1. Домен для маскировки трафика (SNI / Fake-TLS)
echo -e "\n${CYAN}Шаг 2.1: Домен для маскировки (SNI)${NC}"
echo -e "Этот домен будет 'зашит' в секрет — при DPI-проверке трафик будет выглядеть как HTTPS к этому сайту."
read -p "Введите домен для маскировки [по умолчанию: www.google.com]: " SNI_DOMAIN
SNI_DOMAIN=${SNI_DOMAIN:-www.google.com}

# 4. Удаление старого контейнера с таким именем, если он существует
if [ "$(docker ps -aq -f name=tg_proxy)" ]; then
    echo -e "\n${YELLOW}Обнаружен существующий контейнер 'tg_proxy'. Перезаписываем...${NC}"
    docker rm -f tg_proxy >/dev/null
fi

# 5. Запуск Docker-контейнера
echo -e "\n${CYAN}Шаг 3: Запуск официального контейнера MTProto...${NC}"
docker run -d --name tg_proxy --restart always -p "$PORT":443 telegrammessenger/proxy:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка запуска Docker-контейнера!${NC}"
    exit 1
fi

# Даем контейнеру немного времени на генерацию ключей
echo -e "Ожидание генерации секретного ключа контейнером..."
sleep 3

# 6. Получение сгенерированного секрета из логов контейнера
RAW_SECRET=$(docker logs tg_proxy 2>&1 | grep -oE "An/or secret: [0-9a-fA-F]{32}" | awk '{print $NF}')

if [ -z "$RAW_SECRET" ]; then
    # Альтернативный способ парсинга логов
    RAW_SECRET=$(docker logs tg_proxy 2>&1 | grep -oE '[0-9a-fA-F]{32}' | head -n 1)
fi

if [ -z "$RAW_SECRET" ]; then
    echo -e "${RED}Не удалось автоматически прочитать секрет из логов контейнера.${NC}"
    read -p "Введите кастомный 32-значный hex-секрет (или оставьте пустым для генерации случайного): " MANUAL_SECRET
    if [ -z "$MANUAL_SECRET" ]; then
        RAW_SECRET=$(openssl rand -hex 16)
        echo -e "Сгенерирован случайный секрет: $RAW_SECRET"
    else
        RAW_SECRET=$MANUAL_SECRET
    fi
fi

# Автоматически подставляем префикс ee для защиты от систем DPI (Fake-TLS)
FAKE_TLS_SECRET="ee$RAW_SECRET"

# Hex-кодирование домена и формирование "полного" секрета с зашитым доменом
# Формат: ee + 32 hex символа секрета + hex домена. Такой секрет длиннее и
# именно его нужно использовать на iPhone/iOS, где короткий ee-секрет
# без домена может не устанавливать Fake-TLS соединение.
DOMAIN_HEX=$(echo -n "$SNI_DOMAIN" | xxd -ps | tr -d '\n')
FULL_SECRET="ee${RAW_SECRET}${DOMAIN_HEX}"

# 7. Генерация ссылок для подключения к Telegram
TG_LINK="https://t.me/proxy?server=${SERVER_IP}&port=${PORT}&secret=${FAKE_TLS_SECRET}"
TG_SCHEME_LINK="tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${FAKE_TLS_SECRET}"

# Отдельная ссылка с более длинным секретом (домен зашит внутри) — для iPhone/iOS
TG_LINK_IOS="https://t.me/proxy?server=${SERVER_IP}&port=${PORT}&secret=${FULL_SECRET}"
TG_SCHEME_LINK_IOS="tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${FULL_SECRET}"

# Вывод результатов работы
echo -e "\n${GREEN}==================================================================${NC}"
echo -e "${GREEN}        MTProto Proxy успешно установлен и запущен!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "${YELLOW}Параметры подключения:${NC}"
echo -e "  • IP сервера:      ${CYAN}$SERVER_IP${NC}"
echo -e "  • Порт:            ${CYAN}$PORT${NC}"
echo -e "  • Исходный секрет: ${CYAN}$RAW_SECRET${NC}"
echo -e "  • Секрет Fake-TLS: ${CYAN}$FAKE_TLS_SECRET${NC}"
echo -e "  • Домен маскировки (SNI): ${CYAN}$SNI_DOMAIN${NC}"
echo -e "  • Секрет с доменом (для iPhone): ${CYAN}$FULL_SECRET${NC}"
echo -e "  • Имя контейнера:  ${CYAN}tg_proxy${NC}"
echo -e "\n${YELLOW}Основные ссылки (Android/Desktop):${NC}"
echo -e "  👉 ${GREEN}$TG_LINK${NC}"
echo -e "  👉 ${GREEN}$TG_SCHEME_LINK${NC}"
echo -e "\n${YELLOW}Ссылки для iPhone/iOS (секрет длиннее, с зашитым доменом):${NC}"
echo -e "  👉 ${GREEN}$TG_LINK_IOS${NC}"
echo -e "  👉 ${GREEN}$TG_SCHEME_LINK_IOS${NC}"
echo -e "\n${YELLOW}Полезные команды:${NC}"
echo -e "  Посмотреть логи:      ${CYAN}docker logs tg_proxy${NC}"
echo -e "  Перезапустить прокси: ${CYAN}docker restart tg_proxy${NC}"
echo -e "  Остановить прокси:    ${CYAN}docker stop tg_proxy${NC}"
echo -e "${GREEN}==================================================================${NC}"
