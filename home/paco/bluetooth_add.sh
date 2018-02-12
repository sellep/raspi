#!/bin/bash

# This script is called by udev

MAC=$(echo "$NAME" | sed 's/:/_/g' | sed 's/\"//g')
USER=paco

SINK=alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo

function log {
	echo "[$(date)]: $*" >> /var/log/a2dp
}

# Check PulseAudio daemon instance running
function chckpa {
	sudo su - $USER -c "pulseaudio --check"

	if [ "$?" == "1" ] ; then
		log "pulseaudio daemon not running, starting pulseaudio"
		sudo su - $USER -c "pulseaudio --start"
	fi
}

# Check PulseAudio source
# PulseAudio might recognize source a little later
function chcksrc {
	for i in {1..20} ; do
		sleep 1

		SOURCES=$(sudo su - $USER -c "pactl list sources short")

		if [[ "$SOURCES" =~ "$1" ]] ; then
			log "pulseaudio source $1 found"
			break
		fi

		if [ "$i" == "7" ] ; then
			log "unable to find pulseaudio source $1!!"
			exit
		fi
	done
}

# Connect source with sink
function connect {
	log "connecting $1 - $2"
	RES=$(sudo su - $USER -c 'pactl load-module module-loopback source="$1" sink="$2" rate=44100 adjust_time=0')
	log "result $RES"
}

log $ACTION $MAC

if [ "$ACTION" = "add" ] ; then
	SOURCE=bluez_source."$MAC".a2dp_source

	chckpa
	chcksrc "$SOURCE"
	#connect "$SOURCE" "$SINK"
fi
