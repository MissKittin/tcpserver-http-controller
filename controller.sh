#!/bin/sh
# tcpserver http controller
# 14.10.2020

# Measure execution time
#execution_time="$(date '+%s%N')"

# Root
cd "$(dirname "$(readlink -f "${0}")")"

# Settings
. ./settings.rc

# Start server
if [ ! "${1}" = 'start' ]; then
	if ! command -v ${tcpserver_command} > /dev/null 2>&1; then
		echo 'tcpserver not installed'
		exit 1
	fi

	if [ ! -d "${temporary_directory}" ]; then
		echo "temp directory ${temporary_directory} not exists"
		exit 1
	fi

	if ${temporary_directory_clear_on_start}; then
		[ "${log_file}" = '' ] && echo " [$(date "${log_date_format}")] Cleaning ${temporary_directory}..." || echo " [$(date "${log_date_format}")] Cleaning ${temporary_directory}..." >> ${log_file}
		rm -r -f ${temporary_directory}/* > /dev/null 2>&1
	fi

	[ "${log_file}" = '' ] && echo " [$(date "${log_date_format}")] Starting tcpserver..." || echo " [$(date "${log_date_format}")] Starting tcpserver..." >> ${log_file}
	[ "${log_file}" = '' ] && echo '' || echo '' >> ${log_file}

	${limit_execution_time} && timeout_command="${timeout_command} ${max_execution_time}"

	if [ "${log_file}" = '' ]; then
		exec ${tcpserver_command} ${tcpserver_additional_parameters} "${tcpserver_ip_address}" "${tcpserver_port}" ${timeout_command} "${0}" 'start' || exit 1
	else
		exec ${tcpserver_command} ${tcpserver_additional_parameters} "${tcpserver_ip_address}" "${tcpserver_port}" ${timeout_command} "${0}" 'start' >> ${log_file} 2>&1 || exit 1
	fi
fi

# Functions
getURI()
{
	echo -n "${2}"
}
echoText()
{
	# Usage: echoText content mime code
	echo "HTTP/1.1 ${3} OK"; echo "Content-type: ${2}"
	echo "Content-length: ${#1}"
	echo ''
	echo "${1}"
}
printFile()
{
	# Usage: printFile file mime code [cache-time] [gzip]

	# send server error if file not found
	if [ ! -f "${1}" ]; then
		log " e configuration error - ${1} not exists"
		echoText '' 'text/plain' '500'
		return 1
	fi

	# send start header
	echo "HTTP/1.1 ${3} OK"

	# send gzip or normal header
	if [ "${5}" = 'gzip' ]; then
		echo 'Content-Encoding: gzip'
	else
		echo "Content-type: ${2}"
	fi

	# send content length header
	echo "Content-length: $(stat --printf '%s' "${1}")"

	# send cache header
	if [ ! "${4}" = '' ]; then
		echo 'Pragma: cache'
		echo "Cache-Control: max-age=${4}"
	fi

	# send content
	echo ''
	cat "${1}"
}
renderFile()
{
	# Usage: renderFile file mime code

	# send server error if file not found
	if [ ! -f "${1}" ]; then
		log " e configuration error - ${1} not exists"
		echoText '' 'text/plain' '500'
		return 1
	fi

	# create temporary file
	local tempfile="$(mktemp -p "${temporary_directory}")"

	# render file
	. ${1}

	# send rendered file
	printFile "${tempfile}" "${2}" "${3}"

	# remove rendered file
	rm "${tempfile}"
}
log()
{
	# Usage: log 'message content'
	if ${log_enabled}; then
		echo " [$(date "${log_date_format}")] ${1}" >&2
	fi
}

# Variables
read REQUEST_URI; REQUEST_URI="$(getURI ${REQUEST_URI})"; unset getURI
GET="${REQUEST_URI#*\?}"
REQUEST_URI="${REQUEST_URI%\?*}"
[ "${GET}" = "${REQUEST_URI}" ] && GET=''

# Log
log "request from ${TCPREMOTEIP}:${TCPREMOTEPORT} to '${REQUEST_URI}'"

# Log timeout
if ${limit_execution_time}; then
	onTimeout()
	{
		log " e request from ${TCPREMOTEIP}:${TCPREMOTEPORT} timeout"
		exit 0
	}
	trap onTimeout TERM
fi

# Routing
. ./router.rc

# Measure execution time
#log " i execution time: $(expr $(date '+%s%N') - ${execution_time}) nanoseconds"

exit 0
