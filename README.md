## cumulus-ansible-intermediate-mlag-nclu

### Summary:

  - Cumulus Linux 3.7.11
  - Underlying Topology Converter to 4.7.0
  - Tested against Vagrant 2.1.5 on Mac and Linux. Windows is not supported.
  - Tested against Virtualbox 5.2.32 on Mac 10.14
  - Tested against Libvirt 1.3.1 and Ubuntu 16.04 LTS

### Description:

This is an Ansible demo which configures two Cumulus VX switches in an MLAG configuration with a Linux server. This demo will utilize the Ansible Cumulus NCLU module.

### Network Diagram:

![Network Diagram](https://github.com/chronot1995/int-ansible-training-clag-nclu/blob/master/documentation/int-ansible-training-clag-nclu.png)

### Install and Setup Virtualbox on Mac

Setup Vagrant for the first time on Mojave, MacOS 10.14.6

1. Install Homebrew 2.1.9 (This will also install Xcode Command Line Tools)

    https://brew.sh

2. Install Virtualbox (Tested with 5.2.32)

    https://www.virtualbox.org

I had to go through the install process twice to load the proper security extensions (System Preferences > Security & Privacy > General Tab > "Allow" on bottom)

3. Install Vagrant (Tested with 2.1.5)

    https://www.vagrantup.com

### Install and Setup Linux / libvirt demo environment:

First, make sure that the following is currently running on your machine:

1. This demo was tested on a Ubuntu 16.04 VM w/ 4 processors and 32Gb of Diagram

2. Following the instructions at the following link:

    https://docs.cumulusnetworks.com/cumulus-vx/Development-Environments/Vagrant-and-Libvirt-with-KVM-or-QEMU/

3. Download the latest Vagrant, 2.1.5, from the following location:

    https://www.vagrantup.com/

### Initializing the demo environment:

1. Copy the Git repo to your local machine:

```
    git clone https://github.com/chronot1995/cumulus-ansible-intermediate-mlag-nclu/
```

2. Change directories to the following

```
    cumulus-ansible-intermediate-mlag-nclu
```

3a. Run the following for Virtualbox:

```
    ./start-vagrant-vbox-poc.sh
```

3b. Run the following for Libvirt:

```
    ./start-vagrant-libvirt-poc.sh
```

### Running the Ansible Playbook

1a. SSH into the Virtualbox oob-mgmt-server:

```
    cd vx-vbox-simulation
    vagrant ssh oob-mgmt-server
```

1a. SSH into the Libvirt oob-mgmt-server:

```
    cd vx-libvirt-simulation  
    vagrant ssh oob-mgmt-server
```

2. Copy the Git repo unto the oob-mgmt-server:

```
    git clone https://github.com/chronot1995/cumulus-ansible-intermediate-mlag-nclu
```

3. Change directories to the following

```
    cumulus-ansible-intermediate-mlag-nclu/automation
```

4. Run the following:

```
    ./provision.sh
```

This will run the automation script and configure the environment.

### Troubleshooting

Helpful NCLU troubleshooting commands:

- net show clag
- net show interface bonds
- net show interface bondmems
- net show route
- net show interface | grep -i UP
- net show lldp

Helpful Linux troubleshooting commands:

- ip route
- ip link show
- ip address <interface>
- cat /proc/net/bonding/uplink

The MLAG status command will verify the MLAG peer status:

```
cumulus@switch01:mgmt-vrf:~$ net show clag status
The peer is alive
     Our Priority, ID, and Role: 100 44:38:39:00:00:05 primary
    Peer Priority, ID, and Role: 100 44:38:39:00:00:06 secondary
          Peer Interface and IP: peerlink.4094 fe80::4638:39ff:fe00:6 (linklocal)
                      Backup IP: 192.168.200.2 vrf mgmt (active)
                     System MAC: 44:38:39:ff:01:56

CLAG Interfaces
Our Interface      Peer Interface     CLAG Id   Conflicts              Proto-Down Reason
----------------   ----------------   -------   --------------------   -----------------
          bond01   bond01             1         -                      -
```

The most important link is the status of the "Backup IP." In the above, it is set to "active," which means that the two switches will form an LACP connection to the downstream server.

One can see the various LACP interfaces and which bond / LACP member that they belong to:

```
cumulus@switch01:mgmt-vrf:~$ net show interface bondmems
    Name    Speed      MTU  Mode     Summary
--  ------  -------  -----  -------  --------------------
UP  swp1    1G        1500  LACP-UP  Master: bond01(DN)
UP  swp2    1G        1500  LACP-UP  Master: peerlink(UP)
UP  swp3    1G        1500  LACP-UP  Master: peerlink(UP)
```

One can also see the bonds in a more concise output:

```
cumulus@switch01:mgmt-vrf:~$ net show interface bonds
    Name      Speed      MTU  Mode    Summary
--  --------  -------  -----  ------  --------------------------------
DN  bond01    N/A       1500  LACP    Bond Members: swp1(UP)
UP  peerlink  2G        1500  LACP    Bond Members: swp2(UP), swp3(UP)
```

There currently is no NCLU command to view the VRR interface. The easiest way is to check the "UP" state on the "-v" interface using Linux's "ip" command:

```
cumulus@switch01:mgmt-vrf:~$ ip address show | grep vlan100
40: vlan100@bridge: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    inet 172.16.121.2/24 scope global vlan100
41: vlan100-v0@vlan100: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    inet 172.16.121.1/24 scope global vlan100-v0
```

On the Linux server itself, one can view the status of the LACP bond on the "uplink" interface with the following command:

```
cumulus@server01:~$ cat /proc/net/bonding/uplink | grep Status
MII Status: up
MII Status: up
MII Status: up
```

The Linux server will be able to ping the VRR gateway (.1), and each leaf IP (.2, .3):

```
cumulus@server01:~$ ping 172.16.121.1
PING 172.16.121.1 (172.16.121.1) 56(84) bytes of data.
64 bytes from 172.16.121.1: icmp_seq=1 ttl=64 time=2.10 ms
^C
--- 172.16.121.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 2.100/2.100/2.100/0.000 ms

cumulus@server01:~$ ping 172.16.121.2
PING 172.16.121.2 (172.16.121.2) 56(84) bytes of data.
64 bytes from 172.16.121.2: icmp_seq=1 ttl=64 time=1.09 ms
^C
--- 172.16.121.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.095/1.095/1.095/0.000 ms

cumulus@server01:~$ ping 172.16.121.3
PING 172.16.121.3 (172.16.121.3) 56(84) bytes of data.
64 bytes from 172.16.121.3: icmp_seq=1 ttl=64 time=1.02 ms
64 bytes from 172.16.121.3: icmp_seq=2 ttl=64 time=1.08 ms
^C
--- 172.16.121.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.022/1.055/1.089/0.046 ms
```

### Errata

1. To shutdown the demo, run the following command from the vx-simulation directory:

```
vagrant destroy -f
```

2. This topology was configured using the Cumulus Topology Converter found at the following URL:

    https://github.com/CumulusNetworks/topology_converter

3. The following command was used to run the Topology Converter within the appropriate vx-sim directory:

```
     ./topology_converter.py cumulus-ansible-intermediate-mlag-nclu.dot -c --provider=virtualbox
     ./topology_converter.py cumulus-ansible-intermediate-mlag-nclu.dot -c --provider=libvirt
```

After the above command is executed, the following configuration changes are necessary:

4. Within "<vx-sim>/helper_scripts/auto_mgmt_network/OOB_Server_Config_auto_mgmt.sh"

The following stanza:

echo " ### Creating cumulus user ###"
useradd -m cumulus

Will be replaced with the following:

echo " ### Creating cumulus user ###"
useradd -m cumulus -m -s /bin/bash

The following stanza:

    #Install Automation Tools
    puppet=0
    ansible=1
    ansible_version=2.6.3

Will be replaced with the following:

    #Install Automation Tools
    puppet=0
    ansible=1
    ansible_version=2.9.3

Add the following ```echo``` right before the end of the file.

    echo " ### Adding .bash_profile to auto login as cumulus user"
    echo "sudo su - cumulus" >> /home/vagrant/.bash_profile
    echo "exit" >> /home/vagrant/.bash_profile
    echo "### Adding .ssh_config to avoid HostKeyChecking"
    printf "Host * \n\t StrictHostKeyChecking no\n" >> /home/cumulus/.ssh/config

    echo "############################################"
    echo "      DONE!"
    echo "############################################"
