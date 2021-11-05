#!/bin/bash

SCRIPT_DIR="/root/wb-mb-explorer"
SETTINGS_FILE="$SCRIPT_DIR/wb-mb-explorer.conf"
LOG_FILE="$SCRIPT_DIR/wb-mb-explorer.log"
DIALOG="dialog"
DIALOG_BACKTITLE=$(echo "WB-MB-EXPLORER - tool for exploring Modbus network and configuring Wirenboard devices")
DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_HELP=2
DIALOG_EXTRA=3
DIALOG_ITEM_HELP=4
DIALOG_ESC=255

SIG_NONE=0
SIG_HUP=1
SIG_INT=2
SIG_QUIT=3
SIG_KILL=9
SIG_TERM=15

TMP_FILE=$(mktemp /tmp/wb-mb-explorer.XXXXXX)
trap "rm -f $TMP_FILE" 0 1 2 5 9 15

# exit confirmation window
show_exit_dialog() {
    $DIALOG --yesno "\n            $1" 7 50
    case $? in
    $DIALOG_OK) exit ;;
        #*) return ;;
    esac
}

# show message box
show_msg_box() {
    $DIALOG --title "$1" --msgbox "\n    $2" 20 80
}

# show help
show_help() {
    $DIALOG --title "$1" --msgbox "\n    $2" 30 150
}

show_yes_no_dialog() {
    $DIALOG --title "$1" --yesno "\n    $2" 15 61
}

# reboot_device() {
#     modbus_client -mrtu $COM_PORT --debug -o100 -a$MB_ADDRESS -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t6 -r120 1 2>&1
# }

read_communication_settings() {
    if [[ -f $SETTINGS_FILE ]]; then
        COM_PORT=$(cat $SETTINGS_FILE | grep COM_PORT | sed -e 's/COM_PORT://')
        BAUDRATE=$(cat $SETTINGS_FILE | grep BAUDRATE | sed -e 's/BAUDRATE://')
        PARITY=$(cat $SETTINGS_FILE | grep PARITY | sed -e 's/PARITY://')
        STOPBITS=$(cat $SETTINGS_FILE | grep STOPBITS | sed -e 's/STOPBITS://')
        MB_ADDRESS=$(cat $SETTINGS_FILE | grep MB_ADDRESS | sed -e 's/MB_ADDRESS://')
        MB_REGISTER=$(cat $SETTINGS_FILE | grep MB_REGISTER | sed -e 's/MB_REGISTER://')
        MB_REG_TYPE=$(cat $SETTINGS_FILE | grep MB_REG_TYPE | sed -e 's/MB_REG_TYPE://')

    else

        $DIALOG --sleep 2 --title "INFO" --infobox "Configuration file not found! Default settings applied" 10 52
        #mkdir $SCRIPT_DIR
        mkdir /root/wb-mb-explorer
        #touch $SETTINGS_FILE
        touch /root/wb-mb-explorer/wb-mb-explorer.conf
        COM_PORT=/dev/ttyRS485-1
        BAUDRATE=9600
        PARITY=none
        STOPBITS=2
        MB_ADDRESS=1
        MB_REGISTER=128
        MB_REG_TYPE=holding

    fi
}

save_communication_settings() {
    echo COM_PORT:$COM_PORT >$SETTINGS_FILE
    echo BAUDRATE:$BAUDRATE >>$SETTINGS_FILE
    echo PARITY:$PARITY >>$SETTINGS_FILE
    echo STOPBITS:$STOPBITS >>$SETTINGS_FILE
    echo MB_ADDRESS:$MB_ADDRESS >>$SETTINGS_FILE
    echo MB_REGISTER:$MB_REGISTER >>$SETTINGS_FILE
    echo MB_REG_TYPE:$MB_REG_TYPE >>$SETTINGS_FILE
}

