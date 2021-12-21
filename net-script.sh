#!/bin/bash

IFS=$'\n'

echo $(ip address | sed '1,6d')

read -p "What interface do you want to customize? " intername

i=0
while [ $i == 0 ]
 do
  if [[ $(ip address | sed '1,6d' | grep $intername) ]]
  then
   echo "This interface exists"
   break
  else
  read -p "No such interface exists. Please enter the correct name: " intername
  fi
 done

conffile=/etc/sysconfig/network-scripts/ifcfg-$intername
if [[ -f "$conffile" ]]
 then
  echo "Config file was found"
 else 
  echo "Config file not found."
  read -p "Do you want to create a new configure file for interface $intername? (y/n) " conffile_create
  case $conffile_create in
  [Yy][Ee][Ss]|Y|y)
   echo $(cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-$intername)
   echo $(sed -i '/^DEFROUTE/s/=.*/=no/' $conffile)
   echo $(sed -i '/^NAME/s/=.*/='$intername'/' $conffile)
   echo $(sed -i '/^DEVICE/s/=.*/='$intername'/' $conffile)
   echo $(sed -i '/^UUID/d' $conffile) 
  esac
fi

if [[ -f "$conffile" ]]
 then
  IPADDR_FIND="$(cat $conffile | grep IPADDR)"
  PREFIX_FIND="$(cat $conffile | grep PREFIX)"
  GATEWAY_FIND="$(cat $conffile | grep GATEWAY)"
  DNS_FIND="$(cat $conffile | grep DNS)"

  delim="------------------------------------------"
  echo $delim
  echo "This interface has such configurations: "
  echo -e "$IPADDR_FIND \n$PREFIX_FIND \n$GATEWAY_FIND \n$DNS_FIND"
  echo $delim
  
  if [[ $IPADDR_FIND ]]
   then
    read -p "Do you want to change ipv4 for interface $intername? (y/n) " change_ipv4
    case $change_ipv4 in
     [Yy][Ee][Ss]|Y|y)
      read -p "Please, enter a new ipv4 for $intername: " ipv4
      while [ $i == 0 ]
       do
         num1=`echo $ipv4 | cut -d "." -f1`
         num2=`echo $ipv4 | cut -d "." -f2`
         num3=`echo $ipv4 | cut -d "." -f3`
         num4=`echo $ipv4 | cut -d "." -f4`
         error="Error. Incorrect ip address"

         #if [[ ! $ipv4 =~ ^[0-9]+$ ]] ; then echo "Error. Enter just numbers"
         if [[ (($num1 -ne 10) && ($num1 -ne 172) && ($num1 -ne 192)) 
            || (($num1 -eq 10) && ($num2 -gt 255)) 
            || (($num1 -eq 172) && ($num2 -lt 16 || $num2 -gt 31))
            || (($num1 -eq 192) && ($num2 -ne 168)) 
            || (($num3 -gt 255) || ($num4 -gt 255)) ]] ; then echo $error; 
         elif [[ $(echo $ipv4 | tr -cd " " | wc -m) -gt 0 ]] ; then echo "Error. Enter without spaces"; 
         elif [[ $(echo $ipv4 | tr -cd "." | wc -m) -ne 3 ]] ; then echo "Error. Check the number of points.";
         elif [[ ${#ipv4} -gt 15 || ${#ipv4} -lt 8 ]] ; then echo "Error. Incorrect length";
         read -p "Error. Try again: " ipv4
         else
          echo "ok"
          break
         fi
         read -p "Try again: " ipv4
       done
      echo $(sed -i '/^IPADDR/s/=.*/='$ipv4'/' $conffile)
      echo "ipv4 was updated"
      echo $delim 
   esac
  fi
   
  if [[ $PREFIX_FIND ]]
   then
    read -p "Do you want to change prefix for interface $intername? (y/n) " change_prefix
    case $change_prefix in
     [Yy][Ee][Ss]|Y|y)
      read -p "Please, enter a new prefix for interface $intername: " prefix
      echo $(sed -i '/^PREFIX/s/=.*/='$prefix'/' $conffile)
      echo "prefix was updated"
      echo $delim
    esac
  fi
 
  if [[ $GATEWAY_FIND ]]
   then
    read -p "Do you want to change gateway for interface $intername? (y/n) " change_gateway
    case $change_gateway in
     [Yy][Ee][Ss]|Y|y)
      read -p "Please, enter a new gateway for interface $intername: " gateway
      echo $(sed -i '/^GATEWAY/s/=.*/='$gateway'/' $conffile)
      echo "gateway was updated"
      echo $delim
    esac  
  fi
  
  if [[ $DNS_FIND ]]
   then 
    read -p "Do you want to configure the DNS? (y/n) " change_dns
    case $change_dns in
     [Yy][Ee][Ss]|Y|y)
      read -p "What DNS servers do you need to configure? (1/2/both) " dns_number
      case $dns_number in
      1)
       read -p "Please, enter a new dns instead of the FIRST dns for $intername: " first_dns
       echo $(sed -i '/^DNS1/s/=.*/='$first_dns'/' $conffile);;
      2)
       read -p "Please, enter a new dns instead of the SECOND dns for $intername: " second_dns
       echo $(sed -i '/^DNS2/s/=.*/='$second_dns'/' $conffile);;
     [Bb][Oo][Tt][Hh]|B|b|12)
       read -p "New DNS1: " dns1
       read -p "New DNC2: " dns2
       echo $(sed -i '/^DNS1/s/=.*/='$dns1'/' $conffile)
       echo $(sed -i '/^DNS2/s/=.*/='$dns2'/' $conffile);;
      *)
       echo "No such numbers";;
     esac
      echo $delim
    esac
  fi   
  
  echo "Please wait. Server is being updated"
  echo $(systemctl restart network)  

  echo $delim
  echo "Interface $intername was updated. New configurations: "
  echo $(cat $conffile | grep IPADDR)
  echo $(cat $conffile | grep PREFIX)
  echo $(cat $conffile | grep GATEWAY)
  echo $(cat $conffile | grep DNS1)
  echo $(cat $conffile | grep DNS2)
  echo $delim

else
 echo "Config file not found. Program completed!"
fi
