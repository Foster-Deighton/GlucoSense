import os
import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import LSTM, Dense, Dropout, BatchNormalization, Bidirectional, Attention
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_absolute_error, r2_score
import matplotlib.pyplot as plt

# Load initial dataset
dataset_path = "Downloads/glucoseContent.csv"
if not os.path.exists(dataset_path):
    raise FileNotFoundError(f"Dataset file not found: {dataset_path}")

df = pd.read_csv(dataset_path)

df.dropna(subset=['Sweat Glucose Before (mM)', 'Blood Glucose After (mM)'], inplace=True)

# Feature Engineering
df['Time of Day'] = pd.to_datetime(df['Date']).dt.hour / 24.0
X = df[['Sweat Glucose Before (mM)', 'Sweat/Blood Ratio', 'Time of Day']].values
y = df[['Blood Glucose After (mM)']].values

# Normalize data using MinMaxScaler
scaler_X = MinMaxScaler()
scaler_y = MinMaxScaler()
X = scaler_X.fit_transform(X)
y = scaler_y.fit_transform(y)

# Reshape input for LSTM (samples, time steps, features)
X = X.reshape((X.shape[0], 1, X.shape[1]))

# Split data into training, validation, and test sets
X_train_val, X_test, y_train_val, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
X_train, X_val, y_train, y_val = train_test_split(X_train_val, y_train_val, test_size=0.25, random_state=42)

print(f"Train size: {len(X_train)}, Val size: {len(X_val)}, Test size: {len(X_test)}")

# Model path to save and load
model_path = "glucose_forecast_model.h5"

# Check if a pre-trained model exists and load it, otherwise train a new model
if os.path.exists(model_path):
    model = load_model(model_path)
    print("Loaded pre-trained model.")
else:
    model = Sequential([
        Bidirectional(LSTM(256, activation='tanh', return_sequences=True, input_shape=(1, X.shape[2]))),
        BatchNormalization(),
        Dropout(0.3),
        Bidirectional(LSTM(128, activation='tanh', return_sequences=True)),
        BatchNormalization(),
        Dropout(0.3),
        Attention(),
        LSTM(64, activation='tanh', return_sequences=False),
        Dropout(0.3),
        Dense(32, activation='relu'),
        Dense(1)
    ])

    # Custom MAPE loss function for better performance on prediction errors
    def mape_loss(y_true, y_pred):
        return tf.reduce_mean(tf.abs((y_true - y_pred) / (y_true + tf.keras.backend.epsilon())))

    model.compile(optimizer=keras.optimizers.Adam(learning_rate=0.0003), loss=mape_loss)

    # EarlyStopping callback to stop training if validation loss doesn't improve
    early_stopping = EarlyStopping(monitor='val_loss', patience=50, restore_best_weights=True, verbose=1)

    # ModelCheckpoint callback to save the best model during training
    model_checkpoint = ModelCheckpoint(model_path, save_best_only=True, save_weights_only=False, monitor='val_loss', mode='min', verbose=1)

    # Train the model with callbacks
    history = model.fit(X_train, y_train, epochs=300, batch_size=32, validation_data=(X_val, y_val), 
                        verbose=1, callbacks=[early_stopping, model_checkpoint])

    # Save the model after training
    model.save(model_path)
    print("Model trained and saved.")

# Evaluate model with custom evaluation metrics (MAE, R², MAPE)
def evaluate_model(model, X_data, y_data, split_name=""):
    preds = model.predict(X_data)
    preds = scaler_y.inverse_transform(preds)
    y_data = scaler_y.inverse_transform(y_data)
    mae = mean_absolute_error(y_data, preds)
    r2 = r2_score(y_data, preds)
    mape = np.mean(np.abs((y_data - preds) / (y_data + 1e-7))) * 100  # MAPE calculation
    print(f"\n=== {split_name} Results ===")
    print(f"{split_name} MAE:  {mae:.4f} mM")
    print(f"{split_name} R²:   {r2:.4f}")
    print(f"{split_name} MAPE: {mape:.2f}%")

evaluate_model(model, X_train, y_train, "Train")
evaluate_model(model, X_val, y_val, "Val")
evaluate_model(model, X_test, y_test, "Test")

# Plot training and validation loss for analysis
def plot_training_history(history):
    plt.plot(history.history['loss'], label='Training Loss')
    plt.plot(history.history['val_loss'], label='Validation Loss')
    plt.title('Model Loss')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.legend()
    plt.show()

plot_training_history(history)

# Confidence Interval Calculation using Monte Carlo Dropout
def predict_with_confidence(model, X_input, num_samples=100):
    """
    Perform Monte Carlo dropout to estimate prediction intervals (confidence intervals).
    """
    f = keras.backend.function([model.input, keras.backend.learning_phase()], [model.output])
    predictions = np.zeros((num_samples, X_input.shape[0]))

    for i in range(num_samples):
        predictions[i] = f([X_input, 1])[0].flatten()  # Use dropout during inference

    # Calculate mean and confidence intervals (95% confidence)
    mean_preds = np.mean(predictions, axis=0)
    lower_bound = np.percentile(predictions, 2.5, axis=0)  # 2.5 percentile for lower bound
    upper_bound = np.percentile(predictions, 97.5, axis=0)  # 97.5 percentile for upper bound

    return mean_preds, lower_bound, upper_bound

# Interactive prediction with confidence intervals
def predict_blood_glucose_with_ci(sweat_glucose_before, sweat_blood_ratio):
    """
    Takes Sweat Glucose Before (mM) and Sweat/Blood Ratio as inputs and predicts Blood Glucose After (mM),
    along with confidence intervals.
    """
    input_data = np.array([[sweat_glucose_before, sweat_blood_ratio]])
    input_data = scaler_X.transform(input_data)
    input_data = input_data.reshape((1, 1, input_data.shape[1]))
    
    mean_preds, lower_bound, upper_bound = predict_with_confidence(model, input_data)
    predicted_blood_after = mean_preds[0]
    
    # Inverse transform to get original scale
    predicted_blood_after = scaler_y.inverse_transform([[predicted_blood_after]])[0, 0]
    lower_bound = scaler_y.inverse_transform([[lower_bound[0]]])[0, 0]
    upper_bound = scaler_y.inverse_transform([[upper_bound[0]]])[0, 0]
    
    return predicted_blood_after, lower_bound, upper_bound

# Interactive prediction
try:
    user_input_sweat = float(input("\nEnter Sweat Glucose Before (mM): "))
    user_input_ratio = float(input("Enter Sweat/Blood Ratio: "))
    predicted_value, lower_ci, upper_ci = predict_blood_glucose_with_ci(user_input_sweat, user_input_ratio)
    print(f"Predicted Blood Glucose After (mM): {predicted_value:.4f} mM")
    print(f"Confidence Interval: [{lower_ci:.4f}, {upper_ci:.4f}] mM")
except ValueError:
    print("Invalid input. Please enter valid numerical values.")
