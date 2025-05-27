# agent_dqn.py

import random
from collections import deque

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim

class QNetwork(nn.Module):
    """
    Simple MLP mapping state → Q-values for each action.
    """
    def __init__(self, state_dim: int, action_dim: int):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 128),
            nn.ReLU(),
            nn.Linear(128, action_dim)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)

class ReplayBuffer:
    """
    Fixed-size circular buffer for experience replay.
    """
    def __init__(self, capacity: int):
        self.buffer = deque(maxlen=capacity)

    def push(self, transition: tuple):
        self.buffer.append(transition)

    def sample(self, batch_size: int):
        return random.sample(self.buffer, batch_size)

    def __len__(self) -> int:
        return len(self.buffer)

class DQNAgent:
    """
    Core DQN algorithm:
     • ε-greedy action selection
     • replay buffer sampling
     • target network for stable updates
    """
    def __init__(
        self,
        state_shape: tuple[int, ...],
        n_actions: int,
        lr: float = 1e-3,
        gamma: float = 0.99,
        buffer_size: int = 100_000,
        batch_size: int = 64,
        eps_start: float = 1.0,
        eps_end: float = 0.01,
        eps_decay: int = 50_000,
        target_update_freq: int = 1_000
    ):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        flat_dim = int(np.prod(state_shape))
        self.policy_net = QNetwork(flat_dim, n_actions).to(self.device)
        self.target_net = QNetwork(flat_dim, n_actions).to(self.device)
        self.target_net.load_state_dict(self.policy_net.state_dict())
        self.optimizer = optim.Adam(self.policy_net.parameters(), lr=lr)

        self.replay_buffer = ReplayBuffer(buffer_size)
        self.batch_size = batch_size
        self.gamma = gamma

        # ε-greedy params
        self.eps_start = eps_start
        self.eps_end = eps_end
        self.eps_decay = eps_decay
        self.steps_done = 0

        self.target_update_freq = target_update_freq

    def select_action(self, state: np.ndarray) -> int:
        """
        Returns ε-greedy action for given state.
        """
        eps_threshold = self.eps_end + (self.eps_start - self.eps_end) * \
            np.exp(-1.0 * self.steps_done / self.eps_decay)
        self.steps_done += 1

        if random.random() < eps_threshold:
            return random.randrange(self.policy_net.net[-1].out_features)
        else:
            state_t = torch.FloatTensor(state.flatten()).unsqueeze(0).to(self.device)
            with torch.no_grad():
                q_values = self.policy_net(state_t)
            return q_values.argmax(dim=1).item()

    def store_transition(self, s, a, r, s_next, done):
        self.replay_buffer.push((s, a, r, s_next, done))

    def update(self):
        """
        Sample a batch and do one gradient step on the Bellman error.
        """
        if len(self.replay_buffer) < self.batch_size:
            return

        transitions = self.replay_buffer.sample(self.batch_size)
        states, actions, rewards, next_states, dones = zip(*transitions)

        # to tensors
        states      = torch.FloatTensor(np.array(states)).view(self.batch_size, -1).to(self.device)
        actions     = torch.LongTensor(actions).unsqueeze(1).to(self.device)
        rewards     = torch.FloatTensor(rewards).unsqueeze(1).to(self.device)
        next_states = torch.FloatTensor(np.array(next_states)).view(self.batch_size, -1).to(self.device)
        dones       = torch.FloatTensor(dones).unsqueeze(1).to(self.device)

        # Q(s,a)
        q_values = self.policy_net(states).gather(1, actions)

        # max_a' Q_target(s',a')
        with torch.no_grad():
            q_next = self.target_net(next_states).max(1)[0].unsqueeze(1)
            q_target = rewards + (1 - dones) * self.gamma * q_next

        # loss
        loss = nn.functional.mse_loss(q_values, q_target)

        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        # periodically sync target network
        if self.steps_done % self.target_update_freq == 0:
            self.target_net.load_state_dict(self.policy_net.state_dict())
