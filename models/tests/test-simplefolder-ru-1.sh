#!/bin/bash

source helpers/assert.sh -x

# Тесты выполняются в указанном порядке!
export TESTS=(
    "creationTest"
    "commentTest"
    "referenceTest"
    "historyTest"
)

UniqueId=""
RefId=""

function creationTest {

    items='$uniqueid,txtworkitemref'

    OUTPUT=$( \
        curl --silent --location --request POST "$apiUrl/workflow/workitem?items=$items" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt" \
        --header 'Content-Type: application/xml' \
        --data-raw \
        '<document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <item name="$modelversion">
                <value xsi:type="xs:string">simplefolder-ru-1</value>
            </item>
            <item name="$taskid">
                <value xsi:type="xs:int">1000</value>
            </item>
            <item name="$eventid">
                <value xsi:type="xs:int">10</value>
            </item>
            <item name="departmentMembers">
                <value xsi:type="xs:string">imixs</value>
            </item>
        </document>'
    )

    UniqueId=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$uniqueid"]/value'
    )
    echo "Получен uniqueid :: $UniqueId"

    RefId=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="txtworkitemref"]/value'
    )
    echo "Получен txtworkitemref :: $RefId"
}

function commentTest {

    items='txtcommentlog,txtlastcomment'

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

    assert_end ${FUNCNAME[0]}
}

function referenceTest {

    items='$modelversion,$taskid,$uniqueid,$uniqueidref'

    OUTPUT=$( \
        curl --silent --location --request GET "$apiUrl/workflow/tasklist/ref/$UniqueId?items=$items" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt"
    )

    modelversion=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$modelversion"]/value'
    )
    assert "echo $modelversion" "docver-ru-1"

    taskid=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$taskid"]/value'
    )
    assert "echo $taskid" "1000"

    uniqueid=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$uniqueid"]/value'
    )
    assert "echo $uniqueid" "$RefId"

    uniqueidref=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="$uniqueidref"]/value'
    )
    assert "echo $uniqueidref" "$UniqueId"

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
        "Документ добавлен $imixsUser"
        "Примечание добавлено $imixsUser"
    )
    txtcomment=$( \
        echo "$OUTPUT" | xmlstarlet sel -t -v '/data/document/item[@name="txtworkflowhistory"]/value/value[@xsi:type="xs:string"][1]'
    )
    assert "echo ${txtcomment[*]}" "${refHistory[*]}"

    assert_end ${FUNCNAME[0]}
}