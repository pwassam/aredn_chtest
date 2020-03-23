#!/bin/bash

# This script assumes pubkey auth is available and that the LAN address are all reachable
# This will alter /etc/config/wireless on all the radios

# These are the Mesh addresses to iperf against
MESH_R_A=10.120.139.106
MESH_R_B=10.120.139.104
MESH_R_C=10.120.137.132
MESH_R_D=10.120.137.14

# These are the LAN addresses to administrate with
LAN_R_A=10.196.91.81
LAN_R_B=10.196.91.65
LAN_R_C=10.196.76.33
LAN_R_D=10.196.72.113
RADIOS=(${LAN_R_A} ${LAN_R_B} ${LAN_R_C} ${LAN_R_D})

function sshcmd () {
	ssh -oStrictHostKeyChecking=no -p2222 root@$1 -- "$2"
}

function setch () {
	sshcmd $1 "sed -iorig -r -e \"s/option channel '(\d+)'/option channel '$2'/\" /etc/config/wireless && /etc/init.d/network restart &" &
}

function reboot () {
	sshcmd $1 reboot
}

function startiperf () {
	echo "Start iperf on all nodes"
	for r in ${RADIOS[@]}; do
		sshcmd ${r} 'killall -q iperf3 ; iperf3 -s &'
	done

}

function sshall () {
	for r in ${RADIOS[@]}; do
		sshcmd ${r} $1
	done
} 

# All radios to ch 184
echo "Set channels -> 184"
for r in ${RADIOS[@]}; do
	setch ${r} 184
done
wait
sleep 30

startiperf 

# Get radio to radio baselines
echo "Baselines R_A"
sshcmd $LAN_R_A "iperf3 -c ${MESH_R_B} -t5 -Z -u -b1000m -J -O1" > data/A_B_baseline_1000.json 
sshcmd $LAN_R_A "iperf3 -c ${MESH_R_C} -t5 -Z -u -b1000m -J -O1" > data/A_C_baseline_1000.json 
sshcmd $LAN_R_A "iperf3 -c ${MESH_R_D} -t5 -Z -u -b1000m -J -O1" > data/A_D_baseline_1000.json 

echo "Baselines R_B"
sshcmd $LAN_R_B "iperf3 -c ${MESH_R_A} -t5 -Z -u -b1000m -J -O1" > data/B_A_baseline_1000.json 
sshcmd $LAN_R_B "iperf3 -c ${MESH_R_C} -t5 -Z -u -b1000m -J -O1" > data/B_C_baseline_1000.json 
sshcmd $LAN_R_B "iperf3 -c ${MESH_R_D} -t5 -Z -u -b1000m -J -O1" > data/B_D_baseline_1000.json 

echo "Baselines R_C"
sshcmd $LAN_R_C "iperf3 -c ${MESH_R_A} -t5 -Z -u -b1000m -J -O1" > data/C_A_baseline_1000.json 
sshcmd $LAN_R_C "iperf3 -c ${MESH_R_B} -t5 -Z -u -b1000m -J -O1" > data/C_B_baseline_1000.json 
sshcmd $LAN_R_C "iperf3 -c ${MESH_R_D} -t5 -Z -u -b1000m -J -O1" > data/C_D_baseline_1000.json 

echo "Baselines R_D"
sshcmd $LAN_R_D "iperf3 -c ${MESH_R_A} -t5 -Z -u -b1000m -J -O1" > data/D_A_baseline_1000.json 
sshcmd $LAN_R_D "iperf3 -c ${MESH_R_B} -t5 -Z -u -b1000m -J -O1" > data/D_B_baseline_1000.json 
sshcmd $LAN_R_D "iperf3 -c ${MESH_R_C} -t5 -Z -u -b1000m -J -O1" > data/D_C_baseline_1000.json 

speeds=`seq 1 30`

