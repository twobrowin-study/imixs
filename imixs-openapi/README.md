# Собственная сборка сервиса документооборота IMIXS

#### [Домашняя страница проекта](https://www.imixs.org)

## Плагины

* `org.imixs.microservice.plugins.CommentPlugin` - позволяет комментировать
* `org.imixs.microservice.plugins.FileVersionPlugin` - позволяет создавать версии файлов

## Сборка Docker образа сервиса

`mvn clean install -Pdocker,image`

## Тестирование плагинов

`mvn clean test`

## База данных и постоянное хранилище

Доступна возможность запустить сервис с БД в памяти H2. Основным режимом является запуск с подключением ко внешней БД PostgreSQL.

## Группы пользователей

Пользователи обязаны прнадлежить одновременно трём классам групп:

* Отдел, каждый пользователь входит в отдел; на основе отделов в модели определяется доступ и принадлежность процессов (передаётся идентификатор отдела); название отдела усваивается в модели поле `namDepartment`
* Обощённая группа `Пользователи` - все пользователи в системе вообще (всегда передаётся с JWT!)
* Технические роли в системе Imixs (обычно, IMIXS-WORKFLOW-Author)

## Аутентификация пользователей

###### СПРАВКА: авторизация (сопоставление пользователя с парой login/password) должна производится вне, токен аутентификации содержит информацию о полномочиях пользователя.

Аутентификаця пользователей осуществляется на основе [JSON Web Token](https://jwt.io/). Содержимое токена:

```JSON
{ // Header
    "alg": "HS256",
    "typ": "JWT"
}
{ // Payload
    "sub": "tester",
    "groups":
    [
        "IMIXS-WORKFLOW-Manager"
    ],
    "displayname": "John Brown",
    "iat": "1595501219"
}
```

Поля Payload:

* sub - субъект, идентификатор (логин) пользователя
* groups - перечисление групп, в которые входит пользователь
* displayname - отображаемое имя пользователя
* iat - время создания токена, выраженное в системе UNIX в секундах от 1 янв. 1970

Метод преобразования токена:

* SECRET - строка секртного ключа шифрования, общего для передающего и принимающего

```Java
HMACSHA256(
    base64UrlEncode(header) + "." +
    base64UrlEncode(payload),
    
    SECRET

)
```

## Переменные окружения Docker образа

* `DATABASE_PROVIDER` - тип используемой СУБД (postgres, h2)
* `POSTGRES_HOST` - расположение СУБД PostgreSQL
* `POSTGRES_USER` - пользователь СУБД PostgreSQL
* `POSTGRES_PASSWORD` - Пароль пользователя СУБД PostgreSQL
* `POSTGRES_DATABASE` - Название базы данных СУБД PostgreSQL
* `POSTGRES_CONNECTION` - Подключение к СУБД PostgreSQL
* `JWT_SECRET` - Секретный ключ JWT
* `JWT_EXPIRE` - Время действия токена JWT (в секундах)
* `MP_OPENAPI_SERVERS` - Доменное имя сервиса для открытия портов

## Порты Docker образа

* `8080` - основное приложение (/api/ - доступ к ресурам)

## Пример Docker Compose файла

```YAML
version: "3.6"
services:

  imixs-db:
    image: postgres:9.6.1
    environment:
      POSTGRES_PASSWORD: adminadmin
      POSTGRES_DB: workflow-db
    volumes:
      - dbdata:/var/lib/postgresql/data

  imixs-app:
    image: imixs/imixs-microservice
    environment:
      DATABASE_PROVIDER: "postgres"
      POSTGRES_HOST: "db"
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "adminadmin"
      POSTGRES_DATABASE: "workflow"
      POSTGRES_CONNECTION: "jdbc:postgresql://imixs-db/workflow-db"
      JWT_SECRET: "my-secure-secret"
      JWT_EXPIRE: "3600"
      MP_OPENAPI_SERVERS: "http://localhost:8080"
    ports:
      - "8080:8080"

volumes:
  dbdata:
```