#!/bin/bash

source helpers/assert.sh -x

# Тесты выполняются в указанном порядке!
export TESTS=(
    "creationTest"
    "fileVersionTest"
    "commentTest"
    "getEventsTest"
    "historyTest"
)

UniqueId=""

function creationTest {

    items='$uniqueid,$writeaccess,$readaccess'

    OUTPUT=$( \
        curl --silent --location --request POST "$apiUrl/workflow/workitem?items=$items" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt" \
        --header 'Content-Type: application/xml' \
        --data-raw \
        '<document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <item name="$modelversion">
                <value xsi:type="xs:string">docver-ru-1</value>
            </item>
            <item name="$taskid">
                <value xsi:type="xs:int">1000</value>
            </item>
            <item name="$eventid">
                <value xsi:type="xs:int">10</value>
            </item>
            <item name="departmentMembers">
                <value xsi:type="xs:string">alex</value>
                <value xsi:type="xs:string">imixs</value>
            </item>
        </document>'
    )

    UniqueId=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$uniqueid"]/value'
    )
    echo "Получен uniqueid :: $UniqueId"

    refWriteAccess=(
        $imixsUser
    )
    writeAccess=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$writeaccess"]/value'
    )
    assert "echo ${writeAccess[*]}" "${refWriteAccess[*]}"

    refReadAccess=(
        Пользователи
        alex
        imixs
    )
    readAccess=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$readaccess"]/value'
    )
    assert "echo ${readAccess[*]}" "${refReadAccess[*]}" 

    assert_end ${FUNCNAME[0]}
}

function fileVersionTest {

    items='txtfileversionlog,namlastfileversion,$processid'

    OUTPUT=$( \
        curl --silent --location --request POST "$apiUrl/workflow/workitem/$UniqueId?items=$items" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt" \
        --header 'Content-Type: application/xml' \
        --data-raw \
        '<document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <item name="$eventid">
                <value xsi:type="xs:int">20</value>
            </item>
            <item name="fileVersion">
                <value xsi:type="xmlItemArray">
                    <item name="contentType">
                        <value xsi:type="xs:string">application/octet-stream</value>
                    </item>
                    <item name="content">
                        <value xsi:type="xs:base64Binary">IyEvYmluL2Jhc2gKcG9kbWFuLWNvbXBvc2UgLXQgaG9zdG5ldCAtZiBkb2NrZXItY29tcG9zZS55bWwgLXAgaW1peHMgLS1kcnktcnVuIHVwID4gaW1peHMtY29tbWFuZHMuc2gK</value>
                    </item>
                </value>
            </item>
        </document>'
    )

    namversion=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="txtfileversionlog"]/value/item[@name="namversion"]/value'
    )
    assert "echo $namversion" "v1"

    namlastfileversion=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="namlastfileversion"]/value'
    )
    assert "echo $namlastfileversion" "v1"

    processid=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$processid"]/value'
    )
    assert "echo $processid" "1100"

    assert_end ${FUNCNAME[0]}
}

function commentTest {

    items='txtcommentlog,txtlastcomment,$processid'

    OUTPUT=$( \
        curl --silent --location --request POST "$apiUrl/workflow/workitem/$UniqueId?items=$items" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt" \
        --header 'Content-Type: application/xml' \
        --data-raw \
        '<document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <item name="$eventid">
                <value xsi:type="xs:int">30</value>
            </item>
            <item name="txtComment">
                <value xsi:type="xs:string">Test Comment</value>
            </item>
        </document>'
    )

    txtcomment=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="txtcommentlog"]/value/item[@name="txtcomment"]/value'
    )
    assert "echo $txtcomment" "Test Comment"

    txtlastcomment=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="txtlastcomment"]/value'
    )
    assert "echo $txtlastcomment" "Test Comment"

    processid=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$processid"]/value'
    )
    assert "echo $processid" "1100"

    assert_end ${FUNCNAME[0]}
}

function getEventsTest {

    OUTPUT=$( \
        curl --silent --location --request GET "$apiUrl/workflow/workitem/events/$UniqueId" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt"
    )

    refNumActivityId=(
        30
        40
        50
    )
    numActivityId=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="numactivityid"]/value'
    )
    assert "echo ${numActivityId[*]}" "${refNumActivityId[*]}"

    refNextProcessId=(
        1100
        1000
        1200
    )
    nextProcessId=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="numnextprocessid"]/value'
    )
    assert "echo ${nextProcessId[*]}" "${refNextProcessId[*]}"

    refName=(
        'Добавить примечание'
        'Изменить'
        'Заморозить'
    )
    name=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="name"]/value'
    )
    assert "echo ${name[*]}" "${refName[*]}"

    assert_end ${FUNCNAME[0]}
}

function historyTest {

    items='txtworkflowhistory'

    OUTPUT=$( \
        curl --silent --location --request GET "$apiUrl/documents/search/"'$uniqueid:"'$UniqueId'"?items='"$items" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt"
    )

    refHistory=(
        "Документ готов $imixsUser"
        "Примечание добавлено $imixsUser"
    )
    txtcomment=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="txtworkflowhistory"]/value/value[@xsi:type="xs:string"][1]'
    )
    assert "echo ${txtcomment[*]}" "${refHistory[*]}"

    assert_end ${FUNCNAME[0]}
}