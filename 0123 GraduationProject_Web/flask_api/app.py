from flask import Flask, request, jsonify
import torch
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import os
from ultralytics import YOLO
import numpy as np

app = Flask(__name__)

# =============================================
# Configuration and Model Loading
# =============================================

MODEL_PATH = "D:\VS Projects\Graduation Project\AI Model\model_mineral_yolov11m_expert.pt"
CONFIDENCE_THRESHOLD = 0.80
CLASS_NAMES = ['Baryte', 'Calcite', 'Fluorite', 'Pyrite']

try:
    model = YOLO(MODEL_PATH)
    print("✅ Model loaded successfully")
except Exception as e:
    print(f"❌ Failed to load model: {e}")
    raise

# =============================================
# Utility Functions
# =============================================

def preprocess_image(image_bytes):
    """Convert uploaded image bytes to RGB PIL image"""
    image = Image.open(io.BytesIO(image_bytes))
    return image.convert("RGB") if image.mode != "RGB" else image

def predict_and_draw(image):
    """Run prediction and draw bounding boxes on the image"""
    results = model(image)
    detections = []

    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()

    if results[0].boxes is not None:
        for box in results[0].boxes:
            confidence = box.conf.item()
            if confidence >= CONFIDENCE_THRESHOLD:
                class_id = int(box.cls)
                class_name = CLASS_NAMES[class_id]
                x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())

                # Draw bounding box and label
                draw.rectangle([x1, y1, x2, y2], outline="red", width=2)
                draw.text((x1, y1 - 10), f"{class_name} ({confidence:.2f})", fill="yellow", font=font)

                detections.append({
                    "class": class_name,
                    "confidence": round(confidence, 2),
                    "bbox": [x1, y1, x2, y2]
                })

    return detections, image

def encode_image_base64(pil_image):
    """Encode PIL image to base64 string"""
    buffered = io.BytesIO()
    pil_image.save(buffered, format="JPEG")
    return base64.b64encode(buffered.getvalue()).decode("utf-8")

# =============================================
# API Endpoint
# =============================================

@app.route('/api/mineral/detect', methods=['POST'])
def detect_minerals():
    response = {
        "success": False,
        "detections": [],
        "result_image": None,
        "error": None
    }

    try:
        data = request.get_json()
        if not data or 'image' not in data:
            raise ValueError("Missing 'image' in request body")

        image_bytes = base64.b64decode(data['image'])
        image = preprocess_image(image_bytes)

        detections, result_img = predict_and_draw(image)
        encoded_result = encode_image_base64(result_img)

        response.update({
            "success": True,
            "detections": detections,
            "result_image": encoded_result
        })

    except Exception as e:
        response['error'] = str(e)
        app.logger.error(f"Detection error: {e}")

    return jsonify(response)

# =============================================
# Health Check and Error Handling
# =============================================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({
        "status": "healthy",
        "model_loaded": True,
        "ready": True
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404

@app.errorhandler(500)
def server_error(error):
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500
# =============================================
# Main Application
# =============================================

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, threaded=True)