set_communication_settings() {
    while [ 1 ]; do
        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "COMMUNICATIONS SETTINGS" --clear --help-button --ok-label "Select item" --cancel-label "Save settings" --help-label "Main menu" \
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
            "Set register type" "Current setting: $MB_REG_TYPE" 2>${TMP_FILE}

        case $? in
        $DIALOG_OK) case $(cat ${TMP_FILE}) in
        "Set port") set_com_port ;;
        "Set baudrate") set_baudrate ;;
        "Set parity") set_parity ;;
        "Set stopbits") set_stopbits ;;
        "Set device address") set_address ;;
        "Set Modbus register") set_mb_register ;;
        "Set register type") set_mb_register_type ;;
        esac ;;
        1)
            save_communication_settings
            return
            ;;
        *) return ;;
        esac
    done
    #main_menu

}

set_com_port() {
    COM_PORT=$($DIALOG --stdout --title "Please choose a port to use" --fselect /dev/ttyRS485 14 100)
    #set_communication_settings
}

set_baudrate() {
    $DIALOG --title "Baudrate" --radiolist "Choose avaliable option for baudrate:" 20 61 5 \
        "1200" "bit/s" off \
        "4800" "bit/s" off \
        "9600" "bit/s" ON \
        "19200" "bit/s" off \
        "38400" "bit/s" off \
        "57600" "bit/s" off \
        "115200" "bit/s" off 2>$TMP_FILE

    case $? in
    $DIALOG_OK) case $(cat ${TMP_FILE}) in
    "1200") BAUDRATE="1200" ;;
    "4800") BAUDRATE="4800" ;;
    "9600") BAUDRATE="9600" ;;
    "19200") BAUDRATE="19200" ;;
    "38400") BAUDRATE="38400" ;;
    "57600") BAUDRATE="57600" ;;
    "115200") BAUDRATE="115200" ;;
    esac ;;
        #1 | 255) main_menu ;;
    esac

    #set_communication_settings
}

set_parity() {
    #logger -s "mbexplorer setparity"
    $DIALOG --title "Parity" --radiolist "Choose avaliable option for parity:" 20 61 5 \
        "N" "None" ON \
        "E" "Even" off \
        "O" "Odd" off 2>$TMP_FILE

    case $? in
    $DIALOG_OK) case $(cat ${TMP_FILE}) in
    "N") PARITY="none" ;;
    "E") PARITY="even" ;;
    "O") PARITY="odd" ;;
    esac ;;
        # 1 | 255) main_menu ;;
    esac

    #set_communication_settings
}

set_stopbits() {
    $DIALOG --title "Stopbits" --radiolist "Choose avaliable option for stopbits:" 20 61 5 \
        "1" "1 stop bit" off \
        "2" "2 stop bits" ON 2>$TMP_FILE

    case $? in
    $DIALOG_OK) case $(cat ${TMP_FILE}) in
    "1") STOPBITS="1" ;;
    "2") STOPBITS="2" ;;
    esac ;;
        # 1 | 255) main_menu ;;
    esac

    #set_communication_settings
}

set_address() {
    # #Creating address list
    # echo "1 address on" >$TMP_FILE
    # for i in {2..246}; do
    #     echo "$i address off" >>$TMP_FILE
    # done
    # echo "247 address off" >>$TMP_FILE

    $DIALOG --title "Enter address of Modbus device" --inputbox "Enter address of Modbus device you wnat to work with (from 1 to 247)" 16 51 2>$TMP_FILE

    case $? in
    $DIALOG_OK)
        value=$(cat ${TMP_FILE})
        #echo $value
        #sleep 3
        if [[ ($value -ge 0) && ($value -le 248) && ($value%1 -eq 0) && ($value -ne "") ]]; then
            MB_ADDRESS=$value
        else
            #echo "else"
            show_msg_box "INFO" "Entered device address is incorrect!"
            #$DIALOG --sleep 2 --title "INFO" --infobox "Entered device address is incorrect!" 10 52
            #$DIALOG --title "INFO" --msgbox "Entered device address is incorrect!" 10 52
            #set_address
        fi
        ;;
        # 1 | 255) main_menu ;;
    esac

    #set_communication_settings
}

set_mb_register() {

    $DIALOG --title "Enter address of Modbus register" --inputbox "Enter address of Modbus register in decimal or hex (0x12345)" 16 51 2>$TMP_FILE

    case $? in
    $DIALOG_OK) if [[ ($(cat $TMP_FILE) -ge 0) && ($(cat $TMP_FILE) -le 30000) ]]; then
        MB_REGISTER=$(cat $TMP_FILE)
    else
        $DIALOG --sleep 2 --title "INFO" --infobox "Wrong address was entered!" 10 52
    fi ;;
    esac
    #set_communication_settings

}

