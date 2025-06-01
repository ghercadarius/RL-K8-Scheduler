import json
import re
import subprocess
import time


class App:
    def __init__(self, deployment_path: str, service_path: str, temp_deployment_path: str):
        self.deployment_path = deployment_path # absolute path to folder containing deployment files
        self.temp_deployment_path = temp_deployment_path # absolute path to folder containing temporary deployment files
        self.service_path = service_path

    def runApp(self, nr_pods: int = 1):
        print("Running application...")
        print("Generating the new deployment with the specified number of pods...")
        self.generate_temp_deployment(nr_pods)
        deployCommand = f"""kubectl apply -f {self.temp_deployment_path}"""
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
        deleteAppCommand = f"""kubectl delete -f {self.temp_deployment_path}"""
        deleteServiceCommand = f"""kubectl delete -f {self.service_path}"""
        deleteTempDeploymentCommand = f"""rm {self.temp_deployment_path}"""
        try:
            subprocess.run(deleteAppCommand, shell=True, check=True)
            print("Deployment deleted successfully.")
            try:
                subprocess.run(deleteServiceCommand, shell=True, check=True)
                print("Service deleted successfully.")
                # Clean up the temporary deployment file
                try:
                    subprocess.run(deleteTempDeploymentCommand, shell=True, check=True)
                    print("Temporary deployment file deleted successfully.")
                except subprocess.CalledProcessError as e:
                    print(f"Error deleting temporary deployment file: {e}")
            except subprocess.CalledProcessError as e:
                print(f"Error deleting service: {e}")
        except subprocess.CalledProcessError as e:
            print(f"Error deleting deployment: {e}")

    def getAppStatus(self):
        print("Checking application status...")
        health_check_endpoint = "http://172.16.100.3:30085/test"
        while True:
            try:
                response = subprocess.run(
                    f"curl -s {health_check_endpoint}",
                    shell=True, check=True, capture_output=True, text=True
                )
                if response.stdout:
                    try:
                        data = json.loads(response.stdout)
                        if data.get("message") == "Test app is running":
                            print("Application is running.")
                            break
                        else:
                            print("Application is not running properly. Retrying...")
                    except json.JSONDecodeError:
                        print("Invalid JSON response. Retrying...")
                else:
                    print("No response from application. Retrying...")
            except subprocess.CalledProcessError as e:
                print(f"Error checking application status: {e}")
            time.sleep(5)

    def generate_temp_deployment(self, replicas: int = 1):
        with open(self.deployment_path, 'r') as f:
            content = f.read()
        # Replace the replicas line (handles both numbers and REPLICA_NUMBER)
        content = re.sub(
            r'(^[ \t]*replicas:\s*)(\d+|REPLICA_NUMBER)',
            r'\g<1>{}'.format(int(replicas)),
            content,
            flags=re.MULTILINE
        )
        with open(self.temp_deployment_path, 'w') as f:
            f.write(content)