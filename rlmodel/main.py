import gym
import numpy as np

from cluster import Cluster
from dqn_agent import DQNAgent
from app import App
from jmeter import JMeter

# ---- USER MUST DEFINE: environment, state_size, action_size ----
testingApp = App("/home/darius/licenta/RL-K8-Scheduler/testApp/deployment/deployment-test-app.yaml", "/home/darius/licenta/RL-K8-Scheduler/testApp/deployment/service-test-app.yaml") # deployments path
jmeter = JMeter("/home/darius/licenta/RL-K8-Scheduler/testApp/testFile/test-app-test.jmx") # jmeter test file path
jmeter.upload_test()
env = Cluster(testingApp, jmeter)  # example; replace with your env
state_size = len(env.get_state())  # example; replace with your env's state size
action_size = 3  # example; replace with your env's action size

# ---- HYPERPARAMETERS ----
num_episodes = 500
max_steps_per_ep = 200

agent = DQNAgent(
    state_dim=state_size,
    action_dim=action_size,
    lr=1e-3,
    gamma=0.99,
    buffer_size=50_000,
    batch_size=64,
    eps_start=1.0,
    eps_end=0.01,
    eps_decay=10_000,
    target_update_freq=500
)

# ---- MAIN TRAINING LOOP ----
for episode in range(1, num_episodes + 1):
    state = env.reset()
    total_reward = 0.0

    for t in range(max_steps_per_ep):
        # 1. Select action
        action = agent.select_action(state)

        # 2. Step the env
        next_state, reward, done, _ = env.step(action)

        # 3. Store transition & learn
        agent.store(state, action, reward, next_state, float(done))
        agent.update()

        state = next_state
        total_reward += reward

        if done:
            break

    print(f"Episode {episode:3d} | Reward: {total_reward:.2f}")

# ---- RUNNING A TRAINED AGENT ----
state = env.reset()
done = False
while not done:
    action = agent.select_action(state)
    state, _, done, _ = env.step(action)
    env.render()
