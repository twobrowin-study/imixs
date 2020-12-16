#!/bin/bash

source helpers/assert.sh -x

export TESTS=(
    "modelUploadTest"
)

function modelUploadTest {

    MODELS=()
    for bpmn in bpmn/*.bpmn; do
        curl --silent --location --request POST "$apiUrl/model/bpmn" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt" \
        --header 'Content-Type: application/octet-stream' \
        --data-binary "@$(pwd)/$bpmn"

        filename=${bpmn##*/}
        model=${filename%.*}
        MODELS+=($model)
    done

    OUTPUT=$( \
        curl --silent --location --request GET "$apiUrl/model" \
        --header 'Accept: application/xml' \
        --header "Authorization: Bearer $tokenJwt" | \
        xmlstarlet sel -t -v '/model/version'
    )

    assert "echo ${OUTPUT[*]}" "${MODELS[*]}"

    assert_end ${FUNCNAME[0]}
}

