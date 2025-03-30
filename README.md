# chatbot - Your Local "ChatGPT" (Ollama) Setup

This README provides instructions on setting up Ollama, your own local ChatGPT-like experience, on Ubuntu with NVIDIA GPU acceleration using Docker and Portainer. 

## Prerequisites

* **Hardware:** A computer with an NVIDIA GPU that supports CUDA.
* **Software:** Ubuntu desktop distribution installed Ubuntu 24.04.2 LTS.

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
   - Reboot and fix potential issues
     ```bash
     sudo apt --fix-broken install
     sudo reboot now
     echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> ~/.bashrc
     echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.2/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
     source ~/.bashrc
     ```

3. **Docker Installation**
   - Install Docker Engine:
     ```bash
     sudo apt install docker.io
     sudo groupadd docker
     sudo usermod -aG docker $USER
     newgrp docker
     docker run hello-world
     ```
4. **Container Toolkit Installation**
   - Install Container Toolkit:
     ```bash
     sudo apt install curl
     curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
          sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
          sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
     sudo apt update
     sudo apt install -y nvidia-container-toolkit
     sudo nvidia-ctk runtime configure --runtime=docker
     sudo systemctl restart docker
     docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
     ```
     
5. **Portainer Installation**
   - Set up Portainer to manage your Docker containers:
     ```bash
     docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
     ```
     - Access Portainer at `https://0.0.0.0:9443/`

6. **Ollama Environment Setup**
   - Create the required folders on your system:
     ```bash
     mkdir /home/$USER/chatbot/
     mkdir /home/$USER/chatbot/searxng
     mkdir /home/$USER/chatbot/open-webui
     mkdir /home/$USER/chatbot/ollama
     ```
7. **Search Engine Configuration**
   - Create the required files on your system:
     ```bash
     echo "# see https://docs.searxng.org/admin/settings/settings.html#settings-use-default-settings
     use_default_settings: true
      
     server:
       secret_key: \"f9e603d4191caab069b021fa0568391a33c8a837b470892c64461b5dd12464f4\"
       limiter: false
       image_proxy: true
       port: 8080
       bind_address: \"0.0.0.0\"
      
     ui:
       static_use_hash: true
      
     search:
       safe_search: 0
       autocomplete: \"\"
       default_lang: \"\"
       formats:
         - html
         - json" > /home/$USER/chatbot/searxng/settings.yml
     ```
     ```bash
     echo "[botdetection.ip_limit]
     # activate link_token method in the ip_limit method
     link_token = true" > /home/$USER/chatbot/searxng/limiter.toml 
     ```
     ```bash
     echo "[botdetection.ip_limit]
     # activate link_token method in the ip_limit method
     link_token = true" > /home/$USER/chatbot/searxng/limiter.toml 
     
     ## searxng/uwsgi.ini
     echo "[uwsgi]
     # Who will run the code
     uid = searxng
     gid = searxng
     
     # Number of workers (usually CPU count)
     # default value: %k (= number of CPU core, see Dockerfile)
     workers = %k
     
     # Number of threads per worker
     # default value: 4 (see Dockerfile)
     threads = 4
     
     # The right granted on the created socket
     chmod-socket = 666
     
     # Plugin to use and interpreter config
     single-interpreter = true
     master = true
     plugin = python3
     lazy-apps = true
     enable-threads = 4
     
     # Module to import
     module = searx.webapp
     
     # Virtualenv and python path
     pythonpath = /usr/local/searxng/
     chdir = /usr/local/searxng/searx/
     
     # automatically set processes name to something meaningful
     auto-procname = true
      
     # Disable request logging for privacy
     disable-logging = true
     log-5xx = true
      
     # Set the max size of a request (request-body excluded)
     buffer-size = 8192
     
     # No keep alive
     # See https://github.com/searx/searx-docker/issues/24
     add-header = Connection: close
      
     # uwsgi serves the static files
     static-map = /static=/usr/local/searxng/searx/static
     # expires set to one day
     static-expires = /* 86400
     static-gzip-all = True
     offload-threads = 4" > /home/$USER/chatbot/searxng/uwsgi.ini
     ```
8. **Ollama Compose Configuration**
   - Copy the provided `docker-compose.yml` file into your project directory and modify it according to your needs:
     ```yaml
     version: '3.8'
      
     services:
       ollama-backend:
         image: ollama/ollama
         deploy:
                 resources:
                     reservations:
                         devices:
                             - driver: nvidia
                               count: all
                               capabilities:
                                   - gpu
         ports:
           - "11434:11434"
         volumes:
           - /home/viktor/chatbot/ollama:/root/.ollama
         restart: always
         container_name: ollama-backend
     
       ollama-openweb-ui:
         image: ghcr.io/open-webui/open-webui:main
         extra_hosts:
           - host.docker.internal:host-gateway
         environment:
           ENABLE_RAG_WEB_SEARCH: True
           RAG_WEB_SEARCH_ENGINE: "searxng"
           RAG_WEB_SEARCH_RESULT_COUNT: 3
           RAG_WEB_SEARCH_CONCURRENT_REQUESTS: 10
           SEARXNG_QUERY_URL: "http://searxng:8080/search?q=<query>"
      
      
         ports:
           - "3000:8080"
         volumes:
           - /home/viktor/chatbot/open-webui:/app/backend/data
         depends_on:
           - ollama-backend
         restart: always
         container_name: ollama-openweb-ui
      
       searxng:
         image: searxng/searxng:latest
         container_name: searxng
         ports:
           - "8180:8080"
         volumes:
           - /home/viktor/chatbot/searxng:/etc/searxng
      
         restart: always
     ```


9. **Deploy Ollama Containers**
   - In Portainer, import the `docker-compose.yml` file and start the containers.

10. **Access Ollama Web UI**
   - Once all containers are running, access the Ollama OpenWebUI at `http://localhost:3000`. 

## Troubleshooting

* If you encounter issues with GPU acceleration, double-check your CUDA installation and driver versions.
* Refer to the official documentation of Docker, Portainer, Ollama, and SearxNG for detailed troubleshooting guides.


##  Customization

* Modify the `docker-compose.yml` file to adjust port mappings, and other container settings. 
* Explore different Ollama models and configurations based on your performance requirements.



## Useful Links

* **Ollama:** https://ollama.com/
* **Ubuntu Download:** https://ubuntu.com/download/desktop
* **Install CUDA on Ubuntu:** https://www.cherryservers.com/blog/install-cuda-ubuntu
* **Portainer Documentation:** https://docs.portainer.io/start/install-ce/server/docker/linux
* **OpenWebUI GitHub:** https://github.com/open-webui/open-webui
