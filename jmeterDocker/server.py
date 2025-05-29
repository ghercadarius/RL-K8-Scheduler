# server.py

import os, subprocess, signal, time
from datetime import datetime
import sys

from flask import Flask, request, jsonify
from flasgger import Swagger

app = Flask(__name__)
swagger = Swagger(app)

os.makedirs('test_file_folder', exist_ok=True)
os.makedirs('result_file_folder', exist_ok=True)
app.config['test_file_folder'] = 'test_file_folder'
app.config['result_file_folder'] = 'result_file_folder'
result_filename = None
test_filename = None
jmeter_process = None

@app.route('/upload_test', methods=['POST'])
def upload_jmx():
    """
    Upload a JMeter .jmx test file
    ---
    consumes:
      - multipart/form-data
    parameters:
      - in: formData
        name: file
        type: file
        required: true
        description: The .jmx test file to upload
    responses:
      200:
        description: File uploaded successfully
        schema:
          type: object
          properties:
            message:
              type: string
            current_working_dir:
              type: string
      400:
        description: Invalid file type
    """
    global test_filename
    app.logger.info(f"Current working directory: {os.getcwd()}")
    file = request.files.get('file')
    if not file or file.filename.split('.')[-1] != 'jmx':
        return jsonify({'error': 'Invalid file type. Only .jmx files are allowed.'}), 400
    filepath = os.path.join(app.config['test_file_folder'], file.filename)
    file.save(filepath)
    test_filename = file.filename
    return jsonify({'message': 'File uploaded successfully', 'current_working_dir': os.getcwd()}), 200

@app.route('/run', methods=['POST'])
def run_test():
    """
    Run the uploaded JMeter test
    ---
    responses:
      200:
        description: Test run successfully
        schema:
          type: object
          properties:
            message:
              type: string
            result_file:
              type: string
            results:
              type: string
      400:
        description: No test file uploaded
      500:
        description: Execution failed
    """
    global test_filename, result_filename, jmeter_process
    app.logger.info(f"Current working directory: {os.getcwd()}")
    if test_filename is None or not os.path.exists(os.path.join(app.config['test_file_folder'], test_filename)):
        return jsonify({'error': 'No test file uploaded'}), 400
    result_filename = 'result-' + datetime.now().strftime("%Y%m%d%H%M%S") + '.csv'
    result_path = os.path.join(app.config['result_file_folder'], result_filename)
    test_path = os.path.join(app.config['test_file_folder'], test_filename)

    try:
        jmeter_process = subprocess.Popen([
            '../opt/jmeter/bin/jmeter',
            '-n',
            '-t', test_path,
            '-l', result_path
        ], preexec_fn=os.setsid)
        return jsonify({'message': 'Test run successfully started', 'result_file': result_filename}), 200
    except subprocess.CalledProcessError as e:
        jmeter_process = None
        return jsonify({'error': 'Execution failed', 'details': str(e)}), 500

@app.route('/health-check', methods=['GET'])
def health_check():
    """
    Health check endpoint
    ---
    responses:
      200:
        description: Service is healthy
        schema:
          type: object
          properties:
            status:
              type: string
    """
    return jsonify({'status': 'ok'}), 200

@app.route('/stop', methods=['POST'])
def stop_test():
    """
    Stop the running JMeter test
    ---
    responses:
      200:
        description: Test stopped successfully
        schema:
          type: object
          properties:
            message:
              type: string
      400:
        description: No test is running
    """
    global jmeter_process
    if jmeter_process and jmeter_process.poll() is None:
        os.killpg(os.getpgid(jmeter_process.pid), signal.SIGINT)
        time.sleep(2)
        if jmeter_process.poll() is None:
            os.killpg(os.getpgid(jmeter_process.pid), signal.SIGKILL)
        jmeter_process = None
        return jsonify({'message': 'Test stopped successfully'}), 200
    else:
        return jsonify({'error': 'No test is running'}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5005, debug=True)