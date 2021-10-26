#!/bin/bash

SCRIPT_DIR="."
SETTINGS_FILE="$SCRIPT_DIR/wb-mb-explorer.conf"
LOG_FILE="$SCRIPT_DIR/wb-mb-explorer.log"
DIALOG=${DIALOG=dialog}
tempfile=$(mktemp /tmp/bkp.XXXXXX)
trap "rm -f $tempfile" 0 1 2 5 15

#read_result_raw=0

clear

#Clear log file
echo "" >$LOG_FILE

# exit confirmation window
ExitDialog() {
    ${DIALOG} --yesno "$1" 5 70
    case $? in
    0)
        exit
        ;;
    1 | 255)

        MainMenu
        ;;
    esac
}

# InfoDialog() {
#     ${DIALOG} --msgbox "$1" 5 70
# }

# show message box
showMsgBox() {
    $DIALOG --title "$1" --msgbox "$2" 10 60
}

ReadCommunicationSettings() {
    if [[ (-e $SETTINGS_FILE) ]]; then
        COM_PORT=$(cat $SETTINGS_FILE | grep COM_PORT | sed -e 's/COM_PORT://')
        BAUDRATE=$(cat $SETTINGS_FILE | grep BAUDRATE | sed -e 's/BAUDRATE://')
        PARITY=$(cat $SETTINGS_FILE | grep PARITY | sed -e 's/PARITY://')
        STOPBITS=$(cat $SETTINGS_FILE | grep STOPBITS | sed -e 's/STOPBITS://')
        MB_ADDRESS=$(cat $SETTINGS_FILE | grep MB_ADDRESS | sed -e 's/MB_ADDRESS://')
        MB_REGISTER=$(cat $SETTINGS_FILE | grep MB_REGISTER | sed -e 's/MB_REGISTER://')
        MB_REG_TYPE=$(cat $SETTINGS_FILE | grep MB_REG_TYPE | sed -e 's/MB_REG_TYPE://')
        HOME_DIR="~"
    else
        $DIALOG --sleep 2 --title "INFO" --infobox "Configuration file not found! Default settings applied" 10 52
        COM_PORT=/dev/ttyRS485-1
        BAUDRATE=9600
        PARITY=none
        STOPBITS=2
        MB_ADDRESS=1
        MB_REGISTER=128
        MB_REG_TYPE=holding
        HOME_DIR="~"
    fi
}

SaveCommunicationSettings() {
    echo COM_PORT:$COM_PORT >$SETTINGS_FILE
    echo BAUDRATE:$BAUDRATE >>$SETTINGS_FILE
    echo PARITY:$PARITY >>$SETTINGS_FILE
    echo STOPBITS:$STOPBITS >>$SETTINGS_FILE
    echo MB_ADDRESS:$MB_ADDRESS >>$SETTINGS_FILE
    echo MB_REGISTER:$MB_REGISTER >>$SETTINGS_FILE
    echo MB_REG_TYPE:$MB_REG_TYPE >>$SETTINGS_FILE
}

SetCommunicationSettings() {
    ${DIALOG} --clear --help-button --ok-label "Select item" --cancel-label "Save settings" --help-label "Return to main menu" --title "WB MB EXPLORER" \
        --menu "\n Current communication settings: \n\
    \n\
    Port: $COM_PORT \n\
    Baudrate: $BAUDRATE \n\
    Parity: $PARITY \n\
    Stopbits: $STOPBITS \n\
    Device address: $MB_ADDRESS \n\
    Modbus register: $MB_REGISTER \n\
    Modbus register type: $MB_REG_TYPE \n\
    \n\n\
     
        Chose action to do" 28 100 15 \
        "Set port" "Current setting: $COM_PORT" \
        "Set baudrate" "Current setting: $BAUDRATE" \
        "Set parity" "Current setting: $PARITY" \
        "Set stopbits" "Current setting: $STOPBITS" \
        "Set device address" "Current setting: $MB_ADDRESS" \
        "Set Modbus register" "Current setting: $MB_REGISTER" \
        "Set register type" "Current setting: $MB_REG_TYPE" 2>${tempfile}

    case $? in
    0) case $(cat ${tempfile}) in
    "Set port") SetComPort ;;
    "Set baudrate") SetBaudrate ;;
    "Set parity") SetParity ;;
    "Set stopbits") SetStopBits ;;
    "Set device address") SetAddress ;;
    "Set Modbus register") SetMBRegister ;;
    "Set register type") SetMBRegType ;;
    esac ;;
    1) SaveCommunicationSettings ;;

        # 2 | 255)  ;;
    esac

    MainMenu

}

