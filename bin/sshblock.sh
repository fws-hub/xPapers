#! /bin/sh

#
# ----------------------------------------------------------------------------
# "THE CAPPUCHINO-WARE LICENSE"
# Rainer Wichmann <rwichmann@la-samhna.de> wrote this file. As long as you 
# retain this notice you can do whatever you want with this stuff. If we 
# meet some day, and you think this stuff is worth it, you can buy me a 
# cappuchino in return. Rainer Wichmann @ Oct 30, 2005
# ----------------------------------------------------------------------------
#
#      Add the following three lines to the bottom of /etc/hosts.allow:
#
#      #__START_SSHBLOCK__
#      #__END_SSHBLOCK__
#      sshd : ALL : spawn (/usr/local/bin/sshblock.sh %a)&
#
#
############################################
#
# Configurable parameters. NO SPACE before
#   or after the '='.
#
############################################

# your own domain 
DONTBLOCK=192.168

# block host if more than BURST_MAX connections within BURST_TIM seconds
BURST_MAX=7
BURST_TIM=900

# remove block after PURGE_TIM seconds
PURGE_TIM=3600

# the temporary file: do not use a world writeable directory
tmpfile=/root/hosts.allow

############################################
#
# Nothing to change below
#
############################################

PATH="/bin:/usr/bin:/sbin:/usr/sbin"; export PATH

# the only argument is the remote IP address
# 
if [ -z "$1" ]; then
    logger -p auth.err "sshblock: called without argument"
    exit 1
fi

#
# date must support the %s format (seconds after the epoch)
#
now=`date +%s`
if [ $? -ne 0 ]; then
    logger -p auth.err "sshblock: the date command exited on error"
    exit 1
fi

debug=
host=`echo "$1" | sed s%.*:%%`
host_pending=0
LOCKDIR="${tmpfile}.lock"

cleanup()
{
  logger -p auth.err "sshblock: caught signal ... cleaning up."
  /bin/rm -f "${tmpfile}"
  /bin/rmdir "${LOCKDIR}"
}

trap '/bin/rm -f "${tmpfile}"; /bin/rmdir "${LOCKDIR}"'  0
trap "cleanup; exit 2" 1 2 3 15
#
# A lockfile will not work, because 'root' can write anyway.
# However, 'mkdir' an existing directory will fail even for root
#
until (umask 222; mkdir $LOCKDIR) 2>/dev/null   # test & set
do
   set x `ls -ld "${LOCKDIR}"`
   logger -p auth.err "sshblock: waiting for user $4 (working since $7 $8)"
   sleep 1
done

rm -f "$tmpfile"; touch "$tmpfile"

grep "$host" /etc/hosts.allow | grep 'DENY' | egrep '^sshd' >/dev/null 2>&1
if [ $? -eq 0 ]; then
    logger -p auth.err "sshblock: connection by blocked host ${host}" 
fi

while read -r line
do
  case "$line" in
      *TIMESTAMP*)
	  read follow;
	  case "$follow" in
	      sshd*)
		  date1=`echo $line | cut -d ' ' -f 2`
		  let "ddiff = now - date1"
		  if [ $ddiff -lt ${PURGE_TIM} ]; then
		      echo "$line" >>"$tmpfile"
		      echo "$follow" >>"$tmpfile"
		  else
		      purge=`echo $follow | awk '{ print $3 }'`
		      logger -p auth.info "sshblock: purging host $purge"
		      test -z "$debug" || echo "purging host $purge"
		  fi
		  ;;
	      *)
		  echo "$line" >>"$tmpfile"
		  echo "$follow" >>"$tmpfile"
		  logger -p auth.err "sshblock: /etc/hosts.allow corrupt"
		  test -z "$debug" || echo "/etc/hosts.allow corrupt"
		  test -z "$debug" || echo "follow: $follow"
		  ;;
	  esac
	  ;;
      *PENDING*)
	  date=`echo $line | cut -d ' ' -f 2`
	  freq=`echo $line | cut -d ' ' -f 3`
	  pend=`echo $line | cut -d ' ' -f 4`
	  if [ x"$host" = x"$pend" ]; then
	      host_pending=1
	  fi
	  let "ddiff = now - date"
	  if [ $ddiff -lt ${BURST_TIM} -a x"$host" = x"$pend" ]; then
	      if [ $freq -ge ${BURST_MAX} ]; then
		  echo "#TIMESTAMP $now" >>"$tmpfile"
		  echo "sshd : ${host} : DENY" >>"$tmpfile"
		  logger -p auth.info "sshblock: blocking $host"
		  test -z "$debug" || echo "blocking $host"
	      else
		  let "freq = freq + 1"
		  echo "#PENDING $date $freq $pend" >>"$tmpfile"
	      fi
	  elif [ $ddiff -gt ${BURST_TIM} ]; then
	      test -z "$debug" || echo "remove $host from pending"
	  else
	      echo "$line" >>"$tmpfile"
          fi
	  ;;
      *END_SSHBLOCK*)
	  if [ ${host_pending} -eq 0 ]; then
	      case "$host" in 
		  "$DONTBLOCK"*)
		      echo "$line" >>"$tmpfile"
		      test -z "$debug" || echo "$host not added to pending"
		      ;;
		  127.0.0*)
		      echo "$line" >>"$tmpfile"
		      test -z "$debug" || echo "$host not added to pending"
		      ;;
		  *)
		      echo "#PENDING $now 1 $host" >>"$tmpfile"
		      echo "$line" >>"$tmpfile"
		      ;;
	      esac
	  else
	      echo "$line" >>"$tmpfile"
	  fi
	  ;;
      *)
	  echo "$line" >>"$tmpfile"
	  ;;
  esac
done < /etc/hosts.allow

if [ $? -eq 0 ]; then
    diff "$tmpfile" /etc/hosts.allow >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        cat "$tmpfile" >/etc/hosts.allow
    fi
fi
