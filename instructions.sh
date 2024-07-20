## UBUNTU https://ubuntu.com/download/desktop

##NVIDIA DRIVERS https://www.cherryservers.com/blog/install-cuda-ubuntu
sudo apt update
sudo apt upgrade 
sudo apt install ubuntu-drivers-common
sudo ubuntu-drivers devices
sudo apt install nvidia-driver-535
sudo reboot now
nvidia-smi

#NVIDIA CUDA https://developer.nvidia.com/cuda-downloads
sudo apt install gcc
gcc -v
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda
sudo apt --fix-broken install
sudo reboot now
nano ~/.bashrc
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.2/lib64\
                         ${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

#Save the file using Ctrl+x and y.Restart Terminal
nvcc -V

##DOCKER
sudo apt install docker.io
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world

##DOCKER and CUDA
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

##PORTAINER https://docs.portainer.io/start/install-ce/server/docker/linux
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

## PORTAINER WEB https://0.0.0.0:9443/

# Create folders for configs and populate with settings
mkdir /home/$USER/chatbot/searxng
mkdir /home/$USER/chatbot/open-webui
mkdir /home/$USER/chatbot/ollama

## Web Search https://docs.openwebui.com/tutorial/web_search/
## searxng/settings.yml

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


## searxng/limiter.toml
echo "[botdetection.ip_limit]
# activate link_token method in the ip_limit method
link_token = true" > /home/$USER/chatbot/searxng/limiter.toml 

## searxng/uwsgi.ini


##PORTAINER COMPOSE
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