SetComPort() {
    COM_PORT=$($DIALOG --stdout --title "Please choose a port to use" --fselect /dev/ttyRS485 14 100)
    SetCommunicationSettings
}

SetBaudrate() {
    $DIALOG --title "Baudrate" --radiolist "Choose avaliable option for baudrate:" 20 61 5 \
        "1200" "bit/s" off \
        "4800" "bit/s" off \
        "9600" "bit/s" ON \
        "19200" "bit/s" off \
        "38400" "bit/s" off \
        "57600" "bit/s" off \
        "115200" "bit/s" off 2>$tempfile

    case $? in
    0) case $(cat ${tempfile}) in
    "1200") BAUDRATE="1200" ;;
    "4800") BAUDRATE="4800" ;;
    "9600") BAUDRATE="9600" ;;
    "19200") BAUDRATE="19200" ;;
    "38400") BAUDRATE="38400" ;;
    "57600") BAUDRATE="57600" ;;
    "115200") BAUDRATE="115200" ;;
    esac ;;
    1 | 255) MainMenu ;;
    esac

    SetCommunicationSettings
}

SetParity() {
    #logger -s "mbexplorer setparity"
    $DIALOG --title "Parity" --radiolist "Choose avaliable option for parity:" 20 61 5 \
        "N" "None" ON \
        "E" "Even" off \
        "O" "Odd" off 2>$tempfile

    case $? in
    0) case $(cat ${tempfile}) in
    "N") PARITY="none" ;;
    "E") PARITY="even" ;;
    "O") PARITY="odd" ;;
    esac ;;
        # 1 | 255) MainMenu ;;
    esac

    SetCommunicationSettings
}

SetStopBits() {
    $DIALOG --title "Stopbits" --radiolist "Choose avaliable option for stopbits:" 20 61 5 \
        "1" "1 stop bit" off \
        "2" "2 stop bits" ON 2>$tempfile

    case $? in
    0) case $(cat ${tempfile}) in
    "1") STOPBITS="1" ;;
    "2") STOPBITS="2" ;;
    esac ;;
        # 1 | 255) MainMenu ;;
    esac

    SetCommunicationSettings
}

SetAddress() {
    # #Creating address list
    # echo "1 address on" >$tempfile
    # for i in {2..246}; do
    #     echo "$i address off" >>$tempfile
    # done
    # echo "247 address off" >>$tempfile

    $DIALOG --title "Enter address of Modbus device" --inputbox "Enter address of Modbus device you wnat to work with (from 1 to 247)" 16 51 2>$tempfile

    case $? in
    0)
        value=$(cat ${tempfile})
        #echo $value
        #sleep 3
        if [[ ($value -ge 0) && ($value -le 248) && ($value%1 -eq 0) && ($value -ne "") ]]; then
            MB_ADDRESS=$value
        else
            #echo "else"
            showInfoBox "INFO" "Entered device address is incorrect!"
            #$DIALOG --sleep 2 --title "INFO" --infobox "Entered device address is incorrect!" 10 52
            #$DIALOG --title "INFO" --msgbox "Entered device address is incorrect!" 10 52
            SetAddress
        fi
        ;;
        # 1 | 255) MainMenu ;;
    esac

    SetCommunicationSettings
}

SetMBRegister() {

    $DIALOG --title "Enter address of Modbus register" --inputbox "Enter address of Modbus register in decimal or hex (0x12345)" 16 51 2>$tempfile

    case $? in
    0) if [[ ($(cat $tempfile) -ge 0) && ($(cat $tempfile) -le 30000) ]]; then
        MB_REGISTER=$(cat $tempfile)
    else
        $DIALOG --sleep 2 --title "INFO" --infobox "Wrong address was entered!" 10 52
    fi ;;
    esac
    SetCommunicationSettings

}

SetMBRegType() {
    $DIALOG --title "Register type" --radiolist "Choose avaliable option for register type:" 20 61 5 \
        "descrete" "destrete input (read)" off \
        "coil" "descrete output (read/write)" off \
        "input" "input register (read)" off \
        "holding" "holding register (read/write)" ON 2>$tempfile

    case $? in
    0) MB_REG_TYPE=$(cat ${tempfile}) ;;
    esac

    SetCommunicationSettings
}

