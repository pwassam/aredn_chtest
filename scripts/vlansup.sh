#!/bin/bash
ip link add link eth0 name eth0.21 type vlan id 21
ip link add link eth0 name eth0.22 type vlan id 22
ip link add link eth0 name eth0.23 type vlan id 23
ip link add link eth0 name eth0.24 type vlan id 24

ifconfig eth0.21 10.196.91.82/29    # Radio 10.196.91.81
ifconfig eth0.22 10.196.91.66/29    # Radio 10.196.91.65
ifconfig eth0.23 10.196.76.34/29    # Radio 10.196.76.33
ifconfig eth0.24 10.196.72.114/29   # Radio 10.196.72.113