set_mb_register_type() {
    $DIALOG --title "Register type" --radiolist "Choose avaliable option for register type:" 20 61 5 \
        "descrete" "destrete input (read)" off \
        "coil" "descrete output (read/write)" off \
        "input" "input register (read)" off \
        "holding" "holding register (read/write)" ON 2>$TMP_FILE

    case $? in
    $DIALOG_OK) MB_REG_TYPE=$(cat ${TMP_FILE}) ;;
    esac

    #set_communication_settings
}

modbus_read_raw() {

    # read_result_raw=$(modbus_client --debug -mrtu $COM_PORT -o100 -a$1 -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$2 -r$3 -c$4 2>&1)
    # echo $read_result_raw
    modbus_client --debug -mrtu $COM_PORT -o100 -a$1 -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$2 -r$3 -c$4 2>&1
}

modbus_write() {
    #echo $(modbus_client -mrtu -pnone -s2 $COM_PORT -a$MB_ADDRESS -t0x03 -r$R -c$C | grep Data | sed 's/.*Data://' | sed 's/ //g')
    modbus_client -mrtu $COM_PORT --debug -o100 -a$MB_ADDRESS -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$MBFunction -r$MB_REGISTER $1 2>&1
}

#Function of reading hex value from Modbus register
#   If reading was successfull - hex value is returned
#   If reading was unsuccessfull - full output with error is returned
modbus_read_hex_value() {
    readRawResult=$(modbus_read_raw $1 $2 $3 $4)
    readHexValue=$(echo "$readRawResult" | grep Data | sed -e 's/.*Data: //' -e 's/0x//g' -e 's/\s//g')
    if [[ -n $readHexValue ]]; then
        echo $readHexValue
    else
        echo "$readRawResult"
    fi
}

value_hex_to_dec() {
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

modbus_read_text() {
    #option -e for parsing characters
    echo -e $(modbus_read_raw $1 $2 $3 $4 | grep Data | sed -e 's/.*Data: //' -e 's/0x00/\\\x/g' -e 's/\s//g') | tr -d "\0"
}

read_device_info() {
    echo "Reading info from device using following communication settings:" >$TMP_FILE
    echo -e "Port $COM_PORT, Baudrate: $BAUDRATE, Parity: $PARITY, Stopbits: $STOPBITS, address $MB_ADDRESS\n" >>$TMP_FILE
    echo "----------------------------------------------------------" >>$TMP_FILE

    local deviceAddress=$(modbus_read_hex_value $MB_ADDRESS 3 128 1)

    if [[ -z $(echo $deviceAddress | grep ERROR) ]]; then
        #Device model
        echo "Device model:" $(modbus_read_text $MB_ADDRESS 4 200 6) >>$TMP_FILE

        #Device serial number
        local serialNumber=$(modbus_read_hex_value $MB_ADDRESS 4 270 2)
        serialNumber=$(value_hex_to_dec $serialNumber)
        echo "Serial number:" $serialNumber >>$TMP_FILE

        #Device FW version
        echo "FW version:" $(modbus_read_text $MB_ADDRESS 4 250 16) >>$TMP_FILE

        #Device FW signature
        echo "FW signature:" $(modbus_read_text $MB_ADDRESS 4 290 12) >>$TMP_FILE

        #Device bootloader version
        echo "Bootloader version:" $(modbus_read_text $MB_ADDRESS 4 330 8) >>$TMP_FILE

        #Device uptime
        echo "Uptime (s):" $(value_hex_to_dec $(modbus_read_hex_value $MB_ADDRESS 4 104 2)) >>$TMP_FILE

        #Device voltage supply
        local supply_voltage=$(modbus_read_hex_value $MB_ADDRESS 4 121 1)
        supply_voltage=$(value_hex_to_dec $supply_voltage)
        supply_voltage=$(echo "scale=3;$supply_voltage / 1000" | bc -l)
        echo "Supply voltage (V): $supply_voltage" >>$TMP_FILE

    else
        echo -e "\nError: device with current settings is unavailable!" >>$TMP_FILE
        echo -e "\nCheck communication settings and device connection." >>$TMP_FILE
    fi
}

show_device_info() {

    while [ 1 ]; do
        stop_serial_driver
        #echo -e "\n$(date +"%Y-%m-%d %H:%M:%S") +++++ Show device info" >>$LOG_FILE
        write_log "+++++ SHOW DEVICE INFO"

        echo "" >$TMP_FILE
        read_device_info
        #sleep 2

        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "SHOW DEVICE INFO" --ok-label "Read again" --extra-button --extra-label "Main menu" --textbox $TMP_FILE 20 90
        local dialog_button=$?

        write_log "$(cat $TMP_FILE)"

        case $dialog_button in
        $DIALOG_OK) continue ;;
        *) return ;;
        esac

    done

}

