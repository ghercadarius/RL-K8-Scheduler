import subprocess
import time


class App:
    def __init__(self, deployment_path: str, service_path: str):
        self.deployment_path = deployment_path # absolute path to folder containing deployment files
        self.service_path = service_path

    def runApp(self):
        print("Running application...")
        deployCommand = f"""kubectl apply -f {self.deployment_path}"""
        serviceCommand = f"""kubectl apply -f {self.service_path}"""
        try:
            subprocess.run(deployCommand, shell=True, check=True)
            print("Deployment applied successfully.")
            try:
                subprocess.run(serviceCommand, shell=True, check=True)
                print("Service applied successfully.")
            except subprocess.CalledProcessError as e:
                print(f"Error applying service: {e}")
        except subprocess.CalledProcessError as e:
            print(f"Error applying deployment: {e}")

    def deleteApp(self):
        print("Deleting application...")
        deleteAppCommand = f"""kubectl delete -f {self.deployment_path}"""
        deleteServiceCommand = f"""kubectl delete -f {self.service_path}"""
        try:
            subprocess.run(deleteAppCommand, shell=True, check=True)
            print("Deployment deleted successfully.")
            try:
                subprocess.run(deleteServiceCommand, shell=True, check=True)
                print("Service deleted successfully.")
            except subprocess.CalledProcessError as e:
                print(f"Error deleting service: {e}")
        except subprocess.CalledProcessError as e:
            print(f"Error deleting deployment: {e}")

    def getAppStatus(self):
        print("Checking application status...")
        health_check_endpoint = f"http://172.16.100.3:30085/test" # check to see if the app is up
        while True:
            try:
                response = subprocess.run(f"curl -s {health_check_endpoint}", shell=True, check=True, capture_output=True, text=True)
                if response.stdout.strip() == "OK":
                    print("Application is running.")
                    break
                else:
                    print("Application is not running properly. Retrying...")
            except subprocess.CalledProcessError as e:
                print(f"Error checking application status: {e}")
            time.sleep(2)