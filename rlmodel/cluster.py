import subprocess

import gym

from resource_blocker import ResourceBlocker
from node import Node
from app import App
from jmeter import JMeter

class Cluster(gym.Env):
    def __init__(self, test_app: App, jmeter: JMeter):
        # Initialize the cluster with a list of Node objects
        self.num_nodes = 0
        self.nodes = []  # Replace with actual Node instances
        self.max_ram = 12288
        self.action_space = gym.spaces.Discrete(3) # 3 different nodes to choose from
        self.test_app = test_app # Application to be deployed on the cluster
        self.jmeter = jmeter # JMeter instance for load testing
        print("Initialized Cluster environment with 0 nodes.")

    def add_node(self, node: Node):
        # Add a new node to the cluster
        self.nodes.append(node)
        self.num_nodes += 1
        print("Added node:", node.name, "to the cluster. Total nodes:", self.num_nodes)

    def get_state(self):
        print("Getting the current state of the cluster...")
        # Placeholder: Return the current state of the cluster as an array
        # Implement: Aggregate metrics from all nodes (e.g., CPU, RAM, etc.)
        final_state = []
        for node in self.nodes:
            if node is not None:
                print("Simulating metrics for node:", node.name)
                ResourceBlocker(node.get_sim_metrics()) # convert node metrics to real kvm metrics
                node_power = Cluster.get_power() # get power consumption in joules over 10 seconds
                real_metrics = Cluster.get_real_metrics() # get real metrics from the kvm host
                node.update_real_metrics(real_metrics) # update node metrics with real metrics
                node.real_metrics['power_usage'] = node_power # update real metrics with power consumption
                final_state.extend(node.get_state_list())  # Flatten the node metrics into the final state list
                ResourceBlocker.reset_resource_blocker() # delete the pod to reset and force a new one to be created
        return final_state

    def step(self, action):
        print("Taking a step in the environment with action:", action)
        # Placeholder: Apply an action to the cluster and return (next_state, reward, done, info)
        # Implement: Apply resource blocking, update node metrics, calculate reward, check if done
        if action < 0 or action >= len(self.nodes):
            print("Action out of range.")
            return self.get_state(), -10000, True  # Invalid action, return state with heavy penalty
        if not self.nodes[action].is_valid():
            print("Invalid action: Node is not valid. Not enough resources or node is None.")
            reward = -10000  # Invalid action, penalize heavily. Each pod should have be deployed on a node with enough resources
            done = True
            return self.get_state(), reward, done
        if action == 0:
            # deploy application on node 0
            self.apply_action(0)
        elif action == 1:
            # deploy application on node 1
            self.apply_action(1)
        elif action == 2:
            # deploy application on node 2
            self.apply_action(2)
        next_state = []
        done = True
        for node in self.nodes:
            if node is not None:
                done = done and node.is_done() # see if we have a node that is not done
                next_state.extend(node.get_state_list())
        reward = -self.nodes[action].real_metrics['power_usage']  # maximize reward by minimizing power usage
        if done:
            reward += 100
        return next_state, reward, done

    def reset(self):
        # Placeholder: Reset the cluster to an initial state
        # Implement: Reset all node metrics and any environment state
        self.nodes = []
        self.num_nodes = 0
        ResourceBlocker.reset_resource_blocker()
        self.jmeter.stop_test()
        self.test_app.deleteApp()
        return self.get_state()

    def render(self, mode='human'):
        # Placeholder: Print or visualize the current state
        # Implement: Print node metrics or plot them
        for node in self.nodes:
            if node is not None:
                print(f"Node {node.name} metrics: {node.get_state_list()}")


    def apply_action(self, node_index: int):
        # Placeholder: Actually apply the action to the cluster
        # Implement: Use ResourceBlocker or similar to change node resources
        print("Applying action:", node_index)
        if node_index > len(self.nodes) - 1 or node_index < 0:
            raise ValueError("Invalid node index")
        action_node = self.nodes[node_index]
        # simulate the blocked resources
        ResourceBlocker(action_node.get_sim_metrics())
        # start the test app on the desired node
        self.test_app.runApp()
        # check to see if it is running
        self.test_app.getAppStatus()
        # run the jmeter test
        self.jmeter.run_test()
        cur_power = Cluster.get_power()
        action_node.update_real_metrics(Cluster.get_real_metrics())
        action_node.update_real_metric('power_usage', cur_power)  # update the node with the current power usage
        # stop the jmeter test
        self.jmeter.stop_test()
        # delete the test app
        self.test_app.deleteApp()
        # update the node with the real metrics

    @staticmethod
    def get_power(host_ip: str = "172.16.100.1"):
        print("Getting power consumption from the host...")
        ssh_command = (
            f"sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
            f"darius@{host_ip} 'echo 'Dar1us2oo3' | sudo -S ./kvm_power_monitor.sh'"
        )
        avg_watt_value = 0.0
        try:
            result = subprocess.run(ssh_command, shell=True, check=True, capture_output=True, text=True)
            output = result.stdout.strip()
            if output:
                lines = output.splitlines()
                for line in lines:
                    if line.startswith("Average VM Power"):
                        # Example: Average VM Power over 100ms: 607.488 mWatts - miliwatts
                        try:
                            avg_watt_value = float(line.split(":")[1].split()[0])
                            break
                        except (IndexError, ValueError):
                            continue
            else:
                print("No output received from the command.")
        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {e}")
            avg_watt_value = 10000  # Default to 0 if command fails or no output
        return avg_watt_value

    @staticmethod
    def get_real_metrics(host_ip: str="172.16.100.1"):
        print("Getting real metrics from the host...")
        ssh_command = f"sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@{host_ip} 'echo 'Dar1us2oo3' | sudo -S ./metrics-monitor.sh'"
        # Execute the command and capture the output
        metrics = {}
        try:
            result = subprocess.run(ssh_command, shell=True, check=True, capture_output=True, text=True)
            output = result.stdout
            if output:
                lines = output.strip().splitlines()
                for line in lines:
                    if line.startswith("CPU Usage:"):
                        # Example: CPU Usage: 25%
                        metrics['cpu'] = float(line.split(":")[1].strip().replace('%', ''))
                    elif line.startswith("RAM Usage:"):
                        # Example: RAM Usage: 7056 MB used of 31755 MB (22%)
                        parts = line.split()
                        metrics['ram'] = float(parts[2])  # used MB
                    elif line.startswith("Disk Usage:"):
                        # Example: Disk Usage: Disk Read: 26 MB/s, Write: 1365 MB/s
                        read_part = line.split("Disk Read:")[1].split(",")[0].strip()
                        write_part = line.split("Write:")[1].strip()
                        metrics['disk_read'] = float(read_part.split()[0])
                        metrics['disk_write'] = float(write_part.split()[0])
                    elif line.startswith("Network Usage:"):
                        # Example: Network Usage: Net Rx: 0 MBps, Tx: 0 MBps (iface enp0s31f6)
                        rx_part = line.split("Net Rx:")[1].split(",")[0].strip()
                        tx_part = line.split("Tx:")[1].split()[0].strip()
                        metrics['network_bandwidth'] = float(rx_part.split()[0]) + float(tx_part)
            else:
                print("No output received from the command.")
        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {e}")
            metrics['cpu'] = 0.0
            metrics['ram'] = 0.0
            metrics['disk_read'] = 0.0
            metrics['disk_write'] = 0.0
            metrics['network_bandwidth'] = 0.0
        print("Real metrics obtained:", metrics)
        # return power_consumption
        return metrics  # Placeholder value for testing

