#!/bin/bash

echo "Начало установки и настройки Promtail."

# Адрес сервера Loki
LOKI_SERVER_URL="192.168.20.96"

# Путь к исполняемому файлу Promtail
PROMTAIL_BINARY_PATH="/usr/local/bin/promtail-linux-amd64"

# URL для загрузки Promtail
PROMTAIL_DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/v2.9.8/promtail-linux-amd64.zip"

# Путь к каталогу для распаковки
TEMP_DIR="/tmp/promtail_install"

# Путь к каталогу для файла конфигурации
CONFIG_DIR="/etc/loki"
CONFIG_FILE="$CONFIG_DIR/promtail_config.yml"

echo "Проверка наличия и остановка службы Promtail, если она существует и запущена."

# Проверка наличия и остановка службы Promtail, если она существует и запущена
if sudo systemctl status promtail >/dev/null 2>&1; then
    echo "Служба Promtail уже существует и запущена. Остановка службы..."
    sudo systemctl stop promtail
else
    echo "Служба Promtail не найдена."
fi

# Создание временного каталога
echo "Создание временного каталога: $TEMP_DIR"
mkdir -p $TEMP_DIR

# Скачивание и распаковка Promtail
echo "Скачивание и распаковка Promtail..."
wget -q $PROMTAIL_DOWNLOAD_URL -O $TEMP_DIR/promtail.zip
unzip -q $TEMP_DIR/promtail.zip -d $TEMP_DIR

# Копирование исполняемого файла в каталог bin
echo "Копирование исполняемого файла в каталог bin: $PROMTAIL_BINARY_PATH"
sudo cp $TEMP_DIR/promtail-linux-amd64 $PROMTAIL_BINARY_PATH

# Создание каталога для конфигурации, если его нет
echo "Создание каталога для конфигурации, если его нет: $CONFIG_DIR"
sudo mkdir -p $CONFIG_DIR

# Создание файла конфигурации
echo "Создание файла конфигурации: $CONFIG_FILE"
echo "server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://$LOKI_SERVER_URL:3100/loki/api/v1/push

scrape_configs:
  - job_name: systemd_journal
    journal:
      max_age: 24h
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'systemd'  
" | sudo tee $CONFIG_FILE > /dev/null

# Создание файла службы
echo "Создание файла службы: /etc/systemd/system/promtail.service"
echo "[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/usr/local/bin/
ExecStart=$PROMTAIL_BINARY_PATH -config.file=$CONFIG_FILE
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/promtail.service > /dev/null

# Перезагрузка systemd
echo "Перезагрузка systemd..."
sudo systemctl daemon-reload

# Включение службы Promtail
echo "Включение службы Promtail..."
sudo systemctl enable promtail

# Запуск службы Promtail
echo "Запуск службы Promtail..."
sudo systemctl start promtail

# Очистка временных файлов
echo "Очистка временных файлов..."
rm -rf $TEMP_DIR

echo "Установка и настройка Promtail завершены."
