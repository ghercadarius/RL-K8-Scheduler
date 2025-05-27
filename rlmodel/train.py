# train.py

import numpy as np
from env import KubernetesSchedulerEnv
from dqn import DQNAgent

def train_loop(
    env: KubernetesSchedulerEnv,
    agent: DQNAgent,
    num_episodes: int = 500,
    max_steps_per_episode: int = 200
):
    for ep in range(1, num_episodes + 1):
        state = env.reset()
        total_reward = 0.0
        for t in range(max_steps_per_episode):
            action = agent.select_action(state)
            next_state, reward, done, _ = env.step(action)
            agent.store_transition(state, action, reward, next_state, float(done))
            agent.update()
            state = next_state
            total_reward += reward
            if done:
                break

        print(f"Episode {ep:3d} — total reward: {total_reward:.2f}")

if __name__ == "__main__":
    env   = KubernetesSchedulerEnv(namespace="production")
    agent = DQNAgent(
        state_shape=env.observation_space.shape,
        n_actions=env.action_space.n
    )
    train_loop(env, agent)
