#!/bin/sh

# Based on Blokas puredata module.

PURE_DATA_STARTUP_SLEEP=3

. /usr/local/pisound/scripts/common/common.sh

# If there's X server running
if DISPLAY=$(find_display); then
	export XAUTHORITY=/home/pi/.Xauthority
	export DISPLAY
	echo Using display $DISPLAY
	unset NO_GUI
else
	echo No display found, specifying -nogui
	NO_GUI=-nogui
fi

start_mother_and_puredata()
{
	MOTHER_PATCH="/home/patch/Pd/patches/organelle/mother.pd"
	EXTERNALS="/home/patch/Pd/externals"
	flash_leds 1

	if [ -z `which puredata` ]; then
		log "Pure Data was not found! Install by running: sudo apt-get install puredata"
		flash_leds 100
		exit 1
	fi

	log "Killing all Pure Data instances!"
	killall puredata 2> /dev/null

	PATCH="$1"
	PATCH_DIR=$(dirname "$PATCH")
	shift

	log "Launching Pure Data."
	cd "$PATCH_DIR" && puredata -stderr $NO_GUI -path "$EXTERNALS" "$MOTHER_PATCH" "$PATCH" $@ &
	PD_PID=$!

	log "Pure Data started!"
	flash_leds 1
	sleep 0.3
	flash_leds 1
	sleep 0.3
	flash_leds 1

	wait_process $PD_PID
}

PATCH="$1"
shift

echo
echo "$PATCH"
echo "$@"

(
	# Connect the osc2midi bridge to the MIDI Inputs and to Pure Data.
	sleep 4
	/usr/local/pisound-ctl/connect_osc2midi.sh "pisound-ctl"
	aconnect "pisound-ctl" "Pure Data";
	aconnect -d "Pure Data:1" "pisound-ctl"
) &

start_mother_and_puredata "$PATCH" $@
