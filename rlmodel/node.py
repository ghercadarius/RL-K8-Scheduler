class Node:
    def __init__(self, name: str, metrics : dict = None):
        """
        :param name: Kubernetes node name
        """
        self.name = name
        if metrics is not None:
            self.cpu = metrics['cpu']
            self.ram = metrics['ram']
            self.disk_read = metrics['disk_read']
            self.disk_write = metrics['disk_write']
            self.network_upload = metrics['network_upload']
            self.network_download = metrics['network_download']
            self.power_usage = metrics['power_usage']
        else:
            self.cpu = 0.0
            self.ram = 0.0
            self.disk_read = 0.0
            self.disk_write = 0.0
            self.network_download = 0.0
            self.network_upload = 0.0
            self.power_usage = 0.0

    def update_metrics(self, metrics: dict):
        self.cpu = metrics['cpu']
        self.ram = metrics['ram']
        self.disk_read = metrics['disk_read']
        self.disk_write = metrics['disk_write']
        self.network_download = metrics['network_download']
        self.network_upload = metrics['network_upload']
        self.power_usage = metrics['power_usage']

    def get_metrics(self) -> dict:
        """
        :return: dict of metrics in fixed order
        """
        return_dict = {'cpu': self.cpu, 'ram': self.ram, 'disk_read': self.disk_read, 'disk_write': self.disk_write,
                       'network_upload': self.network_upload, 'network_download': self.network_download,
                       'power_usage': self.power_usage}
        return return_dict
