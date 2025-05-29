import gym
import numpy as np

from cluster import Cluster
from dqn_agent import DQNAgent
from app import App
from jmeter import JMeter
from node import Node



# ---- USER MUST DEFINE: environment, state_size, action_size ----
print("Initialized testing app: /home/darius/licenta/RL-K8-Scheduler/testApp/deployment/deployment-test-app.yaml")
testingApp = App("/home/darius/licenta/RL-K8-Scheduler/testApp/deployment/deployment-test-app.yaml", "/home/darius/licenta/RL-K8-Scheduler/testApp/deployment/service-test-app.yaml") # deployments path
print("Initialized JMeter test file: /home/darius/licenta/RL-K8-Scheduler/testApp/testFile/test-app-test.jmx")
jmeter = JMeter("/home/darius/licenta/RL-K8-Scheduler/testApp/testFile/test-app-test.jmx") # jmeter test file path
jmeter.upload_test()
print("Initialized cluster environment")
env = Cluster(testingApp, jmeter)  # example; replace with your env

def add_nodes_to_cluster():
    global action_size, env
    env.reset()
    for i in range(3):
        node = Node(str(i), None)
        env.add_node(node)

add_nodes_to_cluster()  # Add nodes to the cluster
print("Added nodes to the cluster.")
state_size = len(env.get_state())  # example; replace with your env's state size
action_size = env.action_space.n

# ---- HYPERPARAMETERS ----
num_episodes = 500
max_steps_per_ep = 200

agent = DQNAgent(
    state_dim=state_size,         # Number of features in the environment state (input size for the network)
    action_dim=action_size,       # Number of possible actions (output size for the network)
    lr=1e-3,                      # Learning rate for the optimizer (how fast the network updates its weights)
    gamma=0.99,                   # Discount factor for future rewards (close to 1 means future rewards are important)
    buffer_size=50_000,           # Maximum number of transitions stored in the replay buffer (affects memory and sample diversity)
    batch_size=64,                # Number of transitions sampled per training step (affects stability and speed of learning)
    eps_start=1.0,                # Initial epsilon for ε-greedy exploration (probability of random action at the start)
    eps_end=0.01,                 # Minimum epsilon (lowest probability of random action, for more exploitation)
    eps_decay=10_000,             # Decay rate for epsilon (how quickly exploration decreases)
    target_update_freq=500        # How often to update the target network (in steps, for stable Q-learning)
)

model_file = ""
user_input = input("Write the path to the model file, or press Enter to create a new file: ")
if user_input == "":
    user_input = input("Write the path to the new model file: ")
    model_file = user_input
else:
    model_file = user_input
    # Load the model if the file exists
    try:
        agent.load(model_file)
        print(f"Model loaded from {model_file}")
    except FileNotFoundError:
        print(f"No model found at {model_file}, starting training from scratch.")

run_mode = input("Write 'train' to train the agent, or 'test' to run a trained agent: ").strip().lower()
if run_mode == 'train':
    print("Training mode selected.")
# ---- MAIN TRAINING LOOP ----
    for episode in range(1, num_episodes + 1):
        add_nodes_to_cluster()
        state = env.reset()
        total_reward = 0.0

        for t in range(max_steps_per_ep):
            # 1. Select action
            action = agent.select_action(state)

            # 2. Step the env
            next_state, reward, done, _, _ = env.step(action)

            # 3. Store transition & learn
            agent.store(state, action, reward, next_state, float(done))
            agent.update()

            state = next_state
            total_reward += reward

            if done:
                break

        print(f"Episode {episode:3d} | Reward: {total_reward:.2f}")
        # Save the model every 10 episodes
        if episode % 10 == 0:
            agent.save(model_file)
            print(f"Model saved to {model_file} at episode {episode}")
        # Update target network every 1000 steps
        if episode % agent.target_update_freq == 0:
            agent.target_net.load_state_dict(agent.policy_net.state_dict())
            print(f"Target network updated at episode {episode}")
else:
    # ---- RUNNING A TRAINED AGENT ---- # need to write testing code
    print("Testing mode selected.")
    agent.load(model_file)
    add_nodes_to_cluster()
    state = env.reset()
    done = False
    while not done:
        action = agent.select_action(state)
        state, _, done, _ = env.step(action)
        env.render()
