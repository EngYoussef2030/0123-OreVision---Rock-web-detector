from flask import Flask, request, jsonify
from ultralytics import YOLO
import numpy as np
import base64
import io
from PIL import Image
import time
from flask_cors import CORS
import cv2

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load the model using Ultralytics
model_path = r'C:/Users/Ali/Downloads/Telegram Desktop/model_mineral_yolov11m_expert.pt'
model = YOLO(model_path)

# Define class labels with Arabic translations
CLASS_LABELS = ['Baryte', 'Calcite', 'Fluorite', 'Pyrite']
ARABIC_TRANSLATIONS = {
    'Baryte': 'باريت',
    'Calcite': 'كالسيت',
    'Fluorite': 'فلوريت',
    'Pyrite': 'بايرايت',
    'Image not recognized': 'الصورة غير معروفة'
}

# Confidence threshold
CONFIDENCE_THRESHOLD = 0.77

# Cache to store recent predictions to avoid redundant processing
prediction_cache = {}
CACHE_EXPIRY = 1.0  # Cache entries expire after 1 second

def preprocess_image(image):
    # YOLO internally resizes and processes
    return image

def predict_image(image):
    # Run inference with the YOLO model
    results = model(image, verbose=False)
    
    # Process results
    if len(results) > 0:
        result = results[0]
        if len(result.boxes) > 0:
            # Get the box with highest confidence
            confidences = result.boxes.conf.cpu().numpy()
            if max(confidences) >= CONFIDENCE_THRESHOLD:
                # Get the class with highest confidence
                max_conf_idx = np.argmax(confidences)
                class_id = int(result.boxes.cls[max_conf_idx].item())
                class_name = CLASS_LABELS[class_id]
                confidence = confidences[max_conf_idx]
                return result, class_name, float(confidence)
    
    return None, None, None

def create_annotated_image(image, result):
    # Convert PIL image to OpenCV format
    img_cv = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
    
    # Draw bounding boxes on the image
    for box in result.boxes:
        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
        conf = box.conf[0].item()
        cls = int(box.cls[0].item())
        
        # Draw rectangle
        cv2.rectangle(img_cv, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        
        # Add label
        label = f"{CLASS_LABELS[cls]} {conf:.2f}"
        cv2.putText(img_cv, label, (int(x1), int(y1) - 10), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
    
    # Convert back to PIL image
    img_pil = Image.fromarray(cv2.cvtColor(img_cv, cv2.COLOR_BGR2RGB))
    
    # Convert to base64
    buffered = io.BytesIO()
    img_pil.save(buffered, format="JPEG")
    img_str = base64.b64encode(buffered.getvalue()).decode()
    
    return img_str

@app.route('/predict', methods=['POST'])
def predict():
    try:
        start_time = time.time()
        
        data = request.get_json()
        image_base64 = data['image']
        language = data.get('language', 'en')  # Default to English if not specified
        
        # Use a hash of the image data as a cache key
        cache_key = hash(image_base64[:100] + language)  # Include language in cache key
        
        # Check if we have a recent prediction for this image
        current_time = time.time()
        if cache_key in prediction_cache:
            cached_result, timestamp = prediction_cache[cache_key]
            if current_time - timestamp < CACHE_EXPIRY:
                return jsonify(cached_result)
        
        # Process the image
        image_data = base64.b64decode(image_base64)
        image = Image.open(io.BytesIO(image_data)).convert('RGB')
        
        input_data = preprocess_image(image)
        yolo_result, predicted_class, confidence = predict_image(input_data)
        
        if confidence is None:
            english_result = 'Image not recognized'
            result = {
                'result': ARABIC_TRANSLATIONS[english_result] if language == 'ar' else english_result,
                'confidence': '0%',
                'english_result': english_result,
                'arabic_result': ARABIC_TRANSLATIONS[english_result],
                'result_image': None
            }
        else:
            english_result = predicted_class
            arabic_result = ARABIC_TRANSLATIONS[english_result]
            
            # Create annotated image
            annotated_image = create_annotated_image(image, yolo_result)
            
            result = {
                'result': arabic_result if language == 'ar' else english_result,
                'confidence': f"{confidence * 100:.2f}%",
                'english_result': english_result,
                'arabic_result': arabic_result,
                'result_image': annotated_image
            }
        
        # Cache the result
        prediction_cache[cache_key] = (result, current_time)
        
        # Clean up expired cache entries
        for key in list(prediction_cache.keys()):
            if current_time - prediction_cache[key][1] > CACHE_EXPIRY:
                del prediction_cache[key]
        
        processing_time = time.time() - start_time
        app.logger.info(f"Processing time: {processing_time:.3f}s")
        
        return jsonify(result)
    
    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)

