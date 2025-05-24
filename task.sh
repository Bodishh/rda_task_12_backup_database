#!/bin/bash

set -e

DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"

if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "Помилка: Змінні середовища DB_USER і DB_PASSWORD повинні бути встановлені."
  exit 1
fi

SOURCE_DB="ShopDB"
FULL_BACKUP_DB="ShopDBReserve"
DATA_BACKUP_DB="ShopDBDevelopment"

create_db_if_not_exists() {
  local db_name="$1"
  echo "Перевірка наявності бази даних $db_name..."
  RESULT=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES LIKE '$db_name';" | grep "$db_name" || true)
  if [[ -z "$RESULT" ]]; then
    echo "База даних $db_name не існує. Створення..."
    mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE $db_name;"
  else
    echo "База даних $db_name вже існує."
  fi
}

create_db_if_not_exists "$FULL_BACKUP_DB"
create_db_if_not_exists "$DATA_BACKUP_DB"

echo "Створення повної резервної копії бази $SOURCE_DB..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$SOURCE_DB" > full_backup.sql
echo "Відновлення повної копії у $FULL_BACKUP_DB..."
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$FULL_BACKUP_DB" < full_backup.sql

echo "Створення резервної копії лише даних з $SOURCE_DB..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" --no-create-info "$SOURCE_DB" > data_backup.sql
echo "Відновлення даних у $DATA_BACKUP_DB..."
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DATA_BACKUP_DB" < data_backup.sql

echo "Резервне копіювання та відновлення завершено успішно."
