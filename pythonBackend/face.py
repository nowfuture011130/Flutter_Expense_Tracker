from flask import Flask, request, jsonify
import face_recognition
import numpy as np
import io
from PIL import Image

app = Flask(__name__)


def load_known_face():
    known_image_path = 'me.jpeg'
    known_image = face_recognition.load_image_file(known_image_path)
    known_face_encoding = face_recognition.face_encodings(known_image)[0]
    return known_face_encoding


known_face_encoding = load_known_face()


@app.route('/recognize', methods=['POST'])
def recognize_face():
    if 'file' not in request.files:
        return jsonify({'matched': False, 'message': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'matched': False, 'message': 'No selected file'}), 400

    try:
        image = Image.open(io.BytesIO(file.read()))
        image = np.array(image)

        uploaded_face_encodings = face_recognition.face_encodings(image)

        if not uploaded_face_encodings:
            return jsonify({'matched': False, 'message': 'No faces found in the image'}), 400

        uploaded_face_encoding = uploaded_face_encodings[0]
        results = face_recognition.compare_faces(
            [known_face_encoding], uploaded_face_encoding)

        if results[0]:
            return jsonify({'matched': True, 'message': 'Face matches!'}), 200
        else:
            return jsonify({'matched': False, 'message': 'Face does not match!'}), 200

    except Exception as e:
        return jsonify({'matched': False, 'message': str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True, port=5000)
