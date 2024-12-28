#!/bin/bash

# --- Конфигурация и значения по умолчанию ---
CONFIG_FILE="config.cfg"

# Значения по умолчанию
DEFAULT_ARCHIVE_PATH=""
DEFAULT_VOLUME_DIR="$HOME/.volume_freshcraft"
DEFAULT_DOCKER_IMAGE_NAME="freshcraft_server"
DEFAULT_DOCKER_COMPOSE_PATH="$PWD/docker-compose.yml"
DEFAULT_PORTS="25565:25565 24454:24454/udp"
DEFAULT_JAVA_ARCHIVE_NAME="zulu21.36.17-ca-jdk21.0.4-linux_x64.tar.gz"

# Базовые volumes
DEFAULT_VOLUME_WORLD="$DEFAULT_VOLUME_DIR/world:/minecraft/world"
DEFAULT_VOLUME_PROPERTIES="$DEFAULT_VOLUME_DIR/server.properties:/minecraft/server.properties"
DEFAULT_VOLUME_WHITELIST="$DEFAULT_VOLUME_DIR/whitelist.json:/minecraft/whitelist.json"
DEFAULT_VOLUME_JVM_ARGS="$DEFAULT_VOLUME_DIR/user_jvm_args.txt:/minecraft/user_jvm_args.txt"
DEFAULT_VOLUME_RUN_SCRIPT="$DEFAULT_VOLUME_DIR/run.sh:/minecraft/run.sh"
DEFAULT_VOULUME_JVM_ARGS="$DEFAULT_VOLUME_DIR/user_jvm_args.txt:/minecraft/libraries/net/minecraftforge/forge/1.20.1-47.3.12/unix_args.txt"

# Дополнительные volumes (только кастомные, без базовых)
DEFAULT_ADDITIONAL_VOLUMES=""

# Загружаем параметры из конфигурационного файла (если он существует)
if [[ -f "$CONFIG_FILE" ]]; then
  echo "Загружаем параметры из $CONFIG_FILE..."
  source "$CONFIG_FILE"
else
  echo "Конфигурационный файл $CONFIG_FILE не найден! Используем значения по умолчанию."
fi

# Установка значений из конфигурации или по умолчанию
ARCHIVE_PATH=${ARCHIVE_PATH:-$DEFAULT_ARCHIVE_PATH}
VOLUME_DIR=${VOLUME_DIR:-$DEFAULT_VOLUME_DIR}
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-$DEFAULT_DOCKER_IMAGE_NAME}
DOCKER_COMPOSE_PATH=${DOCKER_COMPOSE_PATH:-$DEFAULT_DOCKER_COMPOSE_PATH}
PORTS=${PORTS:-$DEFAULT_PORTS}
JAVA_ARCHIVE_NAME=${JAVA_ARCHIVE_NAME:-$DEFAULT_JAVA_ARCHIVE_NAME}

# Базовые volumes
VOLUME_WORLD=${VOLUME_WORLD:-$DEFAULT_VOLUME_WORLD}
VOLUME_PROPERTIES=${VOLUME_PROPERTIES:-$DEFAULT_VOLUME_PROPERTIES}
VOLUME_WHITELIST=${VOLUME_WHITELIST:-$DEFAULT_VOLUME_WHITELIST}
VOLUME_JVM_ARGS=${VOLUME_JVM_ARGS:-$DEFAULT_VOLUME_JVM_ARGS}
VOLUME_RUN_SCRIPT=${VOLUME_RUN_SCRIPT:-$DEFAULT_VOLUME_RUN_SCRIPT}
VOULUME_JVM_ARGS="${VOULUME_JVM_ARGS:-$DEFAULT_VOULUME_JVM_ARGS}


# Дополнительные volumes
ADDITIONAL_VOLUMES=${ADDITIONAL_VOLUMES:-$DEFAULT_ADDITIONAL_VOLUMES}

# --- Функции ---

# Проверка наличия zip-архива
function find_archive {
  if [[ -z "$ARCHIVE_PATH" ]]; then
    ARCHIVE_PATH=$(ls *.zip 2>/dev/null | head -n 1)
  fi

  if [[ -z "$ARCHIVE_PATH" || ! -f "$ARCHIVE_PATH" ]]; then
    echo "Архив с сервером не найден! Укажите путь в конфиге или поместите архив в текущую директорию."
    exit 1
  fi
}

# Извлечение версии из названия архива
function extract_version {
  VERSION=$(echo "$ARCHIVE_PATH" | grep -oP '\d+\.\d+(\.\d+)?')
  if [[ -z "$VERSION" ]]; then
    echo "Не удалось определить версию из имени архива!"
    read -p "Введите версию вручную (например, 2.5.0): " VERSION
    if [[ -z "$VERSION" ]]; then
      echo "Ошибка: версия не указана!"
      exit 1
    fi
  fi
}

# Распаковка архива
function unpack_archive {
  echo "Распаковываем архив \"$ARCHIVE_PATH\"..."
  mkdir -p "$PWD/fresh_craft_$VERSION"
  unzip -o "$ARCHIVE_PATH" -d "$PWD/fresh_craft_$VERSION"
}

