import random

class ReplayBuffer:
    """Fixed-size buffer to store experience tuples for sampling."""
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.buffer = []
        self.position = 0  # pointer for circular buffer

    def push(self, state, action, reward, next_state, done):
        """Save a transition."""
        if len(self.buffer) < self.capacity:
            self.buffer.append(None)
        self.buffer[self.position] = (state, action, reward, next_state, done)
        self.position = (self.position + 1) % self.capacity

    def sample(self, batch_size: int):
        """Randomly sample a batch of experiences."""
        return random.sample(self.buffer, batch_size)

    def __len__(self):
        return len(self.buffer)
