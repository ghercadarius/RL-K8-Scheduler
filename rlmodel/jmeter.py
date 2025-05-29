import subprocess
from time import sleep


class JMeter:
    def __init__(self, test_path: str):
        self.test_path = test_path

    def upload_test(self):
        print("Uploading test...")
        self.upload_command = f"""curl -X POST "http://localhost:9095/upload_test" -H "accept: application/json" -H "Content-Type: multipart/form-data" -F "file=@{self.test_path}" """
        try:
            result = subprocess.run(self.upload_command, shell=True, check=True, capture_output=True, text=True)
            print("Test uploaded successfully.")
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Error uploading test: {e}")
            print(e.output)

    def run_test(self):
        print("Running test...")
        self.run_command = """curl -X POST "http://localhost:9095/run" -H "accept: application/json" -d "" """
        try:
            result = subprocess.run(self.run_command, shell=True, check=True, capture_output=True, text=True)
            sleep(2) # Wait for the test to start
            print("Test run successfully.")
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Error running test: {e}")
            print(e.output)

    def stop_test(self):
        print("Stopping test...")
        self.stop_command = """curl -X POST "http://localhost:9095/stop" -H "accept: application/json" -d "" """
        try:
            result = subprocess.run(self.stop_command, shell=True, check=True, capture_output=True, text=True)
            print("Test stopped successfully.")
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Error stopping test: {e}")
            print(e.output)
