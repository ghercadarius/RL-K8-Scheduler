# RL-K8-Scheduler

**RL Agent with resource simulation applications meant to showcase performance of agent compared to the default k8 scheduler**

# Project built by Gherca Darius for Undergraduate Thesis, 2025

---

## Project Overview

This project implements a **Reinforcement Learning (RL)** based Kubernetes scheduler that aims to optimize resource allocation and scheduling decisions compared to the default Kubernetes scheduler. The system uses **Deep Q-Learning (DQN)** to make intelligent scheduling decisions based on cluster state and resource utilization metrics, mainly focusing on prioritizing energy consumption by the CPU through RAPL sensors from Intel processors.

---

## Project Structure

### Core Components

#### `rlmodel/`
Contains the main RL implementation:
- `main.py` – Main training and testing entry point for the RL agent
- `app.py` – App class for managing the application for which the agent is trained upon
- `benchmark.py` – Class used to compare the model to the classic scheduler, represented through a simple Round-Robin based schedule algorithm
- `cluster.py` – Class used to represent the environment for the DQN algorithm, and also store information about the cluster with the nodes and the actions associated
- `dqn_agent.py` – The algorithms used for the agent to make the decisions and store the learnt information
- `jmeter.py` – Class that interacts with the testing container to simulate users on the application to gather contextual metrics about the deployed app
- `node.py` - Class that represents a node from a logical, and physical perspective, gathering simulated and real metrics
- `qnetwork.py` – The neuronal network used in the DQN algorithm
- `replay_buffer.py` – The DQN's replay buffer for the agent to go through
- `resource_blocker.py` – Class to interact and manage the blocking of the resources, as well as deleting and creating the pod for this service

Also, it contains the trained models. The longest trained one is Dale.pth ( ~ 27 hours ).

---

### Containers

Resource-intensive applications for testing and simulation:

#### `cpuIntensive/`
CPU-bound application with Fibonacci computation
- `app.py` – Flask app with CPU-intensive operations
- `Dockerfile` – Container definition
- `requirements.txt` – Python dependencies

#### `ramIntensive/`
Memory allocation testing application
- `app.py` – Flask app for memory load testing
- `Dockerfile` – Container definition

#### `diskIntensive/`
Disk I/O intensive application
- `app.py` – Flask app with read/write operations
- `Dockerfile` – Container definition

#### `networkIntensive/`
Network bandwidth testing
- `Dockerfile` – Container definition

#### `resourceBlocker/`
Comprehensive resource consumption simulator
- `app.py` – Incorporates all of the before mentioned apps in one application to better manage the blocking of resources when training
- `Dockerfile` – Container definition

- `makerun.sh` – Build and deployment script for containers

---

### Cluster Management

### `clusters/`
Kubernetes cluster setup and management through KVM's - not fully functional:
- `cloud-init-master.yaml` – Cloud-init configuration for master nodes
- `cloud-init-worker.yaml` – Cloud-init configuration for worker nodes
- `create_vm_remote_host.sh` – VM creation script

#### `scpCluster/`
SCP-based cluster deployment:
- `startScript.sh` – Main cluster creation script
- `masterNode.sh` – Master node setup script

#### `scpScripts/`
Helper scripts for cluster configuration:
- `master.sh` – Master node configuration script
- `worker.sh` – Worker node configuration script
- `comenzi.txt` – Manual setup commands

---

### `cloud/`
Scripts to create and deploy a kubernetes cluster on the cloud

---

### `minikube/`
Kubernetes cluster creation with a one node environment - the final solution used:
- `start.sh` – Minikube cluster setup script
- `deployments/` – Folder for all the necessary deployments - resource blocker, node exporter - and associated services
- `host_scripts/` – Folder for the bash scripts to be used on the machine upon which the cluster is being run - scripts to gather power metrics, CPU metrics etc.
- `prometheus/` – Folder for the prometheus configuration

Very important script that is ran on the host machine for the cluster - `kvm_power_monitor.sh`.

This script measures the wattage of the KVM made by minikube. The results are in miliWatts per 100ms. The script polls for power consumption to the RAPL sensor ( works only on Intel compatible processors ) and averages the burst time of the qemu process on the measured power of the processor and directly attributes the percentage of the burst time to the total power used by the CPU.

---

### Testing Applications

#### `testApp/`
Application for testing scheduler performance:
- `container/` – Test application container
- `Dockerfile` – Container definition
- `requirements.txt` – Dependencies
- `deployment/` – Folder for deployment and service for the test app
- `testFile/` - jMeter test plan used by the testing app for simulating users against the app

#### `jmeterDocker/`
JMeter load testing REST application meant to be used in the training process to simulate users through http request calls. 

---

### Demo Applications

#### `demoApp/`
Scrapped Sample application

#### `OnlineStore/`
E-commerce backend service for realistic workload testing:
- `backendService/backend/`
  - `Program.cs` – ASP.NET Core application entry point
  - `Data/ApplicationDbContext.cs` – Entity Framework database context
  - `Mapping/MappingProfile.cs` – AutoMapper configuration

Scrapped because of too much complexity and not enough infrastructure power to train.

---

## Key Features

- **RL-Based Scheduling**: Uses Deep Q-Learning to make scheduling decisions based on cluster state  
- **Resource Simulation**: Multiple containerized applications that simulate different resource consumption patterns  
- **Performance Benchmarking**: Comparison between RL scheduler and default Kubernetes scheduler  
- **Multi-Environment Support**: Works fully with Minikube, cloud clusters, and has configuration files for bare-metal setups with KVM's
- **Comprehensive Monitoring**: Prometheus integration for metrics collection  
- **Load Testing**: JMeter integration for performance testing for metrics

---

## Getting Started

1. **Setup Environment**: Use scripts in `/minikube/` - `start.sh` to start the cluster and the associated local docker containers - prometheus and app for simulating users with jMeter - and `stop.sh` to reset the state
2. **Build Containers**: Run `makerun.sh` to build resource blocker app and dockercompose with push for jmeterDocker simulating app and `makeImage.sh` for the app to test the scheduler
3. **Train RL Agent**: Execute `main.py` to train the scheduling agent and select the model file, if it exists, or create it by giving a new name, and select the desired mode: `train` or `test`  
4. **Run Tests**: Use the app in `/testApp/` for training and testing the scheduler and `/jmeterDocker/` for simulating users with jMeter through http requests. 

---

## Architecture

The system consists of:

- **RL Scheduler**: Makes pod placement decisions based on learned policies  
- **Resource Blockers**: Simulate various workload types and resource consumption patterns  
- **Monitoring Stack**: Collects metrics for training and evaluation  
- **Testing Framework**: Benchmarks scheduler performance against baselines

---

This project demonstrates how **machine learning can be applied to improve Kubernetes scheduling decisions** by learning from cluster behavior and resource utilization patterns, mainly energy usage.
