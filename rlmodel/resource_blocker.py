import subprocess
import threading
import time

import requests

class ResourceBlocker:
    def __init__(self, node: dict, rb_ip: str = "172.16.100.3:30080"):
        self.rb_ip = rb_ip
        self.block_cpu(node['cpu'])
        self.block_ram(node['ram'])
        if node['disk_read'] > 0 and node['disk_write'] > 0:
            self.block_disk_readwrite(node['disk_read'], node['disk_write'])
        elif node['disk_read'] > 0:
            self.block_disk_read(node['disk_read'])
        elif node['disk_write'] > 0:
            self.block_disk_write(node['disk_write'])
        self.block_network(node['network_bandwidth'])


    def block_cpu(self, percentage: float):
        print("Blocking CPU...")
        # send a post request to the API to block CPU usage
        url = f"http://{self.rb_ip}/cpu"
        json_data = {
            "blocked_factor": int(100 * percentage),
            "input": 50
        }
        try:
            response = requests.post(url, json=json_data)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"CPU blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking CPU: {e}")

    def block_ram(self, value: float):
        print("Blocking RAM...")
        url = f"http://{self.rb_ip}/load"
        json_data = {
            "size_mb": value
        }
        try:
            response = requests.post(url, json=json_data)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"RAM blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking RAM: {e}")


    def block_disk_readwrite(self, read: float, write: float):
        print("Blocking Disk Read/Write...")
        url = f"http://{self.rb_ip}/readwrite"
        json_data = {
            "read_speed_mbps": read,
            "write_speed_mbps": write
        }
        try:
            response = requests.post(url, json=json_data)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"Disk blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking disk read/write: {e}")

    def block_disk_read(self, read: float):
        print("Blocking Disk Read...")
        url = f"http://{self.rb_ip}/read"
        json_data = {
            "read_speed_mbps": read
        }
        try:
            response = requests.post(url, json=json_data)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"Disk read blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking disk read: {e}")

    def block_disk_write(self, write: float):
        print("Blocking Disk Write...")
        url = f"http://{self.rb_ip}/write"
        json_data = {
            "write_speed_mbps": write
        }
        try:
            response = requests.post(url, json=json_data)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"Disk write blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking disk write: {e}")

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
        pod_name_command = "kubectl get pods --no-headers | awk '/resource-blocker/ { print $1 }'"
        try:
            pod_name = subprocess.check_output(pod_name_command, shell=True).decode().strip()
            if pod_name:
                reset_command = f"kubectl delete pod {pod_name}"
                subprocess.run(reset_command, shell=True, check=True)
                # Wait for the pod to be recreated
                print("Waiting for resource blocker pod to be recreated...")
                while True:
                    status_command = "kubectl get pods --no-headers | awk '/resource-blocker/ { print $3 }'"
                    status = subprocess.check_output(status_command, shell=True).decode().strip()
                    if status == "Running":
                        break
                    print("Resource blocker pod is not ready yet. Waiting...")
                    time.sleep(2)
                print("Resource blocker reset successfully.")
            else:
                print("No resource blocker pod found.")
        except subprocess.CalledProcessError as e:
            print(f"Error resetting resource blocker: {e}")