#!/bin/bash

check_sys(){
    local checkType=$1
    local value=$2

    release=''
    systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

check_ins(){
    if type $1 >/dev/null 2>&1 
    then
    ins_stats=1
    else
    ins_stats=0
    fi
}
privoxy_ins(){
    check_sys
    check_ins privoxy
    if [ ${ins_stats} -eq 0 ]
then
    ${systemPackage} install -y privoxy
fi
    echo 'forward-socks5 / 127.0.0.1:10808 .' >> /etc/privoxy/config
    echo "export http_proxy=http://127.0.0.1:8118" >> /etc/profile
    echo "export https_proxy=http://127.0.0.1:8118" >> /etc/profile
    echo "export no_proxy=localhost" >> /etc/profile
    source /etc/profile
}
init(){
mkdir -p /usr/local/v2ray
wget http://tf.yyg.ink/V2ray_Core/v2ray-linux-64.zip -O /usr/local/v2ray/v2ray-linux-64.zip
check_sys
check_ins unzip
if [ ${ins_stats} -eq 0 ]
then
    ${systemPackage} install -y unzip
fi
    unzip /usr/local/v2ray/v2ray-linux-64.zip -d /usr/local/v2ray/
    rm -rf /usr/local/v2ray/v2ray-linux-64.zip
    sed -i "s|ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json|ExecStart=/usr/local/v2ray/v2ray -config /usr/local/v2ray/config.json|" /usr/local/v2ray/systemd/system/v2ray.service
    sed -i "s|Description=V2Ray Service|Description=V2Ray Proxy By Bana|" /usr/local/v2ray/systemd/system/v2ray.service
    cp /usr/local/v2ray/systemd/system/v2ray.service /usr/lib/systemd/system/v2proxy.service
    systemctl daemon-reload
    ln -s /usr/local/v2ray/v2ray /usr/bin/v2ray
privoxy_ins
    systemctl enable v2proxy
    systemctl enable privoxy
}
check_v2proxy(){
    check_ins privoxy
    if [ ${ins_stats} -eq 0 ];then
    ins_privoxy=0
    else
    ins_privoxy=1
    fi
        check_ins v2ray
    if [ ${ins_stats} -eq 0 ];then
    ins_v2ray=0
    else
    ins_v2ray=1
    fi
    
    }
stop(){
    sed -i "s|export http_proxy=http://127.0.0.1:8118||g" /etc/profile
    sed -i "s|export https_proxy=http://127.0.0.1:8118||g" /etc/profile
    sed -i "s|export no_proxy=localhost||g" /etc/profile
    cp /etc/profile /etc/profile.bak
    tr -s '\n' < /etc/profile.bak > /etc/profile
    rm -rf /etc/profile.bak
    source /etc/profile
    systemctl stop v2proxy
    systemctl stop privoxy
}
start(){
    systemctl restart v2proxy
    systemctl restart privoxy
    echo "export http_proxy=http://127.0.0.1:8118" >> /etc/profile
    echo "export https_proxy=http://127.0.0.1:8118" >> /etc/profile
    echo "export no_proxy=localhost" >> /etc/profile
    source /etc/profile
}
uninstall(){
    stop
    rm -rf /usr/local/v2ray
    ${systemPackage} remove privoxy -y
    rm -rf /usr/lib/systemd/system/v2proxy.service
    systemctl daemon-reload
}
menu(){
    if [ -z "$1" ];then
    echo "参数错误，请输入参数：init start stop并重试"
    echo "Parameter error, please enter the parameter: init start stop uninstall"
    echo
    elif [ "$1" == "init" ];then
    echo "开始安装配置v2proxy"
    echo "install and configuring v2proxy"
    echo
    init
    echo "安装已完成"
    echo "finished installing"
    echo "请自行添加替换/usr/local/v2ray/config.json文件然后使用start参数"
    echo "Please add and replace \"/usr/local/v2ray/config.json\" file and then use the start parameter"
    echo
    elif [ "$1" == "start" ];then
    echo "启动v2proxy"
    echo "start v2proxy"
    echo
    start
    echo "启动完成"
    echo "finished start"
    echo
    elif [ "$1" == "stop" ];then
    echo "停止v2proxy"
    echo "stop v2proxy"
    echo
    stop
    echo "停止完成"
    echo "finished stop"
    echo
    elif [ "$1" == "uninstall" ];then
    echo "卸载v2proxy"
    echo "uninstall v2proxy"
    echo
    uninstall
    echo "卸载完成"
    echo "finished uninstall"
    echo
    fi
}
clear
echo "Welcome to V2proxy install and configure script"
echo "This script built by Bana"
menu $1