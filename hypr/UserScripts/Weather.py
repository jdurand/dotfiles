#!/usr/bin/env python3

# Simple weather placeholder script for waybar
import json

# Basic weather data - you can integrate with a weather API if needed
weather_data = {
    "text": " 22°C",
    "tooltip": "Montreal: 22°C - Partly Cloudy",
    "class": "weather"
}

print(json.dumps(weather_data))