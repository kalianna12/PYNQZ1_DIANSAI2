#!/bin/sh
set -eu

APP_DIR=/home/xilinx/base_add
SERVICE_NAME=pynq-max5885-uart.service

for file in base_add.bit base_add.hwh pynqz1_diansai2_max5885.py max5885_uart_listener_service.py; do
    if [ ! -f "$APP_DIR/$file" ]; then
        echo "Missing $APP_DIR/$file"
        exit 1
    fi
done

sudo install -m 0644 "$APP_DIR/$SERVICE_NAME" "/etc/systemd/system/$SERVICE_NAME"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"
sudo systemctl --no-pager --full status "$SERVICE_NAME"

