ARG BASE
FROM $BASE

# update existing packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y

# configure vim environment
RUN pip install ansible-core
RUN ansible-pull -U https://github.com/karwojan/config_scripts playbooks/configure_local_vim.yaml

# setup PATH env
RUN echo 'export PATH=/opt/conda/bin:$PATH' >> /root/.bashrc

# install and run sshd
RUN apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
WORKDIR ~/
CMD ["/usr/sbin/sshd", "-D", "-p", "2222"]

