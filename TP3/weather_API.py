Paris = {"Latitude": 48.8566, "Longitude": 2.3522}
Lille = {"Latitude": 50.6292, "Longitude": 3.0573}
Lyon = {"Latitude": 45.7640, "Longitude": 4.8357}
Marseille = {"Latitude": 43.2965, "Longitude": 5.3698}
Casablanca = {"Latitude": 33.5731, "Lognitude": -7.5898}

import requests

url = "https://api.open-meteo.com/v1/forecast?latitude=48.8566&longitude=2.3522&current_weather=true"