# chatbot - Your Local "ChatGPT" (Ollama) Setup

This README provides instructions on setting up Ollama, your own local ChatGPT-like experience, on Ubuntu with NVIDIA GPU acceleration using Docker and Portainer. 

## Prerequisites

* **Hardware:** A computer with an NVIDIA GPU that supports CUDA.
* **Software:** Ubuntu desktop distribution installed.

##  Step-by-Step Guide

1. **Ubuntu Installation & Driver Setup**
   - Follow these steps to ensure your system is ready:
     ```bash
     sudo apt update
     sudo apt upgrade 
     sudo apt install ubuntu-drivers-common
     sudo ubuntu-drivers devices
     sudo apt install nvidia-driver-535
     sudo reboot now
     nvidia-smi 
     ```

2. **NVIDIA CUDA Toolkit Installation**
   - Install the necessary CUDA tools:
     ```bash
     sudo apt install gcc
     gcc -v
     wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
     sudo dpkg -i cuda-keyring_1.1-1_all.deb
     sudo apt update 
     sudo apt install cuda
     ```

3. **Docker Installation**
   - Install Docker Engine:
     ```bash
     sudo apt install docker-ce docker-ce-cli containerd.io
     ```

4. **Portainer Installation**
   - Set up Portainer to manage your Docker containers:
     ```bash
     docker run -d -p 9000:9000 portainer/portainer-ce
     ```
     - Access Portainer at `http://localhost:9000`

5. **Ollama Environment Setup**
   - Create the required folders on your system:
     ```bash
     mkdir -p /home/viktor/chatbot/ollama 
     mkdir -p /home/viktor/chatbot/open-webui
     mkdir -p /home/viktor/chatbot/searxng
     ```

6. **Ollama Compose Configuration**
   - Copy the provided `docker-compose.yml` file into your project directory and modify it according to your needs:


7. **Deploy Ollama Containers**
   - In Portainer, import the `docker-compose.yml` file and start the containers.

8. **Access Ollama Web UI**
   - Once all containers are running, access the Ollama OpenWebUI at `http://localhost:3000`. 

## Troubleshooting

* If you encounter issues with GPU acceleration, double-check your CUDA installation and driver versions.
* Refer to the official documentation of Docker, Portainer, Ollama, and SearxNG for detailed troubleshooting guides.


##  Customization

* Modify the `docker-compose.yml` file to adjust port mappings, and other container settings. 
* Explore different Ollama models and configurations based on your performance requirements.


