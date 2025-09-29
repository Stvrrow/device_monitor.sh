#!/bin/bash

input_dir="/proc/bus/input"
table_file="input_devices.txt"
log_file="input_devices_log.log"


#Проверка на root права
if [[ $EUID -ne 0 ]]; then
    echo "Скрипт должен быть запущен с правами root."
    exit 1
fi

# Функция для логирования ошибок
log_error() {
    local msg="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $msg" >> "$log_file"
}

# Таблица со всеми устройствами
{
    echo "Права Ссылки Владелец Группа Размер Имя"
    for item in "$input_dir"/*; do
        info=$(ls -ld "$item" 2>/dev/null)
        [ -n "$info" ] || continue
        echo "$info" | awk -v name="$(basename "$item")" '{print $1,$2,$3,$4,$5,name}'
    done
} | column -t > "$table_file"

# Логирование
# Список всех текущих устройств
current=$(find "$input_dir" -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null | sort)

touch "$log_file"

# Проходим по каждому устройству и логируем только новые
echo "$current" | while read -r dev; do
    # Если устройство уже есть в логе — пропускаем
    if ! grep -q "  + $dev\$" "$log_file"; then
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        # Если лог ещё пустой или нет отметки времени для этого устройства, добавляем заголовок
        if ! grep -q "Найдены устройства" "$log_file"; then
            echo "[$timestamp] Найдены устройства:" >> "$log_file"
        fi
        echo "  + $dev" >> "$log_file"
    fi
done

echo "Таблица обновлена: $table_file. Лог файл обновлён: $log_file."

