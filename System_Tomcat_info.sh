#!/bin/bash

# Function to collect OS information
function collect_sys_info() {
    echo "|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++|"
    echo "|                      OS INFO                            |"
    echo "|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++|"
    echo ""

    echo "--------------System Check--------------"
    IP_Address=$(ip addr show | grep 'state UP' -A 2 | grep "inet " | grep -v 127.0.0. | head -1 | cut -d" " -f6 | cut -d/ -f1)
    echo "IP: $IP_Address"
    Hostname=$(hostname -s)
    echo "Hostname: $Hostname"
    Architecture=$(getconf LONG_BIT)
    echo "Architecture: $Architecture"
    Kernel_Release=$(uname -r)
    echo "Kernel_Release: $Kernel_Release"
    Cpu_Cores=$(cat /proc/cpuinfo | grep "cpu cores" | uniq | awk -F ': ' '{print $2}')
    echo "Cpu_Cores: $Cpu_Cores"
    Cpu_Proc_Num=$(cat /proc/cpuinfo | grep "processor" | uniq | wc -l)
    echo "Cpu_Proc_Num: $Cpu_Proc_Num"
    LastReboot=$(who -b | awk '{print $3,$4}')
    echo "LastReboot: $LastReboot"
    Uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    echo "Uptime: $Uptime"
    Load=$(uptime | awk -F ":" '{print $NF}')
    echo "Load: $Load"

    # Memory Information
    MemTotal=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
    if [ $MemTotal -ge 1048576 ]; then
        MemTotalGB=$(awk "BEGIN {printf \"%.2f\", $MemTotal / 1024 / 1024}")
        echo "MemTotal: ${MemTotalGB} GB"
    fi

    MemFree=$(awk '/^MemFree/ {print $2}' /proc/meminfo)
    MemBuffers=$(awk '/^Buffers/ {print $2}' /proc/meminfo)
    MemCached=$(awk '/^Cached/ {print $2}' /proc/meminfo)
    MemUsed=$(($MemTotal - $MemFree - $MemBuffers - $MemCached))
    
    MemUsedGB=$(awk "BEGIN {printf \"%.2f\", $MemUsed / 1024 / 1024}")
    MemFreeGB=$(awk "BEGIN {printf \"%.2f\", $MemFree / 1024 / 1024}")
    MemRate=$(awk "BEGIN {printf \"%.2f\", ($MemUsed / $MemTotal) * 100}")

    echo "MemTotal: ${MemTotalGB} GB"
    echo "MemFree: ${MemFreeGB} GB"
    echo "MemUsed: ${MemUsedGB} GB"
    echo "Mem_Rate: ${MemRate}%"

    # Disk Usage
    Usesum=0
    Totalsum=0
    disknum=$(df -hlT | grep -v tmpfs | grep -v boot | grep -v overlay | wc -l)
    for ((n = 2; n <= $disknum + 1; n++)); do
        use=$(df -k | awk NR==$n'{print int($3)}')
        pertotal=$(df -k | awk NR==$n'{print int($2)}')
        Usesum=$(($Usesum + $use))
        Totalsum=$(($Totalsum + $pertotal))
    done
    Freesum=$(($Totalsum - $Usesum))
    Diskutil=$(awk "BEGIN {printf \"%.2f\", ($Usesum / $Totalsum) * 100}")
    Freeutil=$(awk "BEGIN {printf \"%.2f\", 100 - $Diskutil}")

    echo "Diskutil: ${Diskutil}%"
    echo "Freeutil: ${Freeutil}%"
    
    # CPU I/O Stats
    iostat=$(which iostat)
    if [ $? -eq 0 ]; then
        IO_User=$(iostat -x -k 2 1 | grep -1 avg | grep -v avg | awk '{print $1}')
        IO_System=$(iostat -x -k 2 1 | grep -1 avg | grep -v avg | awk '{print $4}')
        IO_Wait=$(iostat -x -k 2 1 | grep -1 avg | grep -v avg | awk '{print $5}')
        IO_Idle=$(iostat -x -k 2 1 | grep -1 avg | grep -v avg | awk '{print $NF}')
        echo "IO_User: ${IO_User}%"
        echo "IO_System: ${IO_System}%"
        echo "IO_Wait: ${IO_Wait}%"
        echo "IO_Idle: ${IO_Idle}%"
    else
        IO_User=$(top -n1 | fgrep "Cpu(s)" | tail -1 | awk '{print $2}')
        IO_System=$(top -n1 | fgrep "Cpu(s)" | tail -1 | awk '{print $4}')
        IO_Wait=$(top -n1 | fgrep "Cpu(s)" | tail -1 | awk '{print $10}')
        IO_Idle=$(top -n1 | fgrep "Cpu(s)" | tail -1 | awk '{print $8}')
        echo "IO_User: ${IO_User}%"
        echo "IO_System: ${IO_System}%"
        echo "IO_Wait: ${IO_Wait}%"
        echo "IO_Idle: ${IO_Idle}%"
    fi
}

# Function to collect Tomcat information
function collect_tomcat_info() {
    echo "|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++|"
    echo "|                     TOMCAT INFO                          |"
    echo "|+++++++++++++++++++++++++++++++++++++++++++++++++++++++++|"
    echo ""

    TOMCAT_PATH="/path/to/your/tomcat"
    if [ -d "$TOMCAT_PATH" ]; then
        # Tomcat version
        echo "Tomcat Version:"
        $TOMCAT_PATH/bin/version.sh

        # Check if Tomcat is running
        if pgrep -f 'org.apache.catalina.startup.Bootstrap' > /dev/null; then
            echo "Tomcat Status: Running"
        else
            echo "Tomcat Status: Not Running"
        fi

        # Tomcat memory usage
        TOMCAT_PID=$(pgrep -f 'org.apache.catalina.startup.Bootstrap')
        if [ -n "$TOMCAT_PID" ]; then
            echo "Tomcat PID: $TOMCAT_PID"
            echo "Memory Usage:"
            ps -p $TOMCAT_PID -o %mem,%cpu,comm
        else
            echo "Unable to determine memory usage. Tomcat may not be running."
        fi
    else
        echo "Tomcat directory not found at $TOMCAT_PATH. Please check the path."
    fi
}

# Main menu
while true; do
    echo "Select an option:"
    echo "1. Display System Information"
    echo "2. Display Tomcat Information"
    echo "3. Exit"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1) collect_sys_info ;;
        2) collect_tomcat_info ;;
        3) exit 0 ;;
        *) echo "Invalid option. Please choose 1, 2, or 3." ;;
    esac
done
