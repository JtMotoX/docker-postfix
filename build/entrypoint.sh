#!/bin/sh

set -e

# FUNCTION TO PREFIX TIMESTAMP TO STDOUT
ts() {
	while read -r data; do
		printf '%s %s %s[%s]: %s\n' "$(date '+%b %d %H:%M:%S')" "$(hostname)" $(basename "$0") "$$" "$data"
	done
}

# APPLY CONFIGS IF VOLUME MOUNTED
if [[ -f /configs/main.cf ]]; then
	rm -rf /postfix_persist/configs >/dev/null 2>&1
	cp -r /configs /postfix_persist/configs
	if [[ -f /postfix_persist/configs/sasl_passwd ]]; then
		postmap /postfix_persist/configs/sasl_passwd && rm -f /postfix_persist/configs/sasl_passwd
	fi
	if [[ -f /postfix_persist/configs/sender_relay ]]; then
		postmap /postfix_persist/configs/sender_relay && rm -f /postfix_persist/configs/sender_relay
	fi
	chmod -R 644 /postfix_persist/configs
	echo "Successfully applied configurations. You can now comment/disable the 'configs' line in the volumes section" | ts
	NEW_CONFIGS_APPLIED="true"
	if [[ "${ALLOW_ENABLED_CONFIGS}" != "true" ]]; then
		echo "Exiting. For debugging purposes, you can allow the container to run after applying by setting ALLOW_ENABLED_CONFIGS: 'true'. This is not recommended for security purposes." | ts
		exit 0
	else
		echo "Since you have set ALLOW_ENABLED_CONFIGS: 'true', I am going to continue to run. This is not recommended for security reasons." | ts
	fi
fi

# DISPLAY INSTRUCTIONS TO APPLY CONFIGS
if [[ "${NEW_CONFIGS_APPLIED}" != "true" ]]; then
	echo "To apply/overwrite postfix configuration files, place the configs in the 'configs' folder and uncomment/enable the 'configs' line in the volumes section. This is done for security reasons to ensure plain-text credentials are not accessible from inside the running container." | ts
fi

# STOP IF NO CONFIGS HAVE BEEN APPLIED
if [[ ! -f /postfix_persist/configs/main.cf ]]; then
	echo "No configurations have been set. Please provide configuration files" | ts
	exit 1
fi

# COPY CONFIGS FROM PERSIST VOLUME
find /postfix_persist/configs/ -type f -print0 | while read -d $'\0' SRC_FILE; do
	DEST_FILE=$(echo "${SRC_FILE}" | sed 's/^\/postfix_persist\/configs/\/etc\/postfix/')
	DEST_DIR="$(dirname ${DEST_FILE})"
	mkdir -p "${DEST_DIR}"
	cp -p "${SRC_FILE}" "${DEST_FILE}"
done

# SEND LOGS TO DOCKER STDOUT
postconf maillog_file=/dev/stdout

# START POSTFIX
postfix start-fg -vvv
