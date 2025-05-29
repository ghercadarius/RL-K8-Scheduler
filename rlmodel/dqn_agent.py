import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from qnetwork import QNetwork
from replay_buffer import ReplayBuffer
import random

class DQNAgent:
    def __init__(
        self,
        state_dim: int,
        action_dim: int,
        lr: float = 1e-3,
        gamma: float = 0.99,
        buffer_size: int = 100_000,
        batch_size: int = 64,
        eps_start: float = 1.0,
        eps_end: float = 0.01,
        eps_decay: int = 50_000,
        target_update_freq: int = 1000,
        device: str = None
    ):
        # device setup
        self.device = torch.device(device or ("cuda" if torch.cuda.is_available() else "cpu"))

        # Main and target networks
        self.policy_net = QNetwork(state_dim, action_dim).to(self.device)
        self.target_net = QNetwork(state_dim, action_dim).to(self.device)
        # Initialize target to policy weights
        self.target_net.load_state_dict(self.policy_net.state_dict())
        self.target_net.eval()  # target net in inference mode

        # Optimizer and replay buffer
        self.optimizer = optim.Adam(self.policy_net.parameters(), lr=lr)
        self.replay_buffer = ReplayBuffer(buffer_size)

        # Hyperparams
        self.gamma = gamma
        self.batch_size = batch_size
        self.target_update_freq = target_update_freq

        # ε-greedy parameters
        self.eps_start = eps_start
        self.eps_end = eps_end
        self.eps_decay = eps_decay
        self.steps_done = 0

    def select_action(self, state: np.ndarray) -> int:
        """Return ε-greedy action given current state."""
        # Decay ε over time
        eps_threshold = self.eps_end + (self.eps_start - self.eps_end) * \
            np.exp(-1.0 * self.steps_done / self.eps_decay)
        self.steps_done += 1

        if random.random() < eps_threshold:
            return random.randrange(self.policy_net.net[-1].out_features)
        else:
            # convert state to tensor, flatten, forward through policy_net
            with torch.no_grad():
                state_t = torch.FloatTensor(state).unsqueeze(0).to(self.device)
                q_values = self.policy_net(state_t)
                return q_values.argmax(dim=1).item()

    def store(self, *args):
        """Store a transition in the replay buffer."""
        self.replay_buffer.push(*args)

    def update(self):
        """Sample a batch and perform a DQN update step."""
        if len(self.replay_buffer) < self.batch_size:
            return

        # Sample a batch
        transitions = self.replay_buffer.sample(self.batch_size)
        states, actions, rewards, next_states, dones = zip(*transitions)

        # Convert to tensors
        states      = torch.FloatTensor(states).to(self.device)
        actions     = torch.LongTensor(actions).unsqueeze(1).to(self.device)
        rewards     = torch.FloatTensor(rewards).unsqueeze(1).to(self.device)
        next_states = torch.FloatTensor(next_states).to(self.device)
        dones       = torch.FloatTensor(dones).unsqueeze(1).to(self.device)

        # Compute current Q-values: Q(s, a)
        q_values = self.policy_net(states).gather(1, actions)

        # Compute target Q-values: r + γ * max_a' Q_target(s', a') * (1 - done)
        with torch.no_grad():
            q_next = self.target_net(next_states).max(1)[0].unsqueeze(1)
            q_target = rewards + (1 - dones) * self.gamma * q_next

        # MSE loss between current and target Q-values
        loss = nn.functional.mse_loss(q_values, q_target)

        # Gradient descent step
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        # Periodically update target network
        if self.steps_done % self.target_update_freq == 0:
            self.target_net.load_state_dict(self.policy_net.state_dict())

