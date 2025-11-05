import os
import csv
import json
import urllib.request
import urllib.parse
from datetime import datetime

CITIES = [
    {"name": "Lille", "lat": 50.6292, "lon": 3.0573},
    {"name": "Lyon",  "lat": 45.7640, "lon": 4.8357},
]

JSON_FILE = "weather.json"
CSV_FILE = "weather.csv"
LOG_FILE = "weather.log"

API_BASE = "https://api.open-meteo.com/v1/forecast"

def fetch_current_weather(lat, lon, timeout=10):
    params = {"latitude": lat, "longitude": lon, "current_weather": "true"}
    url = API_BASE + "?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        if resp.status != 200:
            raise RuntimeError(f"HTTP {resp.status}")
        return json.load(resp)

def ensure_csv_header(path):
    if not os.path.exists(path):
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["city", "ts", "temperature_c", "windspeed_kmh", "wind_dir_deg"])

def append_json_line(path, obj):
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False) + "\n")

def append_csv_row(path, row):
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(row)

def append_log(path, processed_names):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M")
    count = len(processed_names)
    names = ", ".join(processed_names) if processed_names else "none"
    line = f"{ts} - {count} cities processed ({names})\n"
    with open(path, "a", encoding="utf-8") as f:
        f.write(line)

def main():
    processed = []

    ensure_csv_header(CSV_FILE)

    for city in CITIES:
        name = city["name"]
        try:
            data = fetch_current_weather(city["lat"], city["lon"])
            cw = data.get("current_weather")
            if not cw:
                raise ValueError("no current_weather in response")
            ts = cw.get("time")
            temp = float(cw.get("temperature"))
            windspeed = float(cw.get("windspeed"))
            winddir = float(cw.get("winddirection"))

            json_obj = {
                "city": name,
                "ts": ts,
                "temperature_c": temp,
                "windspeed_kmh": windspeed,
                "wind_dir_deg": winddir,
            }
            append_json_line(JSON_FILE, json_obj)
            append_csv_row(CSV_FILE, [name, ts, temp, windspeed, winddir])

            processed.append(name)
            # also print to console
            print(f"{name}: {ts} {temp}°C {windspeed} km/h {winddir}°")

        except Exception as e:
            print(f"Warning: failed to fetch for {name}: {e}")

    append_log(LOG_FILE, processed)

if __name__ == "__main__":
    main()
