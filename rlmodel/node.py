import random


class Node:
    def __init__(self, name: str, metrics : dict = None):
        """
        :param name: Kubernetes node name
        """
        self.name = name
        if metrics is not None:
            self.cpu = metrics['cpu'] # percentage
            self.ram = metrics['ram'] # in mb
            self.disk_read = metrics['disk_read'] # in mbps
            self.disk_write = metrics['disk_write'] # in mbps
            self.network_bandwidth = metrics['network_bandwidth'] # in mbps
            self.power_usage = 0 # in joules, are calculated when creating the agent state
        else:
            self.cpu = random.uniform(0,1)
            self.ram = random.uniform(0, 4096)
            self.disk_read = random.uniform(0, 50)
            self.disk_write = random.uniform(0, 50)
            self.network_bandwidth = random.uniform(0, 100)
            self.power_usage = 0.0

    def update_metrics(self, metrics: dict):
        self.cpu = metrics['cpu']
        self.ram = metrics['ram']
        self.disk_read = metrics['disk_read']
        self.disk_write = metrics['disk_write']
        self.network_bandwidth = metrics['network_bandwidth']
        self.power_usage = metrics['power_usage']

    def update_metric(self, name, value):
        """
        Update a single metric for the node.
        :param name: Name of the metric (e.g., 'cpu', 'ram', etc.)
        :param value: New value for the metric
        """
        if hasattr(self, name):
            setattr(self, name, value)
        else:
            raise ValueError(f"Metric '{name}' does not exist in Node.")


    def get_metrics(self) -> dict:
        """
        :return: dict of metrics in fixed order
        """
        return_dict = {'cpu': self.cpu, 'ram': self.ram, 'disk_read': self.disk_read, 'disk_write': self.disk_write,
                       'network_bandwidth': self.network_bandwidth,
                       'power_usage': self.power_usage}
        return return_dict

    def get_state_list(self) -> list:
        """
        :return: list of metrics in fixed order
        """
        return [self.cpu, self.ram, self.disk_read, self.disk_write, self.network_bandwidth, self.power_usage]
