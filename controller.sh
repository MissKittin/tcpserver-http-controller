#!/bin/sh
# tcpserver http controller
# 14.10.2020, 24.01.2021

# Measure execution time
#execution_time="$(date '+%s%N')"

. './settings-controller.rc'

readFile() { while IFS= read -r line || [ -n "${line}" ]; do echo "${line}"; done < "${1}"; }
readStream() { while IFS= read -r line || [ -n "${line}" ]; do echo "${line}"; done; }
echoText()
{
	# Usage: echoText content mime code

	echo "HTTP/1.0 ${3} OK"
	[ ! "${http_header_server_id}" = '' ] && echo "Server: ${http_header_server_id}"
	"${http_header_x_frame_options_deny}" && echo 'X-Frame-Options: DENY'
	echo 'Connection: close'
	echo 'Pragma: no-cache'
	echo 'Cache-Control: no-store, no-cache, must-revalidate'
	echo "Content-type: ${2}"
	echo "Content-length: ${#1}"
	echo ''
	echo "${1}"
}
printFile()
{
	# Usage: printFile file mime code [cache-time] [gzip] [use-cat]

	# send server error if file not found
	if [ ! -f "${1}" ]; then
		log " e configuration error - ${1} not exists"
		echoText '' 'text/plain' '500'
		return '1'
	fi

	# send start header
	echo "HTTP/1.0 ${3} OK"
	[ ! "${http_header_server_id}" = '' ] && echo "Server: ${http_header_server_id}"
	"${http_header_x_frame_options_deny}" && echo 'X-Frame-Options: DENY'
	echo 'Connection: close'

	# send gzip or normal header
	if [ "${5}" = 'gzip' ]; then
		echo 'Content-Encoding: gzip'
	else
		echo "Content-type: ${2}"
	fi

	# send content length header
	echo "Content-length: $(stat --printf '%s' "${1}")"

	# send cache header
	if [ "${4}" = '' ]; then
		echo 'Pragma: no-cache'
		echo 'Cache-Control: no-store, no-cache, must-revalidate'
	else
		echo 'Pragma: cache'
		echo "Cache-Control: max-age=${4}"
	fi

	# send content (use cat or readFile)
	echo ''
	if [ "${6}" = 'use-cat' ]; then
		cat "${1}"
	else
		readFile "${1}"
	fi
}
renderFile()
{
	# Usage: renderFile file mime code

	# send server error if file not found
	if [ ! -f "${1}" ]; then
		log " e configuration error - ${1} not exists"
		echoText '' 'text/plain' '500'
		return '1'
	fi

	# create temporary file
	local tempFile="${temporary_directory}/$$"

	# render file
	. "${1}"

	# send rendered file
	printFile "${tempFile}" "${2}" "${3}"

	# remove rendered file
	rm "${tempFile}"
}
log()
{
	# Usage: log 'message content'

	if "${log_enabled}"; then
		echo " [$(date "${log_date_format}")] ${1}" >&2
	fi
}

print_S2() { echo -n "${2}"; }
read REQUEST_URI
REQUEST_URI="$(print_S2 ${REQUEST_URI})"
unset 'print_S2'

log "request from ${TCPREMOTEIP}:${TCPREMOTEPORT} to '${REQUEST_URI%\?*}'"

if "${limit_execution_time}"; then
	onTimeout()
	{
		log " e request from ${TCPREMOTEIP}:${TCPREMOTEPORT}${REQUEST_URI%\?*} timeout"
		exit 0
	}
	trap onTimeout TERM
fi

. './router.rc'

log " i disconnected: ${TCPREMOTEIP}:${TCPREMOTEPORT}${REQUEST_URI%\?*}" # chrome something hangs without this, why? I don't know

# Measure execution time
#log " i execution time: $(expr $(date '+%s%N') - ${execution_time}) nanoseconds"

exit '0'
