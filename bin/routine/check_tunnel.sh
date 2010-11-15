#!/usr/bin/bash
server=bb
createTunnel() {
    /usr/bin/ssh -f -N -L13306:127.0.0.1:3306 -L19922:127.0.0.1:22 ${server}
    if [[ $? -eq 0 ]]; then
        echo Tunnel to ${server} created successfully
        else
        echo An error occurred creating a tunnel to ${server} RC was $?
    fi
}
## Run the 'ls' command remotely.  If it returns non-zero, then create a new connection
/usr/bin/ssh -p 19922 localhost /bin/true
if [[ $? -ne 0 ]]; then
echo Creating new tunnel connection to ${server}
createTunnel
fi
