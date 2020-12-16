#!/bin/bash
# generate_jwt.sh 1.0 - JWT Encoder Bash Script
# Copyright (C) 2020 Will Haley
#
# https://willhaley.com/blog/generate-jwt-with-bash/
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

export JWT_SECRET=${JWT_SECRET:-}
export JWT_PAYLOAD=${JWT_PAYLOAD:-}

# Static header fields.
header='{
	"typ": "JWT",
	"alg": "HS256"
}'

# Use jq to set the dynamic `iat`
# fields on the header using the current time.
# `iat` is set to now
payload=$(
	echo "${JWT_PAYLOAD}" | jq --arg time_str "$(date +%s)" \
	'
	($time_str | tonumber) as $time_num
	| .iat=$time_num
	'
)

base64_encode()
{
	declare input=${1:-$(</dev/stdin)}
	# Use `tr` to URL encode the output from base64.
	printf '%s' "${input}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

json() {
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | jq -c .
}

hmacsha256_sign()
{
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | openssl dgst -binary -sha256 -hmac "${JWT_SECRET}"
}

generate_jwt() {

    header_base64=$(echo "${header}" | json | base64_encode)
    payload_base64=$(echo "${payload}" | json | base64_encode)

    header_payload=$(echo "${header_base64}.${payload_base64}")
    signature=$(echo "${header_payload}" | hmacsha256_sign | base64_encode)

    echo "${header_payload}.${signature}"

}