read_register() {

    # #for test
    # readResult=$(modbus_read_hex_value $MB_ADDRESS 3 1280 1)
    # echo -e "*readResult=$readResult"
    # #echo "*readRawResult="$readRawResult""
    # exit
    # ############

    #cat << EOF > $TMP_FILE;

    while [ 1 ]; do

        stop_serial_driver
        write_log "+++++ READ REGISTER"

        echo "" >$TMP_FILE
        echo "Reading from device using following communication settings:" >>$TMP_FILE
        echo -e "Port $COM_PORT, Baudrate: $BAUDRATE, Parity: $PARITY, Stopbits: $STOPBITS, address $MB_ADDRESS\n" >>$TMP_FILE
        echo "Modbus register: $MB_REGISTER, Register type: $MB_REG_TYPE" >>$TMP_FILE
        echo "----------------------------------------------------------" >>$TMP_FILE
        echo -e "\nResult: \n" >>$TMP_FILE

        case $MB_REG_TYPE in
        "coil") MBFunction="0x01" ;;
        "descrete") MBFunction="0x02" ;;
        "holding") MBFunction="0x03" ;;
        "input") MBFunction="0x04" ;;
        esac

        #modbus_client $COM_PORT $MB_ADDRESS $BAUDRATE $STOPBITS $PARITY $MBFunction $MB_REGISTER >>$TMP_FILE
        local readResult=$(modbus_read_hex_value $MB_ADDRESS $MBFunction $MB_REGISTER 1)
        #echo "hello $readRawResult2"
        #echo $readResult

        if [[ -z $(echo $readResult | grep ERROR) ]]; then
            #echo "*SUCCESS $readResult"
            echo "Read data (hex): 0x$readResult" >>$TMP_FILE
            readResult=$(value_hex_to_dec $readResult)
            echo "Read data (dec): $readResult" >>$TMP_FILE

        else
            # echo "*ERROR $readResult"
            echo "Error reading register $MB_REGISTER" >>$TMP_FILE
            echo "" >>$TMP_FILE
            echo "$readResult" >>$TMP_FILE

            #echo "hello $readRawResult2" >>$TMP_FILE
            #sleep 2
            #readResult=$(modbus_read_hex_value $readResult)
            #readResult=$(echo $((16#$readResult)))
            #readResult=$(echo $readResult | sed 's/)

            #echo "Reg data (dec): $((echo 16#$(echo $readResult | sed 's/0x//g')))) " >>$TMP_FILE
        fi

        # readResult=$(modbusRead)
        # echo $readResult
        # if [[ $(echo $readResult | grep SUCCESS) ]]; then
        #     $(echo $readResult | grep Data) >>$TMP_FILE
        #     #echo $readResult >>$TMP_FILE
        # else
        #     echo "Error reading register"
        # fi

        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "READ REGISTER" --ok-label "Read register again" --extra-button --extra-label "Write to register" --help-button --help-label "Main menu" --textbox $TMP_FILE 25 90 # echo "start dialog" > $TMP_FILE
        local dialog_button=$?

        write_log "$(cat $TMP_FILE)"

        case $dialog_button in
        $DIALOG_OK) continue ;;
        3) write_register ;;
        *) return ;;
        esac

    done

}

