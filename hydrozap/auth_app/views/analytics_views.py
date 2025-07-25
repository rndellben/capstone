from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import pandas as pd
import joblib
import os
import numpy as np
import logging
from django.conf import settings
from ..utils.crop_suggester import suggest_crops_by_env

logger = logging.getLogger(__name__)

# Get the path to the model directory
MODEL_DIR = os.path.join(os.path.dirname(__file__), '..', 'model')

# Load each model
color_index_model = joblib.load(os.path.join(MODEL_DIR, 'color_index_randomForest.pkl'))
tipburn_model = joblib.load(os.path.join(MODEL_DIR, 'tipburn_prediction_model.pkl'))
tipburn_label_encoder = joblib.load(os.path.join(MODEL_DIR, 'tipburn_label_encoder.pkl'))
leaf_count_model = joblib.load(os.path.join(MODEL_DIR, 'leaf_count_model.pkl'))
suggested_crop_model = joblib.load(os.path.join(MODEL_DIR, 'suggested_crop_predictor.pkl'))
label_encoder = joblib.load(os.path.join(MODEL_DIR, 'label_encoder.pkl'))
model_temp = joblib.load(os.path.join(MODEL_DIR, 'temperature_model.pkl'))
model_hum = joblib.load(os.path.join(MODEL_DIR, 'humidity_model.pkl'))
model_ec = joblib.load(os.path.join(MODEL_DIR, 'ec_model.pkl'))
model_ph = joblib.load(os.path.join(MODEL_DIR, 'ph_model.pkl'))
crop_encoder = joblib.load(os.path.join(MODEL_DIR, 'crop_encoder.pkl'))
stage_encoder = joblib.load(os.path.join(MODEL_DIR, 'stage_encoder.pkl'))

class TipburnPredictorView(APIView):
    def post(self, request):
        try:
            data = request.data
            # Extract the feature values from the request data
            feature_values = [
                data.get("temperature"),
                data.get("humidity"),
                data.get("ec"),
                data.get("ph"),
                data.get("crop_type"),
            ]

            # Check for missing data
            if None in feature_values:
                return Response({"error": "Missing input values"}, status=400)

            # Encode the crop type using the label encoder
            encoded_crop_type = tipburn_label_encoder.transform([feature_values[4]])[0]  # Transform crop type
            feature_values[4] = encoded_crop_type

            # Define the feature names (as used during training)
            feature_names = ["temperature", "humidity", "ec", "ph", "crop_type_encoded"]

            # Prepare the input DataFrame for prediction
            df = pd.DataFrame([feature_values], columns=feature_names)

            # Get predicted probabilities
            prediction_proba = tipburn_model.predict_proba(df)

            # Get the predicted class (0 or 1)
            predicted_class = tipburn_model.predict(df)[0]

            # Get the confidence level (probability of the predicted class)
            confidence_level = prediction_proba[0][predicted_class]

            # Convert the prediction to a boolean (True for tipburn, False for no tipburn)
            tipburn_absent = False if predicted_class == 1 else True

            # Return response with prediction and confidence level
            return Response({
                "tipburn_absent": tipburn_absent,
                "confidence_level": confidence_level
            }, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)


class ColorIndexPredictorView(APIView):
    def post(self, request):
        try:
            data = request.data
            feature_values = [
                data.get("ec"),
                data.get("ph"),
                data.get("growth_days"),
                data.get("temperature")
            ]

            if None in feature_values:
                return Response({"error": "Missing input values"}, status=400)

            # Define column names as expected by the model
            feature_names = ["EC", "pH", "Growth_Days", "Temperature"]
            df = pd.DataFrame([feature_values], columns=feature_names)

            prediction = color_index_model.predict(df)[0]
            return Response({"leaf_color_index": float(prediction)}, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)

class LeafCountPredictorView(APIView):
    def post(self, request):
        try:
            data = request.data
            feature_values = [
                data.get("crop_type"),
                data.get("growth_days"),
                data.get("temperature"),
                data.get("ph")
            ]

            if None in feature_values:
                return Response({"error": "Missing input values"}, status=400)

            # Define column names as expected by the model
            feature_names = ["Crop_Type", "Growth_Days", "Temperature","pH"]
            df = pd.DataFrame([feature_values], columns=feature_names)

            prediction = leaf_count_model.predict(df)[0]
            return Response({"leaf_count": int(prediction)}, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)

class CropSuggestionView(APIView):
    def post(self, request):
        try:
            # Get environmental parameters from request
            temperature = request.data.get('temperature')
            humidity = request.data.get('humidity')
            
            # Validate inputs
            if temperature is None or humidity is None:
                return Response(
                    {"error": "Temperature and humidity are required parameters"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Convert to appropriate types
            temperature = float(temperature)
            humidity = float(humidity)
            
            # Get crop suggestions using the crop_suggester utility
            suggestions = suggest_crops_by_env(temperature, humidity)
            
            if isinstance(suggestions, str):
                # If it's a string, it's an error message
                return Response(
                    {"error": suggestions},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # If we have suggestions
            if suggestions and len(suggestions) > 0:
                # Get the top suggestion
                top_suggestion = suggestions[0]
                crop_name = top_suggestion['crop']
                
                # Create a recommendation message with standard ASCII dash
                recommendation = (
                    f"{crop_name} is recommended for your environment. "
                    f"It grows best in temperatures between {top_suggestion['temp_range']} "
                    f"and humidity levels between {top_suggestion['humidity_range']}. "
                    f"Maintain pH between {top_suggestion['pH_range']} and "
                    f"EC between {top_suggestion['EC_range']}."
                )
                
                # Return the response with all suggestions
                return Response({
                    "suggested_crop": crop_name,
                    "recommendation": recommendation,
                    "all_suggestions": suggestions
                }, status=status.HTTP_200_OK)
            else:
                return Response(
                    {"error": "No suitable crops found for the given parameters"},
                    status=status.HTTP_404_NOT_FOUND
                )
                
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
class EnvironmentRecommendationView(APIView):
    def post(self, request):
        try:
            data = request.data
            feature_values = [
                data.get("crop_type"),
                data.get("growth_stage")
            ]

            if None in feature_values:
                return Response({"error": "Missing input values"}, status=400)

            # Encode input values
            crop_type = feature_values[0]
            growth_stage = feature_values[1]

            try:
                crop_encoded = crop_encoder.transform([crop_type])[0]
                stage_encoded = stage_encoder.transform([growth_stage])[0]
            except ValueError:
                return Response({"error": "Invalid crop_type or growth_stage"}, status=400)

            input_features = np.array([[crop_encoded, stage_encoded]])

            # Run predictions
            temperature = round(model_temp.predict(input_features)[0], 2)
            humidity = round(model_hum.predict(input_features)[0], 2)
            ec = round(model_ec.predict(input_features)[0], 2)
            ph = round(model_ph.predict(input_features)[0], 2)

            # Add recommendation message
            recommendation_message = (
                f"For {crop_type} at the {growth_stage} stage, "
                f"maintain around {temperature}°C, {humidity}% humidity, EC {ec}, and pH {ph}."
            )

            return Response({
                "recommended_environment": {
                    "temperature": temperature,
                    "humidity": humidity,
                    "ec": ec,
                    "ph": ph
                },
                "recommendation": recommendation_message
            }, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)