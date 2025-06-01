import random


class Node:
    def __init__(self, name: str, metrics : dict = None):
        """
        :param name: Kubernetes node name
        """
        self.name = name
        self.real_metrics = {
            'cpu': 0.0,  # percentage
            'ram': 0,  # in mb
            'disk_read': 0,  # in mbps
            'disk_write': 0,  # in mbps
            'network_bandwidth': 0,  # in mbps
            'power_usage': 0.0  # in miliwatts, will be calculated when creating the agent state
        }  # will get updated with real metrics from the kvm host
        self.app_instances = 0
        if metrics is not None:
            self.cpu = metrics['cpu'] # percentage
            self.ram = metrics['ram'] # in mb
            self.disk_read = metrics['disk_read'] # in mbps
            self.disk_write = metrics['disk_write'] # in mbps
            self.network_bandwidth = metrics['network_bandwidth'] # in mbps
            self.power_usage = 0 # in miliwatts, are calculated when creating the agent state
        else:
            self.cpu = random.uniform(0,0.5) # it represents the free cpu percentage
            self.ram = int(random.uniform(0, 12288))
            self.disk_read = int(random.uniform(0, 50))
            self.disk_write = int(random.uniform(0, 50))
            self.network_bandwidth = int(random.uniform(0, 10))
            self.power_usage = 0.0

    def update_sim_metrics(self, metrics: dict):
        self.cpu = metrics['cpu']
        self.ram = metrics['ram']
        self.disk_read = metrics['disk_read']
        self.disk_write = metrics['disk_write']
        self.network_bandwidth = metrics['network_bandwidth']
        self.power_usage = metrics['power_usage']

    def update_real_metrics(self, metrics: dict):
        """
        Update the real metrics of the node.
        :param metrics: dict of real metrics
        """
        self.real_metrics['cpu'] = metrics['cpu']
        self.real_metrics['ram'] = metrics['ram']
        self.real_metrics['disk_read'] = metrics['disk_read']
        self.real_metrics['disk_write'] = metrics['disk_write']
        self.real_metrics['network_bandwidth'] = metrics['network_bandwidth']

    def update_real_metric(self, name, value):
        """
        Update a single real metric for the node.
        :param name: Name of the metric (e.g., 'cpu', 'ram', etc.)
        :param value: New value for the metric
        """
        self.real_metrics[name] = value


    def update_sim_metric(self, name, value):
        """
        Update a single metric for the node.
        :param name: Name of the metric (e.g., 'cpu', 'ram', etc.)
        :param value: New value for the metric
        """
        if hasattr(self, name):
            setattr(self, name, value)
        else:
            raise ValueError(f"Metric '{name}' does not exist in Node.")


    def get_sim_metrics(self) -> dict:
        """
        :return: dict of metrics in fixed order
        """
        return_dict = {'cpu': self.cpu, 'ram': self.ram, 'disk_read': self.disk_read, 'disk_write': self.disk_write,
                       'network_bandwidth': self.network_bandwidth}
        return return_dict

    def get_state_list(self) -> list:
        """
        :return: list of metrics in fixed order
        """
        print("Real metrics:", self.real_metrics)
        return [self.real_metrics['cpu'], self.real_metrics['ram'], self.real_metrics['disk_read'], self.real_metrics['disk_write'], self.real_metrics['network_bandwidth'], self.real_metrics['power_usage']]

    def is_valid(self) -> bool:
        """
        Check if the node is valid (not None).
        :return: True if the node is valid, False otherwise
        """
        print(self.get_sim_metrics())
        if self.cpu > 0.95 or self.ram > 12000 or self.disk_read > 470  or self.disk_write > 470 or self.network_bandwidth > 90:
            return False
        return True

    def is_done(self) -> bool:
        """
        Check if the node is done (not valid).
        :return: True if the node is done, False otherwise
        """
        if self.real_metrics == {}:
            return False
        print(self.real_metrics)
        if self.real_metrics['cpu'] > 95 or self.real_metrics['ram'] > 28000 or self.real_metrics['disk_read'] > 1500 \
                or self.real_metrics['disk_write'] > 1500 or self.real_metrics['network_bandwidth'] > 50:
            return True
        return False