# Перенос кастомной Java
function move_java {
  JAVA_FILE=$(find "$PWD/fresh_craft_$VERSION" -name "$JAVA_ARCHIVE_NAME" | head -n 1)
  if [[ -z "$JAVA_FILE" ]]; then
    echo "Файл кастомной Java $JAVA_ARCHIVE_NAME не найден!"
    exit 1
  fi

  SERVER_FOLDER="$PWD/fresh_craft_$VERSION/freshcraft_server"
  if [[ -d "$SERVER_FOLDER" ]]; then
    echo "Перенос кастомной Java в папку сервера..."
    mv "$JAVA_FILE" "$SERVER_FOLDER/"
  else
    echo "Папка freshcraft_server не найдена!"
    exit 1
  fi
}

# Создание Dockerfile
function create_dockerfile {
  echo "Создаём Dockerfile..."
  cat > "$SERVER_FOLDER/Dockerfile" <<EOF
# Используем базовый образ Ubuntu
FROM ubuntu:20.04

# Устанавливаем необходимые пакеты
RUN apt update && apt install -y wget tar openjdk-21-jdk-headless

# Копируем JDK
COPY $JAVA_ARCHIVE_NAME /tmp
RUN mkdir -p /opt/jdk && \\
    tar -xzf /tmp/$JAVA_ARCHIVE_NAME -C /opt/jdk && \\
    rm /tmp/$JAVA_ARCHIVE_NAME

# Устанавливаем переменные среды для использования JDK
ENV JAVA_HOME=/opt/jdk/$(basename "$JAVA_ARCHIVE_NAME" .tar.gz)
ENV PATH=\$JAVA_HOME/bin:\$PATH

# Устанавливаем рабочую директорию
WORKDIR /minecraft

# Копируем файлы сервера в контейнер
COPY . /minecraft

# Открываем порты
EOF

  for port in $PORTS; do
    container_port=$(echo "$port" | cut -d':' -f2 | cut -d'/' -f1)
    echo "EXPOSE $container_port" >> "$SERVER_FOLDER/Dockerfile"
  done

  cat >> "$SERVER_FOLDER/Dockerfile" <<EOF
# Команда запуска сервера
CMD ["java", "@unix_args.txt"]
EOF
}

# Создание файлов и папок volumes, если их нет
function ensure_volumes {
  echo "Проверяем наличие volumes..."

  # Проверяем и создаём базовые volumes
  for volume in "$VOLUME_WORLD" "$VOLUME_PROPERTIES" "$VOLUME_WHITELIST" "$VOLUME_JVM_ARGS" "$VOLUME_RUN_SCRIPT" "VOULUME_JVM_ARGS"; do
    host_path=$(echo "$volume" | cut -d':' -f1)
    if [[ ! -e "$host_path" ]]; then
      echo "Создаём $host_path..."
      if [[ "$host_path" =~ \. ]]; then
        mkdir -p "$(dirname "$host_path")"
        touch "$host_path"
      else
        mkdir -p "$host_path"
      fi
    fi
  done

  # Проверяем и создаём дополнительные volumes
  for volume in $ADDITIONAL_VOLUMES; do
    host_path=$(echo "$volume" | cut -d':' -f1)
    if [[ ! -e "$host_path" ]]; then
      echo "Создаём $host_path..."
      if [[ "$host_path" =~ \. ]]; then
        mkdir -p "$(dirname "$host_path")"
        touch "$host_path"
      else
        mkdir -p "$host_path"
      fi
    fi
  done
}

# Создание Docker-образа
function build_docker_image {
  echo "Собираем Docker-образ ${DOCKER_IMAGE_NAME}:${VERSION}..."
  docker build -t "${DOCKER_IMAGE_NAME}:${VERSION}" "$SERVER_FOLDER"

  if [[ $? -eq 0 ]]; then
    echo "Docker-образ ${DOCKER_IMAGE_NAME}:${VERSION} успешно создан!"
  else
    echo "Ошибка при создании Docker-образа!"
    exit 1
  fi
}

# Создание docker-compose.yml
function create_docker_compose {
  echo "Создаём docker-compose.yml..."
  cat > "$DOCKER_COMPOSE_PATH" <<EOF
version: '3.8'

services:
  minecraft-server:
    image: ${DOCKER_IMAGE_NAME}:${VERSION}
    container_name: freshcraft_server
    ports:
EOF

  for port in $PORTS; do
    echo "      - \"$port\"" >> "$DOCKER_COMPOSE_PATH"
  done

  cat >> "$DOCKER_COMPOSE_PATH" <<EOF
    volumes:
      - $VOLUME_WORLD
      - $VOLUME_PROPERTIES
      - $VOLUME_WHITELIST
      - $VOLUME_JVM_ARGS
      - $VOLUME_RUN_SCRIPT
EOF

  # Добавление дополнительных volumes
  if [[ -n "$ADDITIONAL_VOLUMES" ]]; then
    for vol in $ADDITIONAL_VOLUMES; do
      echo "      - $vol" >> "$DOCKER_COMPOSE_PATH"
    done
  fi

  cat >> "$DOCKER_COMPOSE_PATH" <<EOF
    stdin_open: true
    tty: true
    command: sh /minecraft/run.sh
EOF
  echo "Файл docker-compose.yml успешно создан в $DOCKER_COMPOSE_PATH!"
}

# --- Основной процесс ---

find_archive
extract_version
unpack_archive
move_java
ensure_volumes
create_dockerfile
build_docker_image
create_docker_compose

