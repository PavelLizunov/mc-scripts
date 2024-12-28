### Подробное объяснение всех переменных в `config.cfg`

Файл `config.cfg` — это основной конфигурационный файл, который позволяет кастомизировать поведение скрипта для запуска Minecraft-сервера. Разберём каждую переменную:

---

### 1. **`ARCHIVE_PATH`**

- **Описание:** Указывает полный путь к ZIP-архиву Minecraft-сервера.
- **Назначение:** Определяет, где находится файл с сервером. Если переменная не задана, скрипт ищет архив в текущей папке.
- **Пример использования:**
  ```bash
  ARCHIVE_PATH=/home/user/minecraft/server.zip
  ```
- **Значение по умолчанию:** Пустое. Если не задано, скрипт ищет архив в текущей директории.

---

### 2. **`VOLUME_DIR`**

- **Описание:** Указывает путь к папке, где будут храниться данные сервера (например, мир, конфигурации, whitelist).
- **Назначение:** Позволяет монтировать файлы и папки на хосте, чтобы они сохранялись между перезапусками контейнера.
- **Пример использования:**
  ```bash
  VOLUME_DIR=/home/user/minecraft/volumes
  ```
- **Значение по умолчанию:** `$HOME/.volume_freshcraft`. Если не указано, создаётся эта папка.

---

### 3. **`PORTS`**

- **Описание:** Список портов, которые будут проброшены из контейнера на хост.
- **Назначение:** Позволяет серверу Minecraft быть доступным для клиентов через указанные порты.
- **Формат:**  
  - `ХОСТ_ПОРТ:КОНТЕЙНЕР_ПОРТ` для TCP.
  - `ХОСТ_ПОРТ:КОНТЕЙНЕР_ПОРТ/udp` для UDP.
- **Пример использования:**
  ```bash
  PORTS="25565:25565 24454:24454/udp"
  ```
- **Значение по умолчанию:**  
  ```bash
  PORTS="25565:25565 24454:24454/udp"
  ```

---

### 4. **`DOCKER_IMAGE_NAME`**

- **Описание:** Имя Docker-образа, который будет создан для Minecraft-сервера.
- **Назначение:** Позволяет задавать уникальное имя образа, если у вас несколько серверов.
- **Пример использования:**
  ```bash
  DOCKER_IMAGE_NAME=my_minecraft_server
  ```
- **Значение по умолчанию:**  
  ```bash
  DOCKER_IMAGE_NAME=freshcraft_server
  ```

---

### 5. **`DOCKER_COMPOSE_PATH`**

- **Описание:** Указывает полный путь, где будет создан файл `docker-compose.yml`.
- **Назначение:** Позволяет размещать файл `docker-compose.yml` в удобном месте.
- **Пример использования:**
  ```bash
  DOCKER_COMPOSE_PATH=/home/user/minecraft/docker-compose.yml
  ```
- **Значение по умолчанию:** Текущая директория (`$PWD/docker-compose.yml`).

---

### 6. **`DEFAULT_VOLUME_WORLD`**

- **Описание:** Указывает путь для сохранения мира Minecraft.
- **Назначение:** Монтирует папку с миром, чтобы данные сохранялись между перезапусками.
- **Пример использования:**
  ```bash
  DEFAULT_VOLUME_WORLD=/home/user/minecraft/volumes/world:/minecraft/world
  ```
- **Значение по умолчанию:**
  ```bash
  $VOLUME_DIR/world:/minecraft/world
  ```

---

### 7. **`DEFAULT_VOLUME_PROPERTIES`**

- **Описание:** Указывает путь к файлу `server.properties`.
- **Назначение:** Позволяет настроить параметры сервера (например, максимальное количество игроков, режим игры и т.д.).
- **Пример использования:**
  ```bash
  DEFAULT_VOLUME_PROPERTIES=/home/user/minecraft/volumes/server.properties:/minecraft/server.properties
  ```
- **Значение по умолчанию:**
  ```bash
  $VOLUME_DIR/server.properties:/minecraft/server.properties
  ```

---

### 8. **`DEFAULT_VOLUME_WHITELIST`**

- **Описание:** Указывает путь к файлу `whitelist.json`.
- **Назначение:** Позволяет задать список игроков, которым разрешён вход на сервер.
- **Пример использования:**
  ```bash
  DEFAULT_VOLUME_WHITELIST=/home/user/minecraft/volumes/whitelist.json:/minecraft/whitelist.json
  ```
- **Значение по умолчанию:**
  ```bash
  $VOLUME_DIR/whitelist.json:/minecraft/whitelist.json
  ```

---

### 9. **`DEFAULT_VOLUME_JVM_ARGS`**

- **Описание:** Указывает путь к файлу с пользовательскими JVM-аргументами.
- **Назначение:** Позволяет настроить JVM для оптимизации работы сервера.
- **Пример использования:**
  ```bash
  DEFAULT_VOLUME_JVM_ARGS=/home/user/minecraft/volumes/user_jvm_args.txt:/minecraft/user_jvm_args.txt
  ```
- **Значение по умолчанию:**
  ```bash
  $VOLUME_DIR/user_jvm_args.txt:/minecraft/user_jvm_args.txt
  ```

---

### 10. **`DEFAULT_VOLUME_UNIX_ARGS`**

- **Описание:** Указывает путь к файлу `unix_args.txt` для аргументов Unix.
- **Назначение:** Используется для передачи дополнительных JVM-аргументов при запуске сервера.
- **Пример использования:**
  ```bash
  DEFAULT_VOLUME_UNIX_ARGS=/home/user/minecraft/volumes/unix_args.txt:/minecraft/libraries/net/minecraftforge/forge/1.20.1-47.3.12/unix_args.txt
  ```
- **Значение по умолчанию:**
  ```bash
  $VOLUME_DIR/unix_args.txt:/minecraft/libraries/net/minecraftforge/forge/1.20.1-47.3.12/unix_args.txt
  ```

---

### 11. **`ADDITIONAL_VOLUMES`**

- **Описание:** Указывает дополнительные volumes, которые нужно монтировать в контейнер.
- **Назначение:** Используется для кастомных данных или дополнительных конфигураций.
- **Пример использования:**
  ```bash
  ADDITIONAL_VOLUMES="/path/to/custom_data:/minecraft/custom_data"
  ```
- **Значение по умолчанию:** Пусто.