modbusReadRaw() {

    # read_result_raw=$(modbus_client --debug -mrtu $COM_PORT -o100 -a$1 -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$2 -r$3 -c$4 2>&1)
    # echo $read_result_raw
    modbus_client --debug -mrtu $COM_PORT -o100 -a$1 -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$2 -r$3 -c$4 2>&1
}

modbusWrite() {
    #echo $(modbus_client -mrtu -pnone -s2 $COM_PORT -a$MB_ADDRESS -t0x03 -r$R -c$C | grep Data | sed 's/.*Data://' | sed 's/ //g')
    modbus_client -mrtu $COM_PORT --debug -o100 -a$MB_ADDRESS -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$MBFunction -r$MB_REGISTER $1
}

modbusReadHexValue() {
    echo $(modbusReadRaw $1 $2 $3 $4 | grep Data | sed -e 's/.*Data: //' -e 's/0x//g' -e 's/\s//g')
    #
    #
    #readRawResult=$(modbusReadRaw $1 $2 $3 $4)

    #readHexValue=$(echo $readRawResult | grep Data | sed -e 's/.*Data: //' -e 's/0x//g' -e 's/\s//g')
    #readRawResult2=$readRawResult
    #echo "$readHexValue"
}

valueHexToDec() {
    #echo $((16#$(echo $1 | sed 's/0x//g')))
    #echo $((0xff))

    if [[ "$1" = "0x0000" ]]; then
        echo "0"
    else
        #local clearHexVal=$(echo $1 | sed 's/0x
        echo $((16#$1))
    fi

    # echo $((16#$1))
}

modbusReadText() {
    #option -e for parsing characters
    echo -e $(modbusReadRaw $1 $2 $3 $4 | grep Data | sed -e 's/.*Data: //' -e 's/0x00/\\\x/g' -e 's/\s//g') | tr -d "\0"
}

readDeviceInfo() {
    while [ 1 ]; do
        echo "" >$tempfile

        #Device model
        echo "Device model:" $(modbusReadText $MB_ADDRESS 4 200 6) >>$tempfile

        #Device serial number
        local serialNumber=$(modbusReadHexValue $MB_ADDRESS 4 270 2)
        serialNumber=$(valueHexToDec $serialNumber)
        echo "Device serial number:" $serialNumber >>$tempfile

        #Device FW version
        echo "Device FW version:" $(modbusReadText $MB_ADDRESS 4 250 16) >>$tempfile
        #Device FW signature
        echo "Device FW signature:" $(modbusReadText $MB_ADDRESS 4 290 12) >>$tempfile
        #Device uptime
        echo "Device uptime (s):" $(valueHexToDec $(modbusReadHexValue $MB_ADDRESS 4 104 2)) >>$tempfile

        #sleep 2

        $DIALOG --backtitle "WB-MB-EXPLORER - programm for exploring Modbus network for devices and configuring them" --title "READ DEVICE INFO" --ok-label "Read again" --extra-button --extra-label "Main menu" --textbox $tempfile 20 90

        case $? in
        0) continue ;;
        3) MainMenu ;;
            # 2) MainMenu ;;
        esac
    done
}