write_register() {
    stop_serial_driver
    write_log "+++++ WRITE REGISTER"
    #read_register

    # while [ 1 ]; do
    #     echo "Writing register with address $MB_ADDRESS using following communication settings:" >$TMP_FILE
    #     echo "Port $COM_PORT, Baudrate: $BAUDRATE, Parity: $PARITY, Stopbits: $STOPBITS, address $MB_ADDRESS" >>$TMP_FILE
    #     echo "Modbus register: $MB_REGISTER, Register type: $MB_REG_TYPE" >>$TMP_FILE

    #     #REading selected register first
    #     case $MB_REG_TYPE in
    #     "coil") MBFunction="0x01" ;;
    #     "descrete") MBFunction="0x02" ;;
    #     "holding") MBFunction="0x03" ;;
    #     "input") MBFunction="0x04" ;;
    #     esac
    #     CurrentRegValue =`modbus_client -mrtu $COM_PORT --debug -o 300 -a$MB_ADDRESS -b$BAUDRATE -s$STOPBITS -d8 -p$PARITY -t$MBFunction -r$MB_REGISTER | grep Data | sed -e 's/Data://'`
    #     echo "Current register value: "$CurrentRegValue >> $TMP_FILE
    #     dialog --title "MBEXPLORER WRITE ADDRESS" --help-button --exit-label "Write register" --help-label "Return to main menu" --textbox $TMP_FILE 80 100
    #         case $? in
    #         2 | 255) break ;;
    #         esac
    case $MB_REG_TYPE in
    "coil") MBFunction="0x05" ;;
    "holding") MBFunction="0x06" ;;
    "descrete" | "input")
        #$DIALOG --sleep 2 --title "INFO BOX" --infobox "Register type is $MB_REG_TYPE, can't write!" 10 52
        show_msg_box "ERROR" "Register type is $MB_REG_TYPE, can't write!"
        return
        #read_register
        ;;
    esac

    $DIALOG --title "WRITE REGISTER" --inputbox "Enter new register value in decimal (100) or hex (0x64)" 16 51 2>$TMP_FILE
    # clear
    # cat $TMP_FILE
    # sleep 3
    # case $? in
    # 0)
    local input_value="$(cat $TMP_FILE)"
    # echo $input_value
    # sleep 5
    if [[ "$input_value" -ge "0" && "$input_value" -le "65535" && -n "$input_value" ]]; then
        local writeResult=$(modbus_write $input_value)

        if [[ -n "$(echo $writeResult | grep SUCCESS)" ]]; then
            echo -e "\nData $input_value was successfully written to register $MB_REGISTER" >$TMP_FILE
        else
            echo -e "\nError writing register!!!\n\n$writeResult" >$TMP_FILE

        fi

        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "WRITE RESULTS" --exit-label "OK" --textbox $TMP_FILE 18 80

    else

        show_msg_box "ERROR" "Wrong new value was entered!"
        #read_register
    fi

    write_log "$(cat $TMP_FILE)"

    #     ;;

    # esac

}

