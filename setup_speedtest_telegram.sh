#!/bin/bash

# 📌 Проверка и установка зависимостей
install_dependency() {
    local DEP_NAME=$1
    local INSTALL_CMD=$2

    if ! command -v "$DEP_NAME" &> /dev/null; then
        echo "❌ $DEP_NAME не установлен. Устанавливаю..."
        eval "$INSTALL_CMD"
        if ! command -v "$DEP_NAME" &> /dev/null; then
            echo "❌ Ошибка при установке $DEP_NAME. Завершаем."
            exit 1
        fi
        echo "✅ $DEP_NAME успешно установлен."
    else
        echo "✅ $DEP_NAME уже установлен."
    fi
}

# 📌 Установка зависимостей
install_dependency "jq" "sudo apt update && sudo apt install jq -y"
install_dependency "speedtest" "sudo apt update && sudo apt install speedtest-cli -y"
install_dependency "qrencode" "sudo apt update && sudo apt install qrencode -y"

# 📌 Запрос ID сервера
read -p "Введите ID сервера для замера: " SERVER_ID

# Проверка ввода
if [[ -z "$SERVER_ID" ]]; then
    echo "❌ ID сервера не может быть пустым. Попробуйте снова."
    exit 1
fi

# 📌 Инициализация переменных
TOTAL_DOWNLOAD=0
TOTAL_UPLOAD=0
TOTAL_PING=0
NUM_TESTS=3
SUCCESS_TESTS=0

# 📌 Три замера скорости
for i in {1..3}; do
    echo -e "\n🟦======================= [ Тест #$i ] ======================="
    OUTPUT=$(speedtest -s "$SERVER_ID" --format=json 2>/dev/null)
    
    if [ -z "$OUTPUT" ]; then
        echo "❌ Ошибка во время теста #$i. Пропускаем."
        continue
    fi

    DOWNLOAD=$(echo "$OUTPUT" | jq -r '.download.bandwidth')
    UPLOAD=$(echo "$OUTPUT" | jq -r '.upload.bandwidth')
    PING=$(echo "$OUTPUT" | jq -r '.ping.latency')

    if [[ -z "$DOWNLOAD" || -z "$UPLOAD" || -z "$PING" ]]; then
        echo "❌ Некорректные данные от сервера на тесте #$i. Пропускаем."
        continue
    fi

    DOWNLOAD_MBPS=$(echo "scale=2; $DOWNLOAD / 125000" | bc)
    UPLOAD_MBPS=$(echo "scale=2; $UPLOAD / 125000" | bc)
    PING_MS=$(echo "scale=2; $PING" | bc)

    echo -e "📥 Download: \e[1;32m$DOWNLOAD_MBPS Mbps\e[0m"
    echo -e "📤 Upload: \e[1;34m$UPLOAD_MBPS Mbps\e[0m"
    echo -e "📡 Ping: \e[1;33m$PING_MS ms\e[0m"

    TOTAL_DOWNLOAD=$(echo "$TOTAL_DOWNLOAD + $DOWNLOAD" | bc)
    TOTAL_UPLOAD=$(echo "$TOTAL_UPLOAD + $UPLOAD" | bc)
    TOTAL_PING=$(echo "$TOTAL_PING + $PING" | bc)
    SUCCESS_TESTS=$((SUCCESS_TESTS + 1))
done

# 📌 Проверка успешности тестов
if [ "$SUCCESS_TESTS" -eq 0 ]; then
    echo "❌ Не удалось получить данные с сервера. Проверьте ID сервера и попробуйте снова."
    exit 1
fi

# 📌 Рассчёт средних значений
AVG_DOWNLOAD=$(echo "scale=2; $TOTAL_DOWNLOAD / $SUCCESS_TESTS / 125000" | bc)
AVG_UPLOAD=$(echo "scale=2; $TOTAL_UPLOAD / $SUCCESS_TESTS / 125000" | bc)
AVG_PING=$(echo "scale=2; $TOTAL_PING / $SUCCESS_TESTS" | bc)

# 📌 Финальный результат
echo -e "\n🟩===================== [ ИТОГОВЫЙ РЕЗУЛЬТАТ ] ====================="
echo -e "📊 Средняя скорость скачивания: \e[1;32m$AVG_DOWNLOAD Mbps\e[0m"
echo -e "📊 Средняя скорость загрузки: \e[1;34m$AVG_UPLOAD Mbps\e[0m"
echo -e "📊 Средний Ping: \e[1;33m$AVG_PING ms\e[0m"
echo -e "🟩===============================================================\n"

# 📌 Ссылка на хостинг с бонусом
HOSTING_LINK="http://vk.cc/czDwwy"
echo -e "🌟 \e[1;36mРекомендуемый хостинг с высокой скоростью и бонусом +15% к пополнению:\e[0m"
echo -e "🔗 \e[1;36m$HOSTING_LINK\e[0m"
echo -e "🔗 \e[1;36m$HOSTING_LINK\e[0m"
echo -e "🔗 \e[1;36m$HOSTING_LINK\e[0m"

# 📌 Генерация QR-кода для ссылки
echo -e "\n📲 QR-код для быстрого доступа к ссылке:"
qrencode -o qr_hosting.png -t ANSIUTF8 "$HOSTING_LINK"
cat qr_hosting.png

echo -e "\n✅ \e[1;32mТест завершён! Скопируйте ссылку или используйте QR-код для быстрого перехода.\e[0m"

