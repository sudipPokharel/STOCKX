from fastapi import FastAPI
from pydantic import BaseModel
import pandas as pd
import numpy as np
from tensorflow.keras.models import load_model
import joblib
import os
import warnings
warnings.filterwarnings("ignore")  

app = FastAPI(title="Stock Prediction API")

# List of companies
COMPANIES = ["ANKHU", "ASIAN", "NTC", "SAHAS", "SIDDHARTHA"]

# LSTM model paths
LSTM_MODELS = {
    "ankhu": "models/LSTM_base/model_ohlcv_LSTM_ANKHU_Feb.h5",
    "asian": "models/LSTM_base/model_ohlcv_LSTM_ASIAN_Feb.h5",
    "ntc": "models/LSTM_base/model_ohlcv_LSTM_NTC_Feb.h5",
    "sahas": "models/LSTM_base/model_ohlcv_LSTM_SAHAS_Feb.h5",
    "siddhartha": "models/LSTM_base/model_ohlcv_LSTM_Siddhartha_Feb.h5"
}

# ARIMA model paths
ARIMA_MODELS = {
    "ankhu": "models/arima/arima_model_feb_ANKHU.pkl",
    "asian": "models/arima/arima_model_feb_ASIAN.pkl",
    "ntc": "models/arima/arima_model_feb_NTC.pkl",
    "sahas": "models/arima/arima_model_feb_SAHAS.pkl",
    "siddhartha": "models/arima/arima_model_feb_SIDDHARTHA.pkl"
}

# Scalers for LSTM
SCALER_X = {
    "ankhu": "models/scaler_X/scaler_X_ANKHU.pkl",
    "asian": "models/scaler_X/scaler_X_ALICL.pkl",
    "ntc": "models/scaler_X/scaler_X_NTC.pkl",
    "sahas": "models/scaler_X/scaler_X_SAHAS.pkl",
    "siddhartha": "models/scaler_X/scaler_X_SIDDHARTHA.pkl"
}

SCALER_Y = {
    "ankhu": "models/scaler_y/scaler_y_ANKHU.pkl",
    "asian": "models/scaler_y/scaler_y_ALICL.pkl",
    "ntc": "models/scaler_y/scaler_y_NTC.pkl",
    "sahas": "models/scaler_y/scaler_y_SAHAS.pkl",
    "siddhartha": "models/scaler_y/scaler_y_SIDDHARTHA.pkl"
}

# Window sizes for LSTM input
WINDOW_SIZE = {
    "ankhu": 90,
    "asian": 60,
    "ntc": 90,
    "sahas": 60,
    "siddhartha": 60
}

# Load models and scalers
lstm_models = {c.lower(): load_model(LSTM_MODELS[c.lower()], compile=False) for c in COMPANIES}
arima_models = {c.lower(): joblib.load(ARIMA_MODELS[c.lower()]) for c in COMPANIES}
scaler_x = {c.lower(): joblib.load(SCALER_X[c.lower()]) for c in COMPANIES}
scaler_y = {c.lower(): joblib.load(SCALER_Y[c.lower()]) for c in COMPANIES}

# Input data model
class NewData(BaseModel):
    company: str   
    Date: str      # format: YYYY-MM-DD
    Open: float
    High: float
    Low: float
    Close: float
    Volume: float

@app.post("/predict_next")
def predict_next(new_data: NewData):
    company = new_data.company.lower()
    
    if company not in [c.lower() for c in COMPANIES]:
        return {"error": f"Company '{company}' not found."}

    # Dataset path
    DATA_PATH = f"dataset/{company}_Feb.csv"
    if not os.path.exists(DATA_PATH):
        return {"error": f"Data file for {company} not found."}

    # Load existing data
    df = pd.read_csv(DATA_PATH)
    df['Date'] = pd.to_datetime(df['Date'])
    df.sort_values('Date', inplace=True)

    # Append new actual data
    new_row = {
        'Date': pd.to_datetime(new_data.Date),
        'Open': new_data.Open,
        'High': new_data.High,
        'Low': new_data.Low,
        'Close': new_data.Close,
        'Volume': new_data.Volume
    }
    df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
    df.sort_values('Date', inplace=True)
    df.reset_index(drop=True, inplace=True)
    df.to_csv(DATA_PATH, index=False)

    # Prepare last sequence for LSTM (all OHLCV features)
    win_size = WINDOW_SIZE[company]
    if len(df) < win_size:
        return {"error": f"Not enough data for LSTM prediction. Need at least {win_size} rows."}

    features = ['Open', 'High', 'Low', 'Close', 'Volume']
    last_seq = df[features].values[-win_size:]
    last_seq_scaled = scaler_x[company].transform(last_seq)
    input_seq = last_seq_scaled.reshape(1, win_size, len(features))

    # LSTM prediction
    lstm_scaled_pred = lstm_models[company].predict(input_seq)
    lstm_pred = scaler_y[company].inverse_transform(lstm_scaled_pred)[0][0]

    # ARIMA prediction
    arima_model = arima_models[company]
    try:
        # Append new value to ARIMA without refitting
        arima_model = arima_model.append([new_data.Close], refit=False)
    except AttributeError:
        # For older ARIMA versions
        arima_model = arima_model.extend([new_data.Close])
    arima_pred = arima_model.forecast(steps=1).iloc[0]

    # Save updated ARIMA model
    joblib.dump(arima_model, ARIMA_MODELS[company])
    arima_models[company] = arima_model

    import math

# Ensure predictions are finite numbers
    lstm_pred_safe = lstm_pred if (lstm_pred is not None and math.isfinite(lstm_pred)) else None

    arima_pred_safe = arima_pred if (arima_pred is not None and math.isfinite(arima_pred)) else None


    return {
        "Company": company.upper(),
        "LSTM_Predicted_Close": float(lstm_pred_safe) if lstm_pred_safe is not None else None,
        "ARIMA_Predicted_Close": float(arima_pred_safe) if arima_pred_safe is not None else None,

    }
