
import pandas as pd
import numpy as np
import random

# Step 1: Define the crop data
crops_data = {
    "Arugula":        {"temp": (16, 22), "humidity": (60, 75), "pH": (6.0, 7.0), "EC": (0.8, 1.2)},
    "Cabbage":        {"temp": (15, 24), "humidity": (60, 80), "pH": (6.0, 6.8), "EC": (1.2, 2.0)},
    "Kale":           {"temp": (16, 24), "humidity": (55, 75), "pH": (5.5, 6.5), "EC": (1.4, 2.0)},
    "Lettuce":        {"temp": (18, 24), "humidity": (50, 70), "pH": (5.5, 6.5), "EC": (0.8, 1.8)},
    "Mustard Greens": {"temp": (18, 25), "humidity": (55, 75), "pH": (6.0, 7.0), "EC": (1.0, 1.8)},
    "Pechay":         {"temp": (20, 28), "humidity": (55, 75), "pH": (6.0, 7.0), "EC": (1.2, 2.0)},
    "Spinach":        {"temp": (16, 22), "humidity": (60, 80), "pH": (6.0, 7.0), "EC": (1.5, 2.0)},
}

# Step 2: Helper to create slightly varied random values
def generate_range(min_val, max_val, variance=0.5):
    val = np.clip(random.uniform(min_val - variance, max_val + variance), 0, None)
    return round(val, 2)

# Step 5: Suggest crops based on environment with fallback
def suggest_crops_by_env(temp, humidity, top_n=4):
    matches = []

    for crop, conditions in crops_data.items():
        temp_min, temp_max = conditions["temp"]
        hum_min, hum_max = conditions["humidity"]

        # Only suggest crops that fully match both conditions
        if temp_min <= temp <= temp_max and hum_min <= humidity <= hum_max:
            matches.append({
                "crop": crop,
                "temp_range": f"{temp_min}-{temp_max}°C",
                "humidity_range": f"{hum_min}-{hum_max}%",
                "pH_range": f"{conditions['pH'][0]}-{conditions['pH'][1]}",
                "EC_range": f"{conditions['EC'][0]}-{conditions['EC'][1]} mS/cm"
            })

    if not matches:
        return f"No suitable crops found for {temp}°C and {humidity}%. Please check your input values."

    return matches[:top_n]
