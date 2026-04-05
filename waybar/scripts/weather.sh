#!/bin/bash

# Waybar weather module using wttr.in (no API key needed)
# Returns JSON for waybar's return-type: json

LOCATION=""  # empty = auto-detect via IP
UNITS=""     # empty = auto-detect, "m" = metric, "u" = imperial

PARAMS="format=j1"
[ -n "$UNITS" ] && PARAMS="${PARAMS}&${UNITS}"

data=$(curl -sf "wttr.in/${LOCATION}?${PARAMS}" 2>/dev/null)

if [ -z "$data" ]; then
  echo '{"text": " --", "tooltip": "Weather unavailable", "class": "default"}'
  exit 0
fi

temp=$(echo "$data" | jq -r '.current_condition[0].temp_C')
feels=$(echo "$data" | jq -r '.current_condition[0].FeelsLikeC')
desc=$(echo "$data" | jq -r '.current_condition[0].weatherDesc[0].value')
humidity=$(echo "$data" | jq -r '.current_condition[0].humidity')
wind_kmph=$(echo "$data" | jq -r '.current_condition[0].windspeedKmph')
wind_dir=$(echo "$data" | jq -r '.current_condition[0].winddir16Point')
location=$(echo "$data" | jq -r '.nearest_area[0].areaName[0].value')
code=$(echo "$data" | jq -r '.current_condition[0].weatherCode')

# Map weather codes to icons
case "$code" in
  113) icon=" " ;;                           # clear/sunny
  116) icon=" " ;;                           # partly cloudy
  119|122) icon=" " ;;                       # cloudy/overcast
  143|248|260) icon=" " ;;                   # fog/mist
  176|263|266|293|296) icon=" " ;;           # light rain
  299|302|305|308|311|314|317) icon=" " ;;   # heavy rain
  227|230|320|323|326|329|332|335|338|350|368|371|374|377) icon=" " ;; # snow
  200|386|389|392|395) icon=" " ;;           # thunder
  *) icon=" " ;;
esac

tooltip="${location}: ${desc}\n${icon} ${temp}°C (feels ${feels}°C)\n💧 ${humidity}%\n💨 ${wind_kmph} km/h ${wind_dir}"

echo "{\"text\": \"${icon}${temp}°C\", \"tooltip\": \"${tooltip}\", \"class\": \"weather\"}"