quick_scan() {
    local a
    local scanResult
    local devNumber=0
    local progress=0

    stop_serial_driver

    write_log "+++++ QUICK SCAN"

    echo "Scan results (quick scan)" $(date +"%Y-%m-%d %H:%M") >$TMP_FILE
    echo "Port = $COM_PORT Baudrate = $BAUDRATE, Parity = $PARITY, Stop bits = $STOPBITS " >>$TMP_FILE
    echo -e "------------------------------------------------------------\n" >>$TMP_FILE

    (
        for a in {1..247}; do
            progress=$(($progress + 1))

            echo "XXX"
            echo $(($progress * 100 / 247))
            echo -e "\nQuick scan of devices using\n Port = $COM_PORT, Baudrate = $BAUDRATE, Parity = $PARITY, Stop bits = $STOPBITS"
            echo "Address = $a"
            echo " "
            tail -n10 $TMP_FILE
            echo "XXX"

            scanResult=$(modbus_read_hex_value $a 4 128 1)
            if [[ -z $(echo $scanResult | grep ERROR) ]]; then
                devNumber=$(($devNumber + 1))
                WBDeviceModel=$(modbus_read_text $a 4 200 6)
                WBFWVersion=$(modbus_read_text $a 4 250 16)

                echo "$devNumber Address = $a, Device model = $WBDeviceModel, FW version = $WBFWVersion" >>$TMP_FILE
            fi
            sleep 0.01
        done
    ) |
        $DIALOG --title "QUICK SCAN" --backtitle "$DIALOG_BACKTITLE" --gauge "progress bar" 25 120 5

    $DIALOG --title "QUICK SCAN RESULTS" --backtitle "$DIALOG_BACKTITLE" --exit-label "Main menu" --textbox $TMP_FILE 30 120

    write_log "$(cat $TMP_FILE)"
    # clear
    # read_communication_settings
    # main_menu
}
complete_scan() {
    local a
    local b
    local p
    local s
    local scanResult
    local devNumber=0
    local progress=0

    stop_serial_driver

    write_log "+++++ COMPLETE SCAN"

    echo "Scan results (complete scan)" $(date +"%Y-%m-%d %H:%M") >$TMP_FILE
    echo "Port = $COM_PORT" >>$TMP_FILE
    echo -e "------------------------------------------------------------\n" >>$TMP_FILE
    (
        for b in 9600 115200 19200 57600 38400 4800 2400 1200; do
            for a in {1..247}; do
                for p in {none,odd,even}; do
                    for s in {1,2}; do
                        progress=$(($progress + 1))

                        echo "XXX"
                        echo $(($progress / 11808))
                        echo -e "\nComplete scan of devices using Port = $COM_PORT"
                        echo "Baudrate = $b, Address = $a,  Parity = $p, Stop bits = $s"
                        echo " "
                        tail -n10 $TMP_FILE
                        echo "XXX"

                        scanResult=$(modbus_client -mrtu $COM_PORT -o100 -a$a -b$b -s$s -d8 -p$p -t4 -r128 2>/dev/null | grep Data: | sed -e 's/.*Data: //' -e 's/0x//g' -e 's/\s//g')
                        if [[ -n $scanResult ]]; then
                            WBDeviceModel=$(echo -e "$(modbus_client -mrtu $COM_PORT --debug -o100 -a$a -b$b -s$s -d8 -p$p -t4 -r200 -c6 | grep Data: | sed -e 's/.*Data: //' -e 's/0x00/\\\x/g' -e 's/\s//g')" | tr -d "\0")
                            FWVersion=$(echo -e "$(modbus_client -mrtu $COM_PORT --debug -o100 -a$a -b$b -s$s -d8 -p$p -t4 -r250 -c16 | grep Data: | sed -e 's/.*Data: //' -e 's/0x00/\\\x/g' -e 's/\s//g')" | tr -d "\0")

                            echo "Address = $a, Device model = $WBDeviceModel, FW version = $FWVersion, Boudrate = $b, Parity = $p, Stopbits = $s" >>$TMP_FILE
                        fi
                        sleep 0.01
                    done

                done

            done

        done

    ) |
        $DIALOG --title "COMPLETE SCAN" --backtitle "$DIALOG_BACKTITLE" --gauge "progress bar" 25 120 5

    $DIALOG --title "COMPLETE SCAN RESULTS" --backtitle "$DIALOG_BACKTITLE" --exit-label "Main menu" --textbox $TMP_FILE 30 120

    write_log "$(cat $TMP_FILE)"
    # clear
    # main_menu
}

fw_update_menu() {
    while [ 1 ]; do
        ${DIALOG} --clear --help-button --cancel-label "Main Menu" --backtitle "$DIALOG_BACKTITLE" --title "FW UPDATE" \
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
    Chose action to do" 25 120 8 \
            "Device FW update" "Update firmware of device with address $MB_ADDRESS at port $COM_PORT from Internet" \
            "Force device FW update" "Force update FW of device with address $MB_ADDRESS at port $COM_PORT from Internet" \
            "Update FW of all devices" "Update firmwares of all devices configured in controller at port $COM_PORT from Internet" \
            "Update FW using file" "FW of device with address $MB_ADDRESS at port $COM_PORT will be updated using FW file" 2>$TMP_FILE

        case $? in
        $DIALOG_OK)
            case $(cat $TMP_FILE) in
            "Device FW update") update_device_fw_from_internet ;;
            "Force device FW update") update_device_fw_from_internet "--force" ;;
            "Update FW of all devices") update_all_devices_fw_from_internet ;;
            "Update FW using file") update_fw_using_file ;;
            esac
            ;;
        *) return ;;
        2) show_msg_box "INFO" "Help information about firmware update options" ;;

        esac
    done

}