for speed in ${speeds}; do
	echo "common ${speeds}"
	sshcmd $LAN_R_A "iperf3 -c ${MESH_R_B} -t5 -Z -u -b${speed}m -J -O1" > data/A_B_common_${speed}.json &
	sshcmd $LAN_R_B "iperf3 -c ${MESH_R_A} -t5 -Z -u -b${speed}m -J -O1" > data/B_A_common_${speed}.json &
	sshcmd $LAN_R_C "iperf3 -c ${MESH_R_D} -t5 -Z -u -b${speed}m -J -O1" > data/C_D_common_${speed}.json &
	sshcmd $LAN_R_D "iperf3 -c ${MESH_R_C} -t5 -Z -u -b${speed}m -J -O1" > data/D_C_common_${speed}.json &
	wait
done

echo "184-183 setup"
setch $LAN_R_C 183
setch $LAN_R_D 183
wait
sleep 30
startiperf

for speed in ${speeds}; do
	echo "184-183 ${speeds}"
	sshcmd $LAN_R_A "iperf3 -c ${MESH_R_B} -t5 -Z -u -b${speed}m -J -O1" > data/A_B_184-183_${speed}.json &
	sshcmd $LAN_R_B "iperf3 -c ${MESH_R_A} -t5 -Z -u -b${speed}m -J -O1" > data/B_A_184-183_${speed}.json &
	sshcmd $LAN_R_C "iperf3 -c ${MESH_R_D} -t5 -Z -u -b${speed}m -J -O1" > data/C_D_184-183_${speed}.json &
	sshcmd $LAN_R_D "iperf3 -c ${MESH_R_C} -t5 -Z -u -b${speed}m -J -O1" > data/D_C_184-183_${speed}.json &
	wait
done


echo "184-182 setup"
setch $LAN_R_C 182
setch $LAN_R_D 182
wait
sleep 30
startiperf

for speed in ${speeds}; do
	echo "184-182 ${speeds}"
	sshcmd $LAN_R_A "iperf3 -c ${MESH_R_B} -t5 -Z -u -b${speed}m -J -O1" > data/A_B_184-182_${speed}.json &
	sshcmd $LAN_R_B "iperf3 -c ${MESH_R_A} -t5 -Z -u -b${speed}m -J -O1" > data/B_A_184-182_${speed}.json &
	sshcmd $LAN_R_C "iperf3 -c ${MESH_R_D} -t5 -Z -u -b${speed}m -J -O1" > data/C_D_184-182_${speed}.json &
	sshcmd $LAN_R_D "iperf3 -c ${MESH_R_C} -t5 -Z -u -b${speed}m -J -O1" > data/D_C_184-182_${speed}.json &
	wait
done


echo "184-181 setup"
setch $LAN_R_C 181
setch $LAN_R_D 181
wait
sleep 30
startiperf

for speed in ${speeds}; do
	echo "184-181 ${speeds}"
	sshcmd $LAN_R_A "iperf3 -c ${MESH_R_B} -t5 -Z -u -b${speed}m -J -O1" > data/A_B_184-181_${speed}.json &
	sshcmd $LAN_R_B "iperf3 -c ${MESH_R_A} -t5 -Z -u -b${speed}m -J -O1" > data/B_A_184-181_${speed}.json &
	sshcmd $LAN_R_C "iperf3 -c ${MESH_R_D} -t5 -Z -u -b${speed}m -J -O1" > data/C_D_184-181_${speed}.json &
	sshcmd $LAN_R_D "iperf3 -c ${MESH_R_C} -t5 -Z -u -b${speed}m -J -O1" > data/D_C_184-181_${speed}.json &
	wait
done


echo "184-180 setup"
setch $LAN_R_C 180
setch $LAN_R_D 180
wait
sleep 30
startiperf

for speed in ${speeds}; do
	echo "184-180 ${speeds}"
	sshcmd $LAN_R_A "iperf3 -c ${MESH_R_B} -t5 -Z -u -b${speed}m -J -O1" > data/A_B_184-180_${speed}.json &
	sshcmd $LAN_R_B "iperf3 -c ${MESH_R_A} -t5 -Z -u -b${speed}m -J -O1" > data/B_A_184-180_${speed}.json &
	sshcmd $LAN_R_C "iperf3 -c ${MESH_R_D} -t5 -Z -u -b${speed}m -J -O1" > data/C_D_184-180_${speed}.json &
	sshcmd $LAN_R_D "iperf3 -c ${MESH_R_C} -t5 -Z -u -b${speed}m -J -O1" > data/D_C_184-180_${speed}.json &
	wait
done




