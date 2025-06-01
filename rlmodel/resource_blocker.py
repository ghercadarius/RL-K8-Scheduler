import subprocess
import threading
import time

import requests

class ResourceBlocker:
    deployment_path = ""
    service_path = ""

    def __init__(self, node: dict, rb_ip: str = "172.16.100.3:30080"):
        self.rb_ip = rb_ip
        self.timeout = 5 # seconds
        self.retries = 5 # number of retries
        self.block_cpu(node['cpu'])
        self.block_ram(node['ram'])
        if node['disk_read'] > 0 and node['disk_write'] > 0:
            self.block_disk_readwrite(node['disk_read'], node['disk_write'])
        elif node['disk_read'] > 0:
            self.block_disk_read(node['disk_read'])
        elif node['disk_write'] > 0:
            self.block_disk_write(node['disk_write'])
        # self.block_network(node['network_bandwidth'])


    def block_cpu(self, percentage: float):
        print("Blocking CPU...")
        # send a post request to the API to block CPU usage
        url = f"http://{self.rb_ip}/cpu"
        json_data = {
            "blocked_factor": int(100 * percentage),
            "input": 50
        }
        for attempt in range(self.retries):
            try:
                response = requests.post(url, json=json_data, timeout=self.timeout)
                response.raise_for_status()  # Raise an error for bad responses
                print(f"CPU blocking response: {response.json()}")
                return
            except requests.Timeout:
                print(f"Attempt {attempt + 1} failed: Timeout while blocking CPU. Retrying...")
                time.sleep(1)
            except requests.RequestException as e:
                print(f"Error blocking CPU: {e}")
                break
        print("Failed to block CPU after multiple attempts.")

    def block_ram(self, value: float):
        print("Blocking RAM...")
        url = f"http://{self.rb_ip}/load"
        json_data = {
            "size_mb": value
        }
        for attempt in range(self.retries):
            try:
                response = requests.post(url, json=json_data, timeout=self.timeout)
                response.raise_for_status()  # Raise an error for bad responses
                print(f"RAM blocking response: {response.json()}")
                return
            except requests.Timeout:
                print(f"Attempt {attempt + 1} failed: Timeout while blocking RAM. Retrying...")
                time.sleep(1)
            except requests.RequestException as e:
                print(f"Error blocking RAM: {e}")
                break
        print("Failed to block RAM after multiple attempts.")


    def block_disk_readwrite(self, read: float, write: float):
        print("Blocking Disk Read/Write...")
        url = f"http://{self.rb_ip}/readwrite"
        json_data = {
            "read_speed_mbps": read,
            "write_speed_mbps": write
        }
        for attempt in range(self.retries):
            try:
                response = requests.post(url, json=json_data, timeout=self.timeout)
                response.raise_for_status()  # Raise an error for bad responses
                print(f"Disk blocking response: {response.json()}")
                return
            except requests.Timeout:
                print(f"Attempt {attempt + 1} failed: Timeout while blocking disk read/write. Retrying...")
                time.sleep(1)
            except requests.RequestException as e:
                print(f"Error blocking disk read/write: {e}")
                break
        print("Failed to block disk read/write after multiple attempts.")

    def block_disk_read(self, read: float):
        print("Blocking Disk Read...")
        url = f"http://{self.rb_ip}/read"
        json_data = {
            "read_speed_mbps": read
        }
        for attempt in range(self.retries):
            try:
                response = requests.post(url, json=json_data)
                response.raise_for_status()  # Raise an error for bad responses
                print(f"Disk read blocking response: {response.json()}")
                return
            except requests.Timeout:
                print(f"Attempt {attempt + 1} failed: Timeout while blocking disk read. Retrying...")
                time.sleep(1)
            except requests.RequestException as e:
                print(f"Error blocking disk read: {e}")
                break
        print("Failed to block disk read after multiple attempts.")

    def block_disk_write(self, write: float):
        print("Blocking Disk Write...")
        url = f"http://{self.rb_ip}/write"
        json_data = {
            "write_speed_mbps": write
        }
        for attempt in range(self.retries):
            try:
                response = requests.post(url, json=json_data)
                response.raise_for_status()  # Raise an error for bad responses
                print(f"Disk write blocking response: {response.json()}")
                return
            except requests.Timeout:
                print(f"Attempt {attempt + 1} failed: Timeout while blocking disk write. Retrying...")
                time.sleep(1)
            except requests.RequestException as e:
                print(f"Error blocking disk write: {e}")
                break
        print("Failed to block disk write after multiple attempts.")

    def block_network(self, value: float):
        print("Blocking Network...")
        url = f"http://{self.rb_ip}/stream?network_speed_mbps={value}"

        def network_request():
            try:
                # Stream=True to avoid loading all data into memory, timeout=None for indefinite wait
                response = requests.get(url, stream=True, timeout=None)
                # Do not process the response, just keep the connection open
                for _ in response.iter_content(chunk_size=1024):
                    pass  # Keep the connection alive
            except requests.RequestException as e:
                print(f"Error blocking network: {e}")

        thread = threading.Thread(target=network_request, daemon=True)
        thread.start()
        # check if the thread is alive for 3 seconds
        for _ in range(3):
            if thread.is_alive():
                print("Network blocking is active.")
                time.sleep(1)
            else:
                print("Network blocking failed to start. Retrying...")
                self.block_network(value)  # Retry blocking network
                break

    @staticmethod
    def reset_resource_blocker():
        print("Resetting resource blocker...")
        deployment_delete_command = "kubectl delete -f " + ResourceBlocker.deployment_path
        deployment_apply_command = "kubectl apply -f " + ResourceBlocker.deployment_path
        try:
            subprocess.run(deployment_delete_command, shell=True, check=True)
            print("Resource blocker deployment deleted successfully.")
            time.sleep(5)
            subprocess.run(deployment_apply_command, shell=True, check=True)
            print("Resource blocker deployment applied successfully.")
            # Wait for the resource blocker pod to be ready
            print("Waiting for resource blocker pod to be recreated...")
            while True:
                status_command = "kubectl get pods --no-headers | awk '/resource-blocker/ { print $3 }'"
                status = subprocess.check_output(status_command, shell=True).decode().strip()
                if status == "Running":
                    break
                print("Resource blocker pod is not ready yet. Waiting...")
                time.sleep(2)
            print("Resource blocker reset successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Error resetting resource blocker: {e}")