#!/bin/bash

echo "Начало установки и настройки Node Exporter."

# Путь к каталогу для распаковки
TEMP_DIR="/tmp/node_exporter_install"

# Путь к каталогу для бинарного файла Node Exporter
NODE_EXPORTER_BIN_DIR="/usr/local/bin"

# Путь к каталогу для systemd службы
SYSTEMD_DIR="/etc/systemd/system"

# Название службы
SERVICE_NAME="node_exporter"

# Проверяем, установлена ли служба Node Exporter
if systemctl status $SERVICE_NAME &> /dev/null; then
    # Если служба установлена, останавливаем её
    echo "Остановка службы Node Exporter..."
    sudo systemctl stop $SERVICE_NAME

    # Удаляем службу Node Exporter
    echo "Удаление службы Node Exporter..."
    sudo systemctl disable $SERVICE_NAME
    sudo rm -f $SYSTEMD_DIR/$SERVICE_NAME.service
fi

# URL для загрузки Node Exporter
NODE_EXPORTER_DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v1.8.0/node_exporter-1.8.0.linux-amd64.tar.gz"

echo "Создание временного каталога: $TEMP_DIR"
mkdir -p $TEMP_DIR

# Скачивание и распаковка Node Exporter
echo "Скачивание и распаковка Node Exporter..."
wget -q $NODE_EXPORTER_DOWNLOAD_URL -O $TEMP_DIR/node_exporter.tar.gz
tar -xzf $TEMP_DIR/node_exporter.tar.gz -C $TEMP_DIR

# Копирование исполняемого файла в каталог bin
echo "Копирование исполняемого файла в каталог bin: $NODE_EXPORTER_BIN_DIR"
sudo cp $TEMP_DIR/node_exporter-1.8.0.linux-amd64/node_exporter $NODE_EXPORTER_BIN_DIR

# Создание файла службы
echo "Создание файла службы: $SYSTEMD_DIR/$SERVICE_NAME.service"
echo "[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=$NODE_EXPORTER_BIN_DIR/node_exporter --collector.processes --collector.systemd 

[Install]
WantedBy=multi-user.target" | sudo tee $SYSTEMD_DIR/$SERVICE_NAME.service > /dev/null

# Перезагрузка systemd
echo "Перезагрузка systemd..."
sudo systemctl daemon-reload

# Включение службы Node Exporter
echo "Включение службы Node Exporter..."
sudo systemctl enable $SERVICE_NAME

# Запуск службы Node Exporter
echo "Запуск службы Node Exporter..."
sudo systemctl start $SERVICE_NAME

# Очистка временных файлов
echo "Очистка временных файлов..."
rm -rf $TEMP_DIR

echo "Установка и настройка Node Exporter завершены."