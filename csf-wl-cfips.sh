#!/bin/bash
# csf-wl-cfips.sh
# -------------------------------------------------------
# csf-wl-cfips.sh: Whitelists CloudFlare's IPs in CSF
# ---------------------------------------------------
# InterGenStudios: 7-21-15
# Copyright (c) 2015: Christopher 'InterGen' Cork  InterGenStudios
# URL: https://intergenstudios.com
# --------------------------------
# License: GPL-2.0+
# URL: http://opensource.org/licenses/gpl-license.php
# ---------------------------------------------------
# csf-wl-cfips.sh is free software:
# You may redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your discretion)
# any later version.
# ------------------

###########################################
##---------------------------------------##
## BEGIN - INITIAL VARIABLE DECLARATIONS ##
##---------------------------------------##
###########################################

# Sets a start-point timestamp
TIMESTAMP="$(date +"%m-%d-%Y_%T")"

RED="\e[1m\e[31m"
GREEN="\e[1m\e[32m"
YELLOW="\e[1m\e[33m"
BLUE="\e[1m\e[34m"
WHITE="\e[1m\e[37m"
NOCOLOR="\e[0m"
BLINK="\e[5m"
UNDERLINE_TEXT="\e[4m"

CF_IPS="$(wget -q -O- https://www.cloudflare.com/ips-v4)"

SET_VERBOSE_OFF=unsure

#########################################
##-------------------------------------##
## END - INITIAL VARIABLE DECLARATIONS ##
##-------------------------------------##
#########################################

##############################
##--------------------------##
## BEGIN - SCRIPT FUNCTIONS ##
##--------------------------##
##############################

#----------------------------------#
# BEGIN - DISPLAY LAYOUT FUNCTIONS #
#----------------------------------#

# Simple divider
DIVIDER () {

    echo -e "\n${BLUE}---------------------------------------------------------${NOCOLOR}\n"

}

# Creates uniform look during script execution when called after any clear command
HEADER () {

    echo -e "\n${BLUE}______________________________________________________________________________________${NOCOLOR}\n"
    echo -e "${WHITE}     csf-wl-cfips.sh${GREEN} version${NOCOLOR}.01    ran on $TIMESTAMP"
    echo -e "${BLUE}______________________________________________________________________________________${NOCOLOR}\n"

}

#--------------------------------#
# END - DISPLAY LAYOUT FUNCTIONS #
#--------------------------------#

CHECK_VERBOSE () {

    CSF_VERBOSE="$(grep VERBOSE /etc/csf/csf.conf)"
    if [ "$CSF_VERBOSE" = "VERBOSE = \"1\"" ]; then
        sed -i 's/VERBOSE = "1"/VERBOSE = "0"/' /etc/csf/csf.conf
        SET_VERBOSE_OFF=yes
    else
        SET_VERBOSE_OFF=no
    fi

}

RE_CHECK_VERBOSE () {

    if [ "$SET_VERBOSE_OFF" = "yes" ]; then
        sed -i 's/VERBOSE = "0"/VERBOSE = "1"/' /etc/csf/csf.conf
        printf "\n"
    else
        printf "\n"
    fi

}

CF_CHECK_DENY () {

    echo -e "${GREEN}Checking for CloudFlare IPs in iptables and temp ban list...${NOCOLOR}\n"
    for IP in ${CF_IPS[@]}; do
        if [ -n "$(csf -g $IP | grep -i deny)" ] || [ -n "$(grep $IP /var/log/lfd.log)" ]; then
            echo -e "${GREEN}CloudFlare IP found, removing block...${NOCOLOR}\n"
            sleep 1
            csf -dr $IP 2>&1 >/dev/null
            csf -tr $IP 2>&1 >/dev/null
            echo -e "${GREEN}CloudFlare IP block removed${NOCOLOR}\n"
        fi
    done
    echo -e "${GREEN}Block checks complete${NOCOLOR}\n"

}

CF_IPS_ALLOW () {

    echo -e "${GREEN}Adding CloudFlare IPs to csf.allow...${NOCOLOR}\n"
    for IP in ${CF_IPS[@]}; do
        csf -a $IP 2>&1 >/dev/null
    done
    sleep 1
    echo -e "\n\n${GREEN}CloudFlare IPs have been added to csf.allow${NOCOLOR}"
    sleep 1

}

CF_IPS_IGNORE () {

    echo -e "${GREEN}Adding CloudFlare IPs to csf.ignore...${NOCOLOR}\n"
    echo " " >> /etc/csf/csf.ignore
    echo "#BEGIN CLOUDFLARE IP ENTRIES - ENTERED ON $TIMESTAMP" >> /etc/csf/csf.ignore
    for IP in ${CF_IPS[@]}; do
        echo $IP >> /etc/csf/csf.ignore
    done
    echo "#END CLOUDFLARE IP ENTRIES" >> /etc/csf/csf.ignore
    echo " " >> /etc/csf/csf.ignore
    sleep 1
    echo -e "\n\n${GREEN}CloudFlare IPs have been added to csf.ignore${NOCOLOR}"
    sleep 1

}

CSF_LFD_R () {

    echo -e "${GREEN}Restarting CSF and LFD...${NOCOLOR}"
    csf -r 2>&1 >/dev/null && lfd -r 2>&1 >/dev/null
    echo -e "\n\n\n${GREEN}CloudFlare IP Whitelisting completed${NOCOLOR}\n"

}

############################
##------------------------##
## END - SCRIPT FUNCTIONS ##
##------------------------##
############################

#############################################
##-----------------------------------------##
## BEGIN - MAKE SURE WE'RE RUNNING AS ROOT ##
##-----------------------------------------##
#############################################

if [ "$(id -u)" != "0" ]; then
    echo -e "\n\n${RED}${BLINK}--------${NOCOLOR}"
    echo -e "${RED}${BLINK}WARNING!${NOCOLOR}"
    echo -e "${RED}${BLINK}--------${NOCOLOR}\n\n"
    echo -e "${WHITE}csf-wl-cfips.sh must be run as ${RED}root${NOCOLOR}\n\n"
    echo -e "${GREEN}(Exiting now...)${NOCOLOR}\n\n"
    exit 1
fi

###########################################
##---------------------------------------##
## END - MAKE SURE WE'RE RUNNING AS ROOT ##
##---------------------------------------##
###########################################

#########################
##---------------------##
## BEGIN - CORE SCRIPT ##
##---------------------##
#########################

clear
HEADER
CHECK_VERBOSE
CF_CHECK_DENY
DIVIDER
CF_IPS_ALLOW
DIVIDER
CF_IPS_IGNORE
DIVIDER
CSF_LFD_R
RE_CHECK_VERBOSE

#######################
##-------------------##
## END - CORE SCRIPT ##
##-------------------##
#######################

exit 0
