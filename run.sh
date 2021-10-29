#!/bin/bash
# set -eux
set -e

FROM_DIR=${PWD}/repo/
TO_DIR='$HOME/exp-node'
# FROM_DIRにある直下のディレクトリを取得する(複数存在する場合の作業ディレクトリ指定は後日対応)
REPO=($(ls ${FROM_DIR}))
WORK_DIR=${TO_DIR}/${REPO}
echo "Work Dir: ${WORK_DIR}"

NODE_TEXT_PATH="node.txt"
SETUP_PATH="setup_command.txt"
EXECUTE_PATH="execute_command.txt"
TO_HOSTS=()
NODES=()

# check exists of from_dir
if [ ! -d ${FROM_DIR} ]; then
    echo "from_dir is not exists"
    exit 1
fi

# check exists of node.txt
if [ ! -f ${NODE_TEXT_PATH} ]; then
    echo "node.txt is not found."
    exit 1
fi

# read node.txt
while read line; do
    # check line
    if [ -z "${line}" ]; then
        continue
    fi
    host=`echo ${line} | cut -d ',' -f 1`
    numbers=`echo ${line} | cut -d ',' -f 2`
    echo "Host: ${host} x ${numbers}"
    TO_HOSTS+=(${host})
    NODES+=(${numbers})
done < <(cat ${NODE_TEXT_PATH})

ssh_timeout_status () {
    ssh -o "ConnectTimeout 5" $1 :     > \
    /dev/null 2>&1                     ; \
    echo $?
}

# check ssh connection
for host in ${TO_HOSTS[@]}; do
    echo ""
    echo "check ssh connection to ${host}"
    if [ "`ssh_timeout_status ${host}`" -ne 0 ]; then
        echo "ssh connection to ${host} is failed."
        exit 1
    fi
    echo "connection ok."
done

# rsyncでリポジトリを送る
for host in ${TO_HOSTS[@]}; do
    echo ""
    ssh ${host} "mkdir -p ${TO_DIR}"
    echo "rsync to ${host}"
    rsync -archvz ${FROM_DIR} ${host}:${TO_DIR}
done

# 複数ホストに対して、setup_commandとexecute_commandをノードの数だけ実行する
for ((i=0; i<${#NODES[@]}; i++)); do
    echo ""
    # if setup_command is exists or not blank, executed
    if [ -f ${SETUP_PATH} ]; then
        setup_command=`cat ${SETUP_PATH}`
        echo "setup_command: ${setup_command}"
        ssh ${TO_HOSTS[${i}]} "nohup bash -c 'cd ${WORK_DIR}; ${setup_command}' > tmp.txt 2>&1 &"
    fi
    # if execute_command is exists or not blank, executed
    if [ -f ${EXECUTE_PATH} ]; then
        execute_command=''
        for ((j=0; j<${NODES[i]}; j++)); do
            execute_command+="`cat ${EXECUTE_PATH}`; "
        done
        echo "execute command on ${TO_HOSTS[i]} x ${NODES[i]}"
        ssh ${TO_HOSTS[${i}]} "nohup bash -c 'cd ${WORK_DIR}; ${execute_command}' > tmp.txt 2>&1 &" &
    fi
done
