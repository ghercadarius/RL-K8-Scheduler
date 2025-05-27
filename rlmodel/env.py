# environment.py

import numpy as np
import gym
from gym import spaces
from kubernetes import client, config
from node import Node


class KubernetesSchedulerEnv(gym.Env):
    """
    Gym environment wrapping a Kubernetes cluster for RL-based scheduling.

    Observation:
        A matrix of shape (n_nodes, 5) with per-node:
        [ cpu_util, ram_util, disk_util, net_util, power_usage ]
    Action:
        Discrete integer in [0, n_nodes), picking which node to schedule next.
    Reward:
        Defined in `_compute_reward` (e.g. penalize high max-cpu and power spikes).
    """

    metadata = {'render.modes': []}

    def __init__(
            self,
            namespace: str = "default",
            node_names: list[str] | None = None
    ):
        super().__init__()
        # --- Kubernetes client setup ---
        config.load_kube_config()
        self.v1 = client.CoreV1Api()
        self.namespace = namespace

        # --- Nodes discovery ---
        self.nodes: list[Node] = self._discover_nodes(node_names)
        self.n_nodes = len(self.nodes)

        # --- Gym spaces ---
        low = np.zeros((self.n_nodes, 5), dtype=np.float32)
        high = np.full((self.n_nodes, 5), np.inf, dtype=np.float32)
        self.observation_space = spaces.Box(low=low, high=high, dtype=np.float32)
        self.action_space = spaces.Discrete(self.n_nodes)

    def _discover_nodes(self, node_names: list[str] | None) -> list[Node]:
        """
        Either wrap provided names or auto-list from the cluster.
        """
        if node_names:
            return [Node(name) for name in node_names]
        items = self.v1.list_node().items
        return [Node(item.metadata.name) for item in items]

    def reset(self) -> np.ndarray:
        """
        Called at the start of each episode.
        Can tear down workloads if needed; here we just pull fresh metrics.
        """
        return self._collect_observation()

    def step(self, action: int):
        """
        1. Apply scheduling action
        2. Pull new observation
        3. Compute reward
        4. (Optionally) set done
        """
        assert self.action_space.contains(action), f"Invalid action {action}"
        target_node = self.nodes[action].name

        # 🛠️ your scheduling logic here, e.g. migrate a pod:
        # self._schedule_pod_to_node(pod_name, target_node)

        # new observation
        obs = self._collect_observation()
        # reward based on both previous and new obs if desired
        reward = self._compute_reward(obs, action)
        done = False  # or a horizon condition
        info = {"selected_node": target_node}
        return obs, reward, done, info

    def _collect_observation(self) -> np.ndarray:
        """
        Fetch metrics for each Node and return as (n_nodes,5) array.
        """
        obs = []
        for node in self.nodes:
            raw = self._fetch_node_metrics(node.name)
            node.update_metrics(raw)
            obs.append(node.as_array())
        return np.array(obs, dtype=np.float32)

    def _fetch_node_metrics(self, node_name: str) -> dict[str, float]:
        """
        TODO: replace stub with Metrics API or Prometheus query.
        """
        # stub with randoms for now
        return {
            'cpu': np.random.rand(),
            'ram': np.random.rand(),
            'disk': np.random.rand(),
            'net': np.random.rand(),
            'power': np.random.rand() * 200
        }

    def _compute_reward(self, observation: np.ndarray, action: int) -> float:
        """
        Example reward: penalize the highest CPU load in cluster, plus a
        small penalty for the power usage on the selected node.
        """
        max_cpu = observation[:, 0].max()
        power = observation[action, 4]
        return float(-max_cpu - 0.01 * power)

    def render(self, mode='human'):
        """
        Optional: visualize node metrics or scheduling decisions.
        """
        for node in self.nodes:
            print(
                f"{node.name}: CPU={node.cpu_utilization:.2f}  "
                f"RAM={node.ram_utilization:.2f}  "
                f"Power={node.power_usage:.1f}W"
            )
