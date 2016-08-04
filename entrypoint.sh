#!/bin/bash

forward_all_signals_to() {
    SIGNALS=(SIGHUP SIGINT SIGTERM SIGQUIT SIGSTOP SIGUSR1 SIGUSR2);
    for SIGNAL in ${SIGNALS[@]}; do
        eval "trap \"printf \\\"\\n$0 forwarding signal $SIGNAL to pid $1.\\n\\\"; kill -$SIGNAL $1;\" \"$SIGNAL\";"
    done;
}

confirm_env_exists() {
    local NAME=$1;
    if [ -z "${!NAME}" ]; then
        printf "Missing env $NAME, cannot start.\n";
        exit 1;
    fi
}

for env in DOCKER_NETWORK; do
    confirm_env_exists $env;
done;

if [ -z "$OPENVPN_IF" ]; then
    OPENVPN_IF="tun0";
fi

exec 3< <(openvpn "$@");
OPENVPN_PID=$!;
forward_all_signals_to $OPENVPN_PID;

while read line; do
    case $line in
        *"Initialization Sequence Completed"*)
            printf "Openvpn started.\n";
            break;
            ;;
        *)
            printf " $line\n";
    esac
done <&3;

# exec 3<&-;

if [ -z "$MAIN_IF" ]; then
    MAIN_IF="eth0";
fi

printf "Setting up iptables $OPENVPN_IF $MAIN_IF\n";
iptables -t nat -A POSTROUTING -o $MAIN_IF -j MASQUERADE;
iptables -t nat -A POSTROUTING -o $OPENVPN_IF -j MASQUERADE;

printf "Setting up ip route to $DOCKER_NETWORK\n";
ip r a $DOCKER_NETWORK dev $OPENVPN_IF;

printf "tunnel-local ready\n";

tail -f /dev/null &
TAIL_PID=$!;
trap "kill -9 $TAIL_PID; exit 0;" SIGINT;
wait;

