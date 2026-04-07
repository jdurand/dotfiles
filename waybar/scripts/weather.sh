#!/bin/bash

# Waybar weather module with fallback providers (no API key needed)
# Tries Open-Meteo first, falls back to wttr.in
# Returns JSON for waybar's return-type: json

# Montreal coordinates (change for your location)
LAT="45.5017"
LON="-73.5673"
LOCATION="Montreal"

# WMO weather code to icon + description
wmo_icon() {
  case "$1" in
    0)           echo " |Clear sky" ;;
    1)           echo " |Mainly clear" ;;
    2)           echo " |Partly cloudy" ;;
    3)           echo " |Overcast" ;;
    45|48)       echo " |Foggy" ;;
    51|53|55)    echo " |Drizzle" ;;
    56|57)       echo " |Freezing drizzle" ;;
    61|63)       echo " |Rain" ;;
    65)          echo " |Heavy rain" ;;
    66|67)       echo " |Freezing rain" ;;
    71|73|75)    echo " |Snowfall" ;;
    77)          echo " |Snow grains" ;;
    80|81|82)    echo " |Rain showers" ;;
    85|86)       echo " |Snow showers" ;;
    95)          echo " |Thunderstorm" ;;
    96|99)       echo " |Thunderstorm w/ hail" ;;
    *)           echo " |Unknown" ;;
  esac
}

# wttr.in weather code to icon + description
wttr_icon() {
  case "$1" in
    113)                     echo " |Clear" ;;
    116)                     echo " |Partly cloudy" ;;
    119|122)                 echo " |Cloudy" ;;
    143|248|260)             echo " |Fog" ;;
    176|263|266|293|296)     echo " |Light rain" ;;
    299|302|305|308|311|314|317) echo " |Heavy rain" ;;
    227|230|320|323|326|329|332|335|338|350|368|371|374|377) echo " |Snow" ;;
    200|386|389|392|395)     echo " |Thunderstorm" ;;
    *)                       echo " |Unknown" ;;
  esac
}

# --- Provider: Open-Meteo ---
try_open_meteo() {
  local data
  data=$(curl -sf --max-time 5 \
    "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,apparent_temperature&timezone=auto" \
    2>/dev/null)

  local temp
  temp=$(echo "$data" | jq -r '.current.temperature_2m // empty' 2>/dev/null)
  [ -z "$temp" ] && return 1

  local feels humidity wind code
  feels=$(echo "$data" | jq -r '.current.apparent_temperature // "--"')
  humidity=$(echo "$data" | jq -r '.current.relative_humidity_2m // "--"')
  wind=$(echo "$data" | jq -r '.current.wind_speed_10m // "--"')
  code=$(echo "$data" | jq -r '.current.weather_code // 0')

  temp=$(printf "%.0f" "$temp" 2>/dev/null || echo "$temp")
  feels=$(printf "%.0f" "$feels" 2>/dev/null || echo "$feels")

  local icd
  icd=$(wmo_icon "$code")
  local icon="${icd%%|*}"
  local desc="${icd##*|}"

  local tooltip="${LOCATION}: ${desc}\n${icon}${temp}°C (feels ${feels}°C)\n💧 ${humidity}%\n💨 ${wind} km/h"
  echo "{\"text\": \"${icon}${temp}°C\", \"tooltip\": \"${tooltip}\", \"class\": \"weather\"}"
}

# --- Provider: wttr.in ---
try_wttr() {
  local data
  data=$(curl -sf --max-time 5 "wttr.in/${LOCATION}?format=j1" 2>/dev/null)

  local temp
  temp=$(echo "$data" | jq -r '.current_condition[0].temp_C // empty' 2>/dev/null)
  [ -z "$temp" ] && return 1

  local feels humidity wind code location_name
  feels=$(echo "$data" | jq -r '.current_condition[0].FeelsLikeC // "--"')
  humidity=$(echo "$data" | jq -r '.current_condition[0].humidity // "--"')
  wind=$(echo "$data" | jq -r '.current_condition[0].windspeedKmph // "--"')
  code=$(echo "$data" | jq -r '.current_condition[0].weatherCode // 0')
  location_name=$(echo "$data" | jq -r '.nearest_area[0].areaName[0].value // "'"$LOCATION"'"')

  local icd
  icd=$(wttr_icon "$code")
  local icon="${icd%%|*}"
  local desc="${icd##*|}"

  local tooltip="${location_name}: ${desc}\n${icon}${temp}°C (feels ${feels}°C)\n💧 ${humidity}%\n💨 ${wind} km/h"
  echo "{\"text\": \"${icon}${temp}°C\", \"tooltip\": \"${tooltip}\", \"class\": \"weather\"}"
}

# --- Try providers in order ---
result=$(try_open_meteo) && { echo "$result"; exit 0; }
result=$(try_wttr) && { echo "$result"; exit 0; }

echo '{"text": " --", "tooltip": "Weather unavailable", "class": "default"}'
