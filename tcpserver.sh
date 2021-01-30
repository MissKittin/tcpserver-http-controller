#!/bin/sh
# start tcpserver daemon

dirNameOf() { echo "${1%/*}"; }
cd "$(dirNameOf "$(readlink -f "${0}")")"

. './settings-tcpserver.rc'

if ! command -v "${tcpserver_command}" > /dev/null 2>&1; then
	echo 'tcpserver not installed'
	exit 1
fi

if [ ! -d "${temporary_directory}" ]; then
	echo "temp directory ${temporary_directory} not exists"
	exit 1
fi

if "${temporary_directory_clear_on_start}"; then
	[ "${log_file}" = '' ] && echo " [$(date "${log_date_format}")] Cleaning ${temporary_directory}..." || echo " [$(date "${log_date_format}")] Cleaning ${temporary_directory}..." >> "${log_file}"
	rm -r -f ${temporary_directory}/* > '/dev/null' 2>&1
fi

[ "${log_file}" = '' ] && echo " [$(date "${log_date_format}")] Starting tcpserver..." || echo " [$(date "${log_date_format}")] Starting tcpserver..." >> "${log_file}"
[ "${log_file}" = '' ] && echo '' || echo '' >> "${log_file}"

"${limit_execution_time}" && timeout_command="${timeout_command} ${max_execution_time}"

if [ "${log_file}" = '' ]; then
	exec ${tcpserver_command} ${tcpserver_additional_parameters} "${tcpserver_ip_address}" "${tcpserver_port}" ${timeout_command} './controller.sh' || exit 1
else
	exec ${tcpserver_command} ${tcpserver_additional_parameters} "${tcpserver_ip_address}" "${tcpserver_port}" ${timeout_command} './controller.sh' >> "${log_file}" 2>&1 || exit 1
fi

echo ' Error starting tcpserver, exiting'
exit 1
