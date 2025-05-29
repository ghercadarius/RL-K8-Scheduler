import subprocess

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
        # send a post request to the API to block CPU usage
        url = f"http://{self.rb_ip}/cpu"
        json_data = {
            "blocked_factor": percentage,
            "input": 50
        }
        try:
            response = requests.post(url, json=json_data)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"CPU blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking CPU: {e}")

    def block_ram(self, value: float):
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
        url = f"http://{self.rb_ip}/stream?network_speed_mbps={value}"
        try:
            response = requests.post(url)
            response.raise_for_status()  # Raise an error for bad responses
            print(f"Network blocking response: {response.json()}")
        except requests.RequestException as e:
            print(f"Error blocking network: {e}")

    @staticmethod
    def reset_resource_blocker():
        pod_name_command = "kubectl get pods --no-headers | awk '/resource-blocker/ { print $1 }'"
        try:
            pod_name = subprocess.check_output(pod_name_command, shell=True).decode().strip()
            if pod_name:
                reset_command = f"kubectl delete pod {pod_name}"
                subprocess.run(reset_command, shell=True, check=True)
                print("Resource blocker reset successfully.")
            else:
                print("No resource blocker pod found.")
        except subprocess.CalledProcessError as e:
            print(f"Error resetting resource blocker: {e}")