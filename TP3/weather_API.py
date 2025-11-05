import requests
import csv
import time
import os
from datetime import datetime

CITIES = [
    {"name": "Paris", "latitude": 48.8566, "longitude": 2.3522},
    {"name": "Lille", "latitude": 50.6292, "longitude": 3.0573},
    {"name": "Lyon", "latitude": 45.7640, "longitude": 4.8357},
    {"name": "Marseille", "latitude": 43.2965, "longitude": 5.3698},
    {"name": "Casablanca", "latitude": 33.5731, "longitude": -7.5898}
]

#Partie A

url = "https://api.open-meteo.com/v1/forecast"
CSVPath = "weather_history.csv"

def fetch_current_weather(latitude, longitude):
    attempts = 3
    delay = 0.5
    params = {"latitude": latitude, "longitude": longitude, "current_weather": "true"}
    for attempt in range(1, attempts + 1):
        try:
            r = requests.get(url, params=params, timeout=8)
            r.raise_for_status()
            data = r.json()
            cw = data.get("current_weather")
            if cw is None:
                print("Response missing current_weather")
                raise ValueError("no current_weather")
            cw["timezone"] = data.get("timezone", "")
            return cw
        except Exception as e:
            print(f"Try {attempt}/{attempts} failed for {latitude},{longitude}: {e}")
            if attempt < attempts:
                time.sleep(delay)
    print(f"Failed after {attempts} attempts for {latitude},{longitude}")
    return None

def ensure_csv_header(path):
    header = [
        "city",
        "ts",
        "latitude",
        "longitude",
        "temperature_c",
        "windspeed_kmh",
        "wind_dir_deg",
        "weathercode",
        "timezone",
    ]
    if not os.path.isfile(path) or os.path.getsize(path) == 0:
        with open(path, "a", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(header)

def append_csv_row(path, row):
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            row.get("city", ""),
            row.get("ts", ""),
            row.get("latitude", ""),
            row.get("longitude", ""),
            row.get("temperature_c", ""),
            row.get("windspeed_kmh", ""),
            row.get("wind_dir_deg", ""),
            row.get("weathercode", ""),
            row.get("timezone", ""),
        ])

if __name__ == "__main__":
    print(f"Run start: cities: {[c['name'] for c in CITIES]}")
    t0 = time.perf_counter()

    ensure_csv_header(CSVPath)

    processed = 0
    for city in CITIES:
        info = fetch_current_weather(city["latitude"], city["longitude"])
        if not info:
            print(f"{city['name']}: data not available")
            append_csv_row(CSVPath, {
                "city": city.get("name", ""),
                "latitude": city.get("latitude", ""),
                "longitude": city.get("longitude", ""),
                "temperature_c": "",
                "windspeed_kmh": "",
                "wind_dir_deg": "",
                "weathercode": "",
                "timezone": "",
            })
            continue

        temp = info.get("temperature")
        wind_ms = info.get("windspeed")
        wind_kmh = round(wind_ms * 3.6, 1) if isinstance(wind_ms, (int, float)) else ""
        wind_dir = info.get("winddirection", "")
        weathercode = info.get("weathercode", "")
        timezone = info.get("timezone", "")
        print(f"{city['name']}: {temp} °C, Vent {wind_ms} m/s")

        append_csv_row(CSVPath, {
            "city": city.get("name", ""),
            "latitude": city.get("latitude", ""),
            "longitude": city.get("longitude", ""),
            "temperature_c": temp,
            "windspeed_kmh": wind_kmh,
            "wind_dir_deg": wind_dir,
            "weathercode": weathercode,
            "timezone": timezone,
        })
        processed += 1

    duration = time.perf_counter() - t0
    print(f"Run end: processed {processed}/{len(CITIES)} cities in {duration:.2f} s")


logging_basic_done = True

