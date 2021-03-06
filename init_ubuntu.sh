#!/bin/bash
# The script is spupport 'Ubuntu 14.04.3 LTS'
# By xielifeng On 2016-11-04

export PATH=$PATH:/usr/sbin:/usr/bin:/bin:/sbin

SYSCTL_CONFIG="/etc/sysctl.conf"
LIMIT_CONFIG="/etc/security/limits.conf"
LANG_CONFIG="/var/lib/locales/supported.d/local"
LANG_CFG_7="/etc/locale.conf"
SSHD_CONFIG="/etc/ssh/sshd_config"
SUDO_CONFIG="/etc/sudoers"
LOG_FILE="/tmp/check_result.log"
DISABLE_SERVICES="NetworkManager"
ZONE_CONFIG="/etc/localtime"

SYSCTL_CONF="""
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 0
"""

> $LOG_FILE

[ `id -u` != 0 ] && echo "Please use root username." && exit 1

## Backup config
backup_file(){
    CONF_NAME="$1"
    DATETIME=`date +%F`
    BACKUP_NAME="${CONF_NAME}-${DATETIME}.bak"
    \cp -f ${CONF_NAME} ${BACKUP_NAME}
}

write_log(){
    CONTENT="$*"
    NOW_TIME=`date +"%F %T"`
    echo "" >> $LOG_FILE
    echo -e "$NOW_TIME $CONTENT" >> $LOG_FILE
}

## Check Result 0 or 1
check_result(){
    RESULT_VAL="$?"
    VELUE="$1"
    if [[ $RESULT_VAL != 0 ]];then
        write_log "[ Error ] $VELUE is failed."
        exit 2
    else
        write_log "[ Ok ] $VELUE is successful."
    fi
}

disable_ssh_ipv6(){
    SSH_IPV4="ListenAddress 0.0.0.0"
    grep "^$SSH_IPV4" $SSHD_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "SSH ipv6 was disabled"
    else
        sed -i "s/#$SSH_IPV4/$SSH_IPV4/g" $SSHD_CONFIG
        check_result "SSH disable IPV6"
    fi
}

set_sysctl(){
    ## Set Kernel Parameters
    grep '^net.ipv6.conf.all.disable_ipv6 = 1' $SYSCTL_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "$SYSCTL_CONFIG was setted"
    else
        echo "" >> $SYSCTL_CONFIG
        echo "## By OPS On `date +%F`" >> $SYSCTL_CONFIG
        echo  "$SYSCTL_CONF" >> $SYSCTL_CONFIG
        check_result "Set system parameters in $SYSCTL_CONFIG"
    fi
}

set_lang(){
    if [ -f "$LANG_CONFIG" ];then
        echo 'en_US.UTF-8 UTF-8' > $LANG_CONFIG
        check_result "Set lang"
    fi
}

set_cpu_used(){
    ## Limit
    grep "* soft nofile 655350" $LIMIT_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "$LIMIT_CONFIG was setted\n`tail -n 10 $LIMIT_CONFIG`"
    else
        backup_file "$LIMIT_CONFIG"
        echo """* soft nofile 655350
* hard nofile 655350
* soft core unlimited
* hard core unlimited
""" >> $LIMIT_CONFIG
        check_result "Setting all user 'soft & hard' limit"
    fi
}

# ---- main:
disable_ssh_ipv6
set_sysctl
set_system
set_cpu_used