import copy
import numpy as np

def compare_rl_vs_round_robin(agent, env, num_episodes=20, max_steps=200):
    rl_rewards = []
    rr_rewards = []
    node_count = env.action_space.n

    for ep in range(num_episodes):
        # Reset environment and add nodes
        env.reset()
        env.add_nodes_to_cluster()
        state = env.get_state()

        # Deepcopy the env for fair comparison
        env_rr = copy.deepcopy(env)
        env_rl = copy.deepcopy(env)

        # --- RL agent ---
        state_rl = env_rl.get_state()
        total_reward_rl = 0.0
        done_rl = False
        steps_rl = 0
        agent.epsilon = 0.0  # no exploration during test

        while not done_rl and steps_rl < max_steps:
            action_rl = agent.select_action(state_rl)
            next_state_rl, reward_rl, done_rl = env_rl.step(action_rl)
            state_rl = next_state_rl
            total_reward_rl += reward_rl
            steps_rl += 1

        # --- Round Robin agent ---
        state_rr = env_rr.get_state()
        total_reward_rr = 0.0
        done_rr = False
        steps_rr = 0
        current_node = 0

        while not done_rr and steps_rr < max_steps:
            action_rr = current_node
            next_state_rr, reward_rr, done_rr = env_rr.step(action_rr)
            state_rr = next_state_rr
            total_reward_rr += reward_rr
            steps_rr += 1
            current_node = (current_node + 1) % node_count

        rl_rewards.append(total_reward_rl)
        rr_rewards.append(total_reward_rr)
        print(f"[EP {ep+1:2d}] RL reward: {total_reward_rl:.2f} | RR reward: {total_reward_rr:.2f} | Steps RL: {steps_rl} | Steps RR: {steps_rr}")

    print("\n==== Comparison Results ====")
    print(f"RL avg reward: {np.mean(rl_rewards):.2f} ± {np.std(rl_rewards):.2f}")
    print(f"RR avg reward: {np.mean(rr_rewards):.2f} ± {np.std(rr_rewards):.2f}")
    print(f"RL min/max: {np.min(rl_rewards):.2f} / {np.max(rl_rewards):.2f}")
    print(f"RR min/max: {np.min(rr_rewards):.2f} / {np.max(rr_rewards):.2f}")
    return rl_rewards, rr_rewards

