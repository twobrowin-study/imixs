#!/bin/bash

source helpers/assert.sh -x

# Тесты выполняются в указанном порядке!
export TESTS=(
    "creationTest"
)

UniqueId=""


function complexTestInit {

}

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
