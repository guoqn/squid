#!/bin/bash

# Chinacache SquidDevTeam
# $Id: purgeGetoptMon.sh 5585 2008-11-19 05:53:41Z jyp $

#---------------------------------------------------------------------------|
#  @program   : purgeGetoptMon.sh                                           |  
#  @version   : 0.3.2 #                                                     |
#  @function@ : to monitor purgeGetopts.sh status and delete_dir.list       |
#  @campany   : china cache                                                 |
#  @dep.      : SquidTeam                                                   |
#  @writer    : Alex  Yu                                                    |
#---------------------------------------------------------------------------|

DEBUG=0
#ConfFile=purge.conf
#ConfFile=/usr/local/squid/etc/squid.conf
#ConfTag='#*->'
AlarmSeconds=$(( 6 * 60 ))
#valid minutes
INTERVAL=2             
#LogFile=/var/log/chinacache/purgedir.log
DataFile=/usr/local/squid/var/purge.request
PurgeInterface=/usr/local/squid/etc/purge_submit.list

ExternalConf=/usr/local/squid/etc/fcexternal.conf
_SwapWarnSize=`test -r $ExternalConf&&awk '$1 == "SwapWarnSize" {print $2}' $ExternalConf`
SwapWarnSize=${_SwapWarnSize:-900}

#trap "rm -f $DataFile; exit 1" TERM INT 
Result=1
	
if [ -f "$DataFile" ] ;then
        FirstRecordTS=`head -1 $DataFile|awk '{print $3}'`
       	NowTS=`date +%s`
        [ "$DEBUG" -ge "1" ]&&echo "In alarmFun: NowTS=$NowTS"
       	FTS=${FirstRecordTS:-$NowTS}
        [ "$DEBUG" -ge "1" ]&&echo "In alarmFun: FTS=$FTS"
       	INVALID=$(( $NowTS - $FTS - $AlarmSeconds ))
        [ "$DEBUG" -ge "1" ]&&echo  "INVALID=$(( $NowTS - $FTS - $AlarmSeconds ))"
        [ "$DEBUG" -ge "1" ]&&echo "INVALID=$INVALID" 
       	if [ "$INVALID" -ge "0" ];then
	   #purgeGetopt.sh is not working
	 	Result=0
        fi
else
	 test -r /usr/local/squid/etc/squid.conf||exit 0
	 SwapStatSizeM=`du -m "$(awk '$1 ~ /^cache_dir/{print $3}' \
                /usr/local/squid/etc/squid.conf|head -1)/swap.state"|awk '{print $1}'`
        if [ ${SwapStatSizeM:-2000} -gt $SwapWarnSize ];then
                Result=0
        fi
fi

if [ -f "$PurgeInterface" ] ;then
	M_DATE=`stat $PurgeInterface|awk '/Modify/ {print $2}'`
	M_TIME=`stat $PurgeInterface|awk '/Modify/ {print $3}'|cut -d. -f1`

	L_ym=${M_DATE%-*}
	#echo \$L_ym=$L_ym
	L_y=${M_DATE%%-*}
	#echo \$L_y=$L_y
	L_m=${L_ym#*-}
	#echo \$L_m=$L_m
	L_d=${M_DATE##*-}
	#echo \$L_d=$L_d

	#echo $M_TIME
	L_HM=${M_TIME%:*}
	#echo \$L_HM=$L_HM
	L_H=${M_TIME%%:*}
	#echo \$L_H=$L_H
	L_M=${L_HM#*:}
	#echo \$L_M=$L_M
	L_S=${M_TIME##*:}
	#echo \$L_S=$L_S
	INVALID=`awk -v _tm_test_date="$L_y $L_m $L_d $L_H $L_M $L_S" \
		-v interval="$INTERVAL" 'BEGIN  {
				    if (_tm_test_date) {
			        	t = mktime(_tm_test_date)
				        now = systime()
				        diff = (now - t)/60
				        printf "%d\n", (diff - interval)
				    }
	}' `

	#echo $INVALID
	if [ "$INVALID" -ge "0" ];then
		Result=0
	fi
fi
	
#if Result is 0, something wrong, or everything is fine.

echo $Result
