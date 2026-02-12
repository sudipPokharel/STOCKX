from fastapi import FastAPI
from pydantic import BaseModel
import pandas as pd
import numpy as np
import joblib
import os
import tensorflow as tf
from tensorflow.keras.models import load_model
from sklearn.preprocessing import StandardScaler


# ==============================
# REPRODUCIBILITY
# ==============================
np.random.seed(42)
tf.random.set_seed(42)

# ==============================
# FASTAPI APP
# ==============================
app = FastAPI(title="Stock Prediction API")

# ==============================
# CONFIGURATION
# ==============================
WINDOW = 60

MODEL_PATH = "/Users/manishyogi/Desktop/yochai final hai/model_ohlcv_LSTM_Siddhartha_Feb.h5"
SCALER_PATH = "/Users/manishyogi/Desktop/yochai final hai/scaler_X_Siddhartha.pkl"
DATA_PATH = "/Users/manishyogi/Desktop/yochai final hai/Siddhartha_Feb.csv"

# ==============================
# LOAD MODEL & SCALER
# ==============================
model = load_model(MODEL_PATH, compile=False)
scaler = joblib.load(SCALER_PATH)

print("Model and Scaler Loaded Successfully")

# ==============================
# INPUT DATA MODEL
# ==============================
class NewData(BaseModel):
    Date: str
    Open: float
    High: float
    Low: float
    Close: float
    Volume: float

# ==============================
# PREDICTION ENDPOINT
# ==============================
@app.post("/predict_next")
def predict_next(new_data: NewData):

    if not os.path.exists(DATA_PATH):
        return {"error": "Dataset not found"}

    # Load dataset
    df = pd.read_csv(DATA_PATH)
    df['Date'] = pd.to_datetime(df['Date'])
    df.sort_values('Date', inplace=True)

    # Add new row (or update if exists)
    new_row = {
        "Date": pd.to_datetime(new_data.Date),
        "Open": new_data.Open,
        "High": new_data.High,
        "Low": new_data.Low,
        "Close": new_data.Close,
        "Volume": new_data.Volume
    }

    if new_row["Date"] in df["Date"].values:
        df.loc[df["Date"] == new_row["Date"],
               ["Open","High","Low","Close","Volume"]] = \
               [new_row["Open"], new_row["High"],
                new_row["Low"], new_row["Close"],
                new_row["Volume"]]
    else:
        df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)

    df.sort_values('Date', inplace=True)
    df.reset_index(drop=True, inplace=True)

    # Save updated dataset
    df.to_csv(DATA_PATH, index=False)

    # ==============================
    # PREPARE LAST WINDOW
    # ==============================
    if len(df) < WINDOW:
        return {"error": f"Need at least {WINDOW} rows"}

    features = ['Open', 'High', 'Low', 'Close', 'Volume']
    last_seq = df[features].values[-WINDOW:].astype(np.float32)

    # Apply SAME log1p transformation used in training
    last_seq[:, 4] = np.log1p(last_seq[:, 4])

    last_seq = np.nan_to_num(last_seq)

    # Scale using SAME scaler
    last_seq_scaled = scaler.transform(last_seq)

    # Reshape for LSTM
    input_seq = last_seq_scaled.reshape(1, WINDOW, 5)

    # ==============================
    # PREDICT
    # ==============================
    scaled_prediction = model.predict(input_seq)

    # Inverse transform properly
    dummy = np.zeros((1, 5))
    dummy[0, 3] = scaled_prediction[0][0]  # Close index = 3

    inverted = scaler.inverse_transform(dummy)
    predicted_close = float(inverted[0][3])

    print("Scaled prediction:", scaled_prediction)
    print("Final predicted Close:", predicted_close)

    return {
        "Predicted_Next_Close": predicted_close
    }