update_device_fw_from_internet() {
    local window_title="DEVICE FW UPDATE"
    local button_title="Update firmware"

    if [[ "$1" = "--force" ]]; then
        window_title="FORCE DEVICE FW UPDATE"
        button_title="Force firmware update"
    fi

    write_log "+++++ $window_title"

    echo -e "Device info before "${1##--} "FW update:\n" >$TMP_FILE
    clear
    read_device_info
    echo -e "--------------------------------------\n" >>$TMP_FILE

    $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "$window_title" --ok-label "$button_title" --extra-button --extra-label "Cancel" --textbox $TMP_FILE 20 90

    case $? in
    $DIALOG_OK)
        #echo "$(wb-mcu-fw-updater update-fw -a$MB_ADDRESS $COM_PORT)" | sed -e 's/[[:cntrl:]]//g' -e 's/\[......//g' -e 's/\[..//g' >>$TMP_FILE
        wb-mcu-fw-updater update-fw -a$MB_ADDRESS $COM_PORT $1 2>&1 | sed -e 's/[[:cntrl:]]//g' -e 's/\[......//g' -e 's/\[..//g' >>$TMP_FILE
        #cat $TMP_FILE >$LOG_FILE

        if [[ -z $(cat $TMP_FILE | grep Done) ]]; then
            echo -e "\nError updating firmware: device with address $MB_ADDRESS is unavaliable!" >$TMP_FILE
        fi
        #wb-mcu-fw-updater update-fw -a"$MB_ADDRESS" "$COM_PORT" 2>&1 >>$TMP_FILE
        # cat $TMP_FILE >$LOG_FILE
        # cat $LOG_FILE >$TMP_FILE
        # while [ 1 ]; do
        #echo "" >$TMP_FILE

        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "DEVICE FW UPDATE" --exit-label "OK" --textbox $TMP_FILE 25 120
        local dialog_button=$?

        write_log "$(cat $TMP_FILE)"

        case $dialog_button in
        # 0) echo "0" ;;
        $DIALOG_OK) return ;;
            #2) main_menu ;;
        esac
        ;;

    3) return ;;
        # 2) main_menu ;;
    esac

    #sleep 1

    #done
}

update_all_devices_fw_from_internet() {
    show_yes_no_dialog "WARNING" \
        "   Are yous sure to update firmwares of \n  \
                  ALL DEVICES\n \
             configured in controller?"
    case $? in
    $DIALOG_OK)
        write_log "+++++ ALL DEVICES FW UPDATE"
        echo -e "\nUpdate FW of all devicess configured in controller at port $COM_PORT\n" >$TMP_FILE
        #echo -e $(wb-mcu-fw-updater update-all 2>&1 | sed -e 's/[[:cntrl:]]//g' -e 's/\[..//g' -e 's/\;10./\\n/g') >>$TMP_FILE
        wb-mcu-fw-updater update-all 2>&1 | sed -e 's/[[:cntrl:]]//g' -e 's/\[..//g' -e 's/\;10.//g' >>$TMP_FILE
        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "ALL DEVICES FW UPDATE" --exit-label "OK" --textbox $TMP_FILE 32 150
        local dialog_button=$?

        write_log "$(cat $TMP_FILE)"

        case $dialog_button in
        # 0) echo "0" ;;
        $DIALOG_OK) return ;;
            #2) main_menu ;;
        esac
        ;;

    *) return ;;
    esac

}

