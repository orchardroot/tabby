#!/usr/bin/env bash
# Insert Vodafone UK APN (research 2026-09-29: apn.how, vodafone.co.uk/help/mobile/set-up-data-sim)
source "$(dirname "$0")/lib.sh"
say "Insert APN"
adbs shell content insert --uri content://telephony/carriers \
  --bind name:s:"Vodafone UK" --bind numeric:s:23415 --bind mcc:s:234 --bind mnc:s:15 \
  --bind apn:s:wap.vodafone.co.uk --bind user:s:wap --bind password:s:wap --bind authtype:i:1 \
  --bind mmsc:s:http://mms.vodafone.co.uk/servlets/mms --bind mmsproxy:s:212.183.137.12 --bind mmsport:s:8799 \
  --bind type:s:default,supl,mms --bind protocol:s:IPV4V6 --bind roaming_protocol:s:IP \
  --bind carrier_enabled:i:1 --bind current:i:1
say "Set as preferred"
id="$(adbs shell content query --uri content://telephony/carriers --where "'apn=\"wap.vodafone.co.uk\"'" --projection _id | grep -oE '_id=[0-9]+' | head -1 | cut -d= -f2)"
echo "apn _id=$id"
[ -n "$id" ] && adbs shell content insert --uri content://telephony/carriers/preferapn --bind apn_id:i:"$id"
adbs shell content query --uri content://telephony/carriers/preferapn
