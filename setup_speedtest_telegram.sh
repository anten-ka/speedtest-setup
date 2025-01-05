#!/bin/bash

# ========================== #
# 📌 Проверка зависимостей   #
# ========================== #

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

# ============================= #
# 📌 Удаление старого Speedtest #
# ============================= #

remove_old_speedtest() {
    if command -v speedtest-cli &> /dev/null; then
        echo "🛠️ Удаляем устаревший speedtest-cli..."
        sudo apt remove --purge speedtest-cli -y
        sudo apt autoremove -y
        rm -f /usr/local/bin/speedtest
        rm -f /usr/bin/speedtest
    fi
}

# ============================== #
# 📌 Установка Speedtest CLI     #
# ============================== #

install_speedtest() {
    if ! command -v speedtest &> /dev/null || ! speedtest --version | grep -q "Speedtest by Ookla"; then
        echo "🛠️ Устанавливаем официальную версию Ookla Speedtest CLI..."
        wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
        tar -xvf ookla-speedtest-1.2.0-linux-x86_64.tgz
        chmod +x speedtest
        sudo mv speedtest /usr/local/bin/speedtest
        rm -f ookla-speedtest-1.2.0-linux-x86_64.tgz
    fi

    # 📌 Подтверждение условий использования
    echo "✅ Подтверждаем условия использования Speedtest CLI..."
    echo "YES" | speedtest --accept-license --accept-gdpr > /dev/null 2>&1

    echo "✅ Speedtest установлен и готов к использованию:"
    speedtest --version
}

# ============================= #
# 📌 Проверка зависимостей      #
# ============================= #

install_dependency "jq" "sudo apt update && sudo apt install jq -y"
install_dependency "qrencode" "sudo apt update && sudo apt install qrencode -y"

# 📌 Удаляем старую версию и устанавливаем новую
remove_old_speedtest
install_speedtest

# ======================== #
# 📌 Запрос ID сервера     #
# ======================== #

read -p "Введите ID сервера для замера: " SERVER_ID

if [[ -z "$SERVER_ID" ]]; then
    echo "❌ ID сервера не может быть пустым. Попробуйте снова."
    exit 1
fi

# ============================ #
# 📌 Инициализация переменных  #
# ============================ #

TOTAL_DOWNLOAD=0
TOTAL_UPLOAD=0
TOTAL_PING=0
NUM_TESTS=3
SUCCESS_TESTS=0

# ======================== #
# 📌 Три замера скорости   #
# ======================== #

for i in {1..3}; do
    echo -e "\n🟦======================= [ Тест #$i ] ======================="
    OUTPUT=$(speedtest -s "$SERVER_ID" --format=json 2>/dev/null)
    
    if [ -z "$OUTPUT" ]; then
        echo "❌ Ошибка во время теста #$i. Сервер с ID $SERVER_ID может быть недоступен."
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

# ============================ #
# 📌 Рассчёт средних значений  #
# ============================ #

if [[ $SUCCESS_TESTS -gt 0 ]]; then
    AVG_DOWNLOAD=$(echo "scale=2; $TOTAL_DOWNLOAD / $SUCCESS_TESTS / 125000" | bc)
    AVG_UPLOAD=$(echo "scale=2; $TOTAL_UPLOAD / $SUCCESS_TESTS / 125000" | bc)
    AVG_PING=$(echo "scale=2; $TOTAL_PING / $SUCCESS_TESTS" | bc)
else
    AVG_DOWNLOAD=0
    AVG_UPLOAD=0
    AVG_PING=0
fi

# ============================ #
# 📌 Рекламный блок с QR-кодом #
# ============================ #

echo -e "\n🟦===================== [ 🚀 РЕКОМЕНДУЕМЫЙ ХОСТИНГ ] ====================="
echo -e "🌐 Быстрый VPS-хостинг с бонусом +15% при пополнении!"
echo -e "🔗 Ссылка: \e[1;34mhttp://vk.cc/czDwwy\e[0m"
echo -e "🔗 Ссылка: \e[1;34mhttp://vk.cc/czDwwy\e[0m"
echo -e "🔗 Ссылка: \e[1;34mhttp://vk.cc/czDwwy\e[0m"

qrencode -t ANSI256 "http://vk.cc/czDwwy"
echo -e "🟩====================================================================\n"

exit 0
