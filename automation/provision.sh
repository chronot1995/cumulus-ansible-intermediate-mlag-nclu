#!/bin/bash
ansible-playbook -l switch01 cumulus-ansible-intermediate-mlag-nclu.yml
sleep 10
ansible-playbook -l switch02,server01 cumulus-ansible-intermediate-mlag-nclu.yml