ReadRegister() {
    stopSerialDriver
    #cat << EOF > $tempfile;

    while [ 1 ]; do
        echo "" >$tempfile
        echo "Reading from device using following communication settings:" >>$tempfile
        echo -e "Port $COM_PORT, Baudrate: $BAUDRATE, Parity: $PARITY, Stopbits: $STOPBITS, address $MB_ADDRESS\n" >>$tempfile
        echo "Modbus register: $MB_REGISTER, Register type: $MB_REG_TYPE" >>$tempfile
        echo "----------------------------------------------------------" >>$tempfile
        echo -e "\nResult: \n" >>$tempfile

        case $MB_REG_TYPE in
        "coil") MBFunction="0x01" ;;
        "descrete") MBFunction="0x02" ;;
        "holding") MBFunction="0x03" ;;
        "input") MBFunction="0x04" ;;
        esac

        #modbus_client $COM_PORT $MB_ADDRESS $BAUDRATE $STOPBITS $PARITY $MBFunction $MB_REGISTER >>$tempfile
        readResult=$(modbusReadHexValue $MB_ADDRESS $MBFunction $MB_REGISTER 1)
        #echo "hello $readRawResult2"
        #echo $readResult

        if [[ "$readResult" = "" ]]; then
            echo "Error reading register $MB_REGISTER" >>$tempfile
            echo "" >>$tempfile
            #echo "hello $readRawResult2" >>$tempfile
            echo $readRawResult #>$tempfile
            #sleep 2

        else
            echo "Read data (hex): 0x$readResult" >>$tempfile

            #readResult=$(modbusReadHexValue $readResult)
            #readResult=$(echo $((16#$readResult)))
            #readResult=$(echo $readResult | sed 's/)
            readResult=$(valueHexToDec $readResult)
            echo "Read data (dec): $readResult" >>$tempfile
            #echo "Reg data (dec): $((echo 16#$(echo $readResult | sed 's/0x//g')))) " >>$tempfile
        fi
        # readResult=$(modbusRead)
        # echo $readResult
        # if [[ $(echo $readResult | grep SUCCESS) ]]; then
        #     $(echo $readResult | grep Data) >>$tempfile
        #     #echo $readResult >>$tempfile
        # else
        #     echo "Error reading register"
        # fi

        $DIALOG --backtitle "WB-MB-EXPLORER - programm for exploring Modbus network for devices and configuring them" --title "READ REGISTER" --ok-label "Read register" --extra-button --extra-label "Write to register" --help-button --help-label "Main menu" --textbox $tempfile 20 90 # echo "start dialog" > $tempfile

        ButtonNumber=$?

        case $ButtonNumber in
        0) continue ;;
        3) WriteRegister ;;
        2) MainMenu ;;
        esac

    done

}

WriteRegister() {
    stopSerialDriver
    #ReadRegister

    # while [ 1 ]; do
    #     echo "Writing register with address $MB_ADDRESS using following communication settings:" >$tempfile
    #     echo "Port $COM_PORT, Baudrate: $BAUDRATE, Parity: $PARITY, Stopbits: $STOPBITS, address $MB_ADDRESS" >>$tempfile
    #     echo "Modbus register: $MB_REGISTER, Register type: $MB_REG_TYPE" >>$tempfile

    #     #REading selected register first
    #     case $MB_REG_TYPE in
    #     "coil") MBFunction="0x01" ;;
    #     "descrete") MBFunction="0x02" ;;
    #     "holding") MBFunction="0x03" ;;
    #     "input") MBFunction="0x04" ;;
    #     esac
    #     CurrentRegValue =`modbus_client -mrtu $COM_PORT --debug -o 300 -a$MB_ADDRESS -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$MBFunction -r$MB_REGISTER | grep Data | sed -e 's/Data://'`
    #     echo "Current register value: "$CurrentRegValue >> $tempfile
    #     dialog --title "MBEXPLORER WRITE ADDRESS" --help-button --exit-label "Write register" --help-label "Return to main menu" --textbox $tempfile 80 100
    #         case $? in
    #         2 | 255) break ;;
    #         esac
    case $MB_REG_TYPE in
    "coil") MBFunction="0x05" ;;
    "holding") MBFunction="0x06" ;;
    "descrete" | "input")
        $DIALOG --sleep 2 --title "INFO BOX" --infobox "Register type is $MB_REG_TYPE, can't write!" 10 52
        ReadRegister
        ;;
    esac

    $DIALOG --title "WRITE REGISTER" --inputbox "Enter new register value in decimal (100) or hex (0x64)" 16 51 2>$tempfile

    case $? in
    0) if [[ ($(cat $tempfile) -ge 0) && ($(cat $tempfile) -le 65535) ]]; then
        #&& ("$(cat $tempfile)" -ne "")
        #local
        MBRegisterNewValue=$(cat $tempfile)
    else
        $DIALOG --sleep 2 --title "INFO BOX" --infobox "Wrong new value was entered!" 10 52
        ReadRegister
    fi ;;
    esac

    #modbus_client -mrtu $COM_PORT --debug -o 300 -a$MB_ADDRESS -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$MBFunction -r$MB_REGISTER $MBRegisterNewValue >$tempfile
    #modbusWrite
    local writeResult=$(modbusWrite $MBRegisterNewValue)
    # echo "1 $writeResult"
    # echo "2"
    # echo $(echo $writeResult | grep SUCCESS)
    # echo $MBRegisterNewValue
    # # $("$writeResult" | grep ERROR)
    # #echo "$writeResult" | grep SUCCESS

    # sleep 4

    if [[ "$(echo $writeResult | grep ERROR)" != "" ]]; then
        echo "Error writing register!!! $write_result" >$tempfile

    elif [[ "$(echo $writeResult | grep SUCCESS)" != "" ]]; then
        echo -e "\n Data $MBRegisterNewValue was successfully written to register $MB_REGISTER" >$tempfile

        # #readResult=$(modbusReadHexValue $readResult)
        # #readResult=$(echo $((16#$readResult)))
        # readResult=$(valueHexToDec $readResult)
        # echo "Read data (dec): $readResult" >>$tempfile
        # #echo "Reg data (dec): $((echo 16#$(echo $readResult | sed 's/0x//g')))) " >>$tempfile
    fi

    dialog --backtitle "WB-MB-EXPLORER - programm for exploring Modbus network for devices and configuring them" --title "WRITE RESULTS" --exit-label "OK" --textbox $tempfile 18 80
    cat $tempfile >>$LOG_FILE

}