update_fw_using_file() {
    #echo "update_fw_using_file"
    local window_title="DEVICE FW UPDATE USING FILE"

    write_log "+++++ $window_title"
    #echo -e "Device info before FW update:\n" >$TMP_FILE

    read_device_info

    echo -e "--------------------------------------\n" >>$TMP_FILE
    while [ 1 ]; do
        $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "$window_title" --ok-label "Select FW file" --extra-button --extra-label "Cancel" --textbox $TMP_FILE 28 120

        case $? in
        $DIALOG_OK)
            local fw_file=$($DIALOG --stdout --title "$window_title" --fselect /root/vda/firmwares 14 100)
            if [[ -f $fw_file && -n $(echo $fw_file | grep ".wbfw") ]]; then
                echo "Firmware file:" $fw_file >>$TMP_FILE
                #sleep 5
                #echo -e "\nFirmware " >>$TMP_FILE
                $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "$window_title" --ok-label "Start" --extra-button --extra-label "Cancel" --textbox $TMP_FILE 28 120
                case $? in
                $DIALOG_OK)

                    wb-mcu-fw-flasher -d $COM_PORT -a$MB_ADDRESS -j -f $fw_file 2>&1 >>$TMP_FILE
                    #reboot_device
                    #echo "Firmware done" >>$TMP_FILE
                    ;;
                *) return ;;

                esac
                sleep 1
                echo -e "\n--------------------------------------" >>$TMP_FILE
                echo -e "Device info after FW update:\n" >>$TMP_FILE
                local tmp_info=$(cat $TMP_FILE)
                read_device_info

                #echo "$tmp_info" | cat - $TMP_FILE >$TMP_FILE
                #sed -i $tmp_info $TMP_FILE
                echo -e "$tmp_info\n $(cat $TMP_FILE)" >$TMP_FILE
                $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "$window_title" --exit-label "OK" --textbox $TMP_FILE 30 120
                write_log "$(cat $TMP_FILE)"
                return
            else
                show_msg_box "ERROR" "File with firmware was no found!"

            fi

            ;;

        3) return ;;

        esac
    done
}

show_log_file() {
    $DIALOG --backtitle "$DIALOG_BACKTITLE" --title "LOG FILE" --exit-label "OK" --textbox $LOG_FILE 32 150
}

main_menu() {

    while [ 1 ]; do
        $DIALOG --clear --help-button --cancel-label "Exit" --backtitle "$DIALOG_BACKTITLE" --title "MAIN MENU" \
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
     
        Chose action to do" 28 100 8 \
            "1 Settings" "set communication settings" \
            "2 Show device info" "read information about device" \
            "3 Read/write register" "read register using current settings" \
            "4 Quick device scan" "scan network using current settings (about 2 min)" \
            "5 Complete device scan" "scan network using all settings combinations (about 60 min)" \
            "6 FW update" "Device firmware update" \
            "7 Show log file" "Show log file of current session" 2>$TMP_FILE

        case $? in
        $DIALOG_OK) #InfoDialog `cat ${TMP_FILE}`
            #choice=`cat ${TMP_FILE}`;
            #

            case $(cat $TMP_FILE) in
            "1 Settings") set_communication_settings ;;
            "2 Show device info") show_device_info ;;
            "3 Read/write register") read_register ;;
            "4 Quick device scan") quick_scan ;;
            "5 Complete device scan") complete_scan ;;
            "6 FW update") fw_update_menu ;;
            "7 Show log file") show_log_file ;;
            *) main_menu ;;
            esac
            #complete_scan
            #InfoDialog `cat ${TMP_FILE}`

            #main_menu
            ;;
        2)
            show_help "HELP" "This is a bref user guide of WB-MW-EXPLORER"
            ;;
        *)

            show_exit_dialog "Are you sure to exit?"

            ;;
        esac

    done
}

stop_serial_driver() {
    # status=$(systemctl is-active wb-mqtt-serial)
    # echo $?
    # echo $status

    if [[ "$(systemctl is-active wb-mqtt-serial)" = "active" ]]; then
        echo "Stopping service wb-mqtt-serial"
        systemctl stop wb-mqtt-serial
    fi

    #sleep 2
}

write_log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") $1\n" >>$LOG_FILE
}

main() {
    clear

    #Clear log file
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") WB-MB-EXPLORER started\n" >$LOG_FILE
    #Stop driver wb-mqtt-serial
    stop_serial_driver

    #Reading current communication settings
    read_communication_settings

    #Show main menu
    main_menu
}

main
