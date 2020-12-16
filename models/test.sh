#!/bin/bash

IMAGE_RUN=0
IMAGE_REMOVE=0
PODMAN=0

args="$(getopt -n "$0" -l \
    help,image-run,image-remove,podman hIRp $*)" \
|| exit -1
for arg in $args; do
    case "$arg" in
        -h)
            echo "$0 [-IRp]" \
                "[--image-run] [--image-remove] [--podman]"
            echo "`sed 's/./ /g' <<< "$0"` [-h] [--help]"
            exit 0;;
        --help)
            cat <<EOF
Использование: $0 [параметры]
Тестирование моделей Imixs

Параметры:
  -I, --image-run     запустить тестовый сервис Imixs
  -R, --image-remove  после завершения тестирования удалить тестовый сервис Imixs
  -p, --podman        использовать контейнеры Podman вместо Docker
  -h                  показать помощь по использованию и выйти
  --help              показать эту подсказку и выйти
EOF
            exit 0;;
        -I|--image-run)
            IMAGE_RUN=1;;
        -R|--image-remove)
            IMAGE_REMOVE=1;;
        -p|--podman)
            PODMAN=1;;
    esac
done

source helpers/print_centered.sh

baseUrl='http://localhost:8080'
apiUrl="$baseUrl/api"
serviceName='imixs-app-h2-tests'

contProg=docker
if [ $PODMAN -eq 1 ]; then
    echo "Выбрано тестирование с применением контейнеров Podman"
    contProg=podman
fi

########################################
print_centered " Тестирование моделей BPMN IMIXS " "="


########################################
echo "Генерация JWT токена аутентификации..."

imixsUser='tester'

JWT_SECRET='my-secure-secret'
JWT_PAYLOAD='{ "sub": "'"$imixsUser"'", "groups": [ "IMIXS-WORKFLOW-Manager" ], "displayname": "Tester" }'

source helpers/generate_jwt.sh

tokenJwt=$(generate_jwt)

echo "Получен токен: $tokenJwt"


########################################
if [ $IMAGE_RUN -eq 1 ]; then
    echo "Запуск тествого сервиса..."

    $contProg run -d --rm --name=$serviceName --network host \
        -e DATABASE_PROVIDER=h2 \
        -e JWT_SECRET=$JWT_SECRET \
        -e JWT_EXPIRE=3600 \
        -e MP_OPENAPI_SERVERS=$baseUrl \
        -p 8080:8080 imixs/imixs-microservice
    

    echo "Ожидание запуска..."
    for i in {45..0}; do
        echo -e '\e[1A\e[KОжидание запуска...'$i
        sleep 1
    done

    echo "Запущено!"
fi


########################################
echo "Проверка подключения к тестовому сервису..."

wget -q --spider $apiUrl

if [ ! $? -eq 0 ]; then
    echo "Ошибка подключения"
    echo "Завершение..."
    echo "Тестовый сервис Imixs завершён не будет"
    exit 1
fi

echo "Подключение установлено!"


########################################
for test_file in tests/test-*.sh; do
    filename=${test_file##*/}
    test_name=${filename%.*}
    print_centered " $test_name " "-"

    source "$test_file"

    for test_func in ${TESTS[*]}; do
        echo "Выполняется $test_func"
        $test_func
    done
done


########################################
print_centered " Тестирование успешно завершено " "="


########################################
if [ $IMAGE_REMOVE -eq 1 ]; then
    echo "Остановка тествого сервиса..."
    $contProg stop $serviceName
    echo "Остановлено!"
fi