QuickScan() {
    stopSerialDriver

    progress=0
    echo "Scan results (quick scan)" $(date +"%Y-%m-%d %H:%M") >./qscanlog.txt
    echo "Port = $COM_PORT Baudrate = $BAUDRATE, Parity = $PARITY, Stop bits = $STOPBITS " >>./qscanlog.txt
    echo -e "------------------------------------------------------------\n" >>./qscanlog.txt
    #ComSettings=$(cat $SCRIPT_DIR/mbexplorer_settings)

    #echo $ComSettings | sed 's/com settings: //' > $tempfile

    #dialog --title "Scan results" --exit-label "Return to maint menu" --textbox $tempfile 90 100
    (
        local devNumber=0
        for a in {1..247}; do

            local progress=$(($progress + 1))

            echo "XXX"
            echo $(($progress * 100 / 247))
            echo -e "\nQuick scan of devices using Port = $COM_PORT, Baudrate = $BAUDRATE, Parity = $PARITY, Stop bits = $STOPBITS"
            #echo "Current trial:"
            echo "Address = $a"
            #echo "Reply from address: $Address"
            echo " "
            tail -n10 ./qscanlog.txt
            echo "XXX"

            #local Address=$(modbus_client -mrtu $COM_PORT --debug -o200 -a$a $ComSettings -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t0x03 -r0x80 2>/dev/null | grep Data: | sed -e 's/Data://')
            local Address=$(modbusReadHexValue $a 3 128 1)
            if [[ -n "$Address" ]]; then
                devNumber=$(($devNumber + 1))
                # echo -e $(modbus_client -mrtu $COM_PORT --debug -o200 -a$a $ComSettings -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t0x03 -r200 -c 6 | grep Data | sed -e 's/0x00/\\\x/g' -e 's/Data://' -e 's/\s//g') | tr -d "\0" >$tempfile
                # WBDeviceModel=$(cat $tempfile)
                MB_ADDRESS=$a
                WBDeviceModel=$(modbusReadText $MB_ADDRESS 4 200 6)
                #echo "Device FW version:" $(modbusReadText 4 250 16) >>$tempfile
                # echo -e $(modbus_client -mrtu $COM_PORT --debug -o200 -a$a $ComSettings -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t0x03 -r250 -c 15 | grep Data | sed -e 's/0x00/\\\x/g' -e 's/Data://' -e 's/\s//g') | tr -d "\0" >$tempfile
                # WBFWVersion=$(cat $tempfile)
                WBFWVersion=$(modbusReadText $MB_ADDRESS 4 250 16)

                echo "$devNumber Address = $a, Device model = $WBDeviceModel, FW version = $WBFWVersion" >>./qscanlog.txt
            fi
            sleep 0.01
        done

    ) |
        dialog --title "QUICK SCAN" --backtitle "WB-MB-EXPLORER - programm for exploring Modbus network for devices and configuring them" --gauge "progress bar" 25 120 5

    dialog --title "QUICK SCAN RESULTS" --backtitle "WB-MB-EXPLORER - programm for exploring Modbus network for devices and configuring them" --exit-label "Return to main menu" --textbox ./qscanlog.txt 30 120
    clear
    ReadCommunicationSettings
    MainMenu
}
CompleteScan() {
    progress=0
    echo "Scan results (complete scan)" $(date +%Y-%m-%d-%H-%M) >./log.txt
    (
        for a in {149..150}; do
            for b in {1200,2400,4800,9600,19200,38400,57600,115200}; do
                for p in {none,odd,even}; do

                    for s in {1,2}; do

                        progress=$(($progress + 1))
                        echo "XXX"
                        echo $(($progress / 11808))

                        #printf "Modbus address:$a\tSpeed:$b\tParity:$p\tStop bits:$s"
                        echo "Current trial:"
                        echo "Address = $a Speed = $b Parity = $p Stop bits = $s"
                        echo $Address
                        echo "XXX"

                        Address=$(modbus_client -mrtu /dev/ttyRS485-2 --debug -o 300 -a$a -b$b -s$s -d8 -p$p -t0x03 -r0x80 2>/dev/null | grep Data: | sed -e 's/Data://')
                        if [[ $Address != "" ]]; then
                            #FWVersion=`modbus_client --debug -mrtu /dev/ttyRS485-2 --debug -o 300 -a$a -b$b -s$s -d8 -p$p -t0x03 -r250 -c 6 | grep Data | sed -e 's/0x00/\\\x/g' -e 's/Data://' -e 's/\s//g'`
                            #FWVersion=`echo -e $FWVersion 2>/dev/null`
                            echo -e $(modbus_client --debug -mrtu /dev/ttyRS485-2 --debug -o 300 -a$a -b$b -s$s -d8 -p$p -t0x03 -r250 -c 6 | grep Data | sed -e 's/0x00/\\\x/g' -e 's/Data://' -e 's/\s//g' | sed -e 's/x00/ /') >$tempfile
                            FWVersion=$(cat $tempfile)

                            echo "Address = $a FW = $FWVersion Boudrate = $b Parity = $p Stopbits = $s" >>./log.txt
                        fi

                    done

                done

            done

        done

    ) |
        dialog --title "wb-modbus-scan" --gauge "progress bar" 10 70 0

    dialog --title "Scan results" --exit-label "Return to maint menu" --textbox ./log.txt 90 100
    clear
    MainMenu
}

MainMenu() {
    ${DIALOG} --clear --help-button --cancel-label "Exit" --backtitle "WB-MB-EXPLORER - programm for exploring Modbus network for devices and configuring them" --title "WB MB EXPLORER" \
        --menu "\n Current communication settings: \n\
    \n\
    Port: $COM_PORT \n\
    Baudrate: $BAUDRATE \n\
    Parity: $PARITY \n\
    Stopbits: $STOPBITS \n\
    Address: $MB_ADDRESS \n\
    Modbus register: $MB_REGISTER \n\
    Modbus register type: $MB_REG_TYPE \n\
    \n\n\
     
        Chose action to do" 25 100 8 \
        "Settings" "set communication settings" \
        "Read device info" "read information about device" \
        "Read/write register" "read register using current settings" \
        "1 Quick device scan" "scan network using current settings (about 4 min)" \
        "2 Complete device scan" "scan network using all settings combinations" 2>${tempfile}

    case $? in
    0) #InfoDialog `cat ${tempfile}`
        #choice=`cat ${tempfile}`;
        #

        case $(cat $tempfile) in
        "Settings") SetCommunicationSettings ;;
        "Read device info") readDeviceInfo ;;
        "Read/write register") ReadRegister ;;
        "Write register") WriteRegister ;;
        "1 Quick device scan") QuickScan ;;
        "2 Complete device scan") CompleteScan ;;
        *) MainMenu ;;
        esac
        #CompleteScan
        #InfoDialog `cat ${tempfile}`

        #MainMenu
        ;;
    1 | 255)

        ExitDialog "Are you sure to exit?"

        ;;
    esac
}

stopSerialDriver() {
    # status=$(systemctl is-active wb-mqtt-serial)
    # echo $?
    # echo $status

    if [[ "$(systemctl is-active wb-mqtt-serial)" = "active" ]]; then
        echo "Stopping service wb-mqtt-serial"
        systemctl stop wb-mqtt-serial
    fi

    #sleep 2
}
#Stop driver wb-mqtt-serial
# if [[ $(ps aux | grep [s]erial | wc -l) != 0 ]]; then
#     echo "Stopping service wb-mqtt-serial"
#     service wb-mqtt-serial stop
# fi

#Reading current communication settings
stopSerialDriver
ReadCommunicationSettings

#Show main menu
MainMenu
