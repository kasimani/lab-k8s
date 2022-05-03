Setup will deploy Ubuntu based single Kubernetes master node and Worker nodes [Number of Worker nodes depends on how many you choose, for learning purpose, 2 should be fine]

To deploy this setup, one should have ansible installed and a pre-configured Ubuntu Qcow2 image, same can be downloaded using this link: http://172.21.166.204/master.qcow2

G-Drive Link: https://drive.google.com/file/d/18KCd9yJI29DgYoJxOkSrmyHbewBaoPSy/view?usp=sharing

**To start setup:**

Step 1: create Download the Ubuntu Qcow2 image on Ansible server under /tmp directory

Step 2: run populate_variables.sh, /bin/sh populate_variables.sh

Step 3: Run ansible script

**Steps Summary:**

## mkdir /kubernetes-install

## cd /kubernetes-install

## git clone https://github.com/kasimani/lab-k8s.git

## cd lab-k8s

## /bin/sh populate_variables.sh
 ![image](https://user-images.githubusercontent.com/4587953/166261071-c9d7265f-a0bf-4def-91bc-9d397f7409f4.png)


## ansible-playbook src/playbook/kubernetesvm_deploy.yml


**To destroy setup:**
## ansible-playbook src/playbook/destroy_kubernetes.yml

