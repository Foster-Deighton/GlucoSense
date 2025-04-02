import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from sklearn.preprocessing import MinMaxScaler
from flask import Flask, request, jsonify
import pickle

app = Flask(__name__)

# Load the trained model
model = load_model('glucose_model.h5')

# Load the scalers (assuming they were saved as .pkl files)
with open('scaler_X.pkl', 'rb') as f:
    scaler_X = pickle.load(f)

with open('scaler_y.pkl', 'rb') as f:
    scaler_y = pickle.load(f)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        sweat_glucose_before = float(data['sweat_glucose_before'])
        sweat_blood_ratio = float(data['sweat_blood_ratio'])

        # Prepare input data for the model
        input_data = np.array([[sweat_glucose_before, sweat_blood_ratio]])
        input_data = scaler_X.transform(input_data)  # Apply the scaler
        input_data = input_data.reshape((1, 1, input_data.shape[1]))  # Reshape for LSTM input

        # Get prediction
        prediction = model.predict(input_data)
        predicted_value = scaler_y.inverse_transform(prediction)[0, 0]

        return jsonify({'prediction': predicted_value})

    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)  # Host set to 0.0.0.0 for external access
