#!/bin/sh 
DEMO="Cloud JBoss BPM Suite Install Demo"
AUTHORS="Andrew Block, Eric D. Schabell"
PROJECT="git@github.com:redhatdemocentral/rhcs-bpms-install-demo.git"
SRC_DIR=./installs
OPENSHIFT_USER=openshift-dev
OPENSHIFT_PWD=devel
HOST_IP=10.1.2.2
BPMS=jboss-bpmsuite-6.4.0.GA-deployable-eap7.x.zip
EAP=jboss-eap-7.0.0-installer.jar

# prints the documentation for this script.
function print_docs() 
{
	echo "This project can be installed on any OpenShift platform, such as OpenShift"
	echo "Container Platform or Red Hat Container Development Kit. It's possible to"
	echo "install it on any available installation by pointing this installer to an"
	echo "OpenShift IP address:"
	echo
	echo "   $ ./init.sh IP"
	echo
	echo "If using Red Hat OCP, IP should look like: 192.168.99.100"
	echo
	echo "If using Red Hat CDK, IP should look like: 10.1.2.2"
	echo
}

# check for a valid passed IP address.
function valid_ip()
{
	local  ip=$1
	local  stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi

	return $stat
}

# wipe screen.
clear 

echo
echo "###################################################################"
echo "##                                                               ##"   
echo "##  Setting up the ${DEMO}            ##"
echo "##                                                               ##"   
echo "##                                                               ##"   
echo "##     ####  ####   #   #      ### #   # ##### ##### #####       ##"
echo "##     #   # #   # # # # #    #    #   #   #     #   #           ##"
echo "##     ####  ####  #  #  #     ##  #   #   #     #   ###         ##"
echo "##     #   # #     #     #       # #   #   #     #   #           ##"
echo "##     ####  #     #     #    ###  ##### #####   #   #####       ##"
echo "##                                                               ##" 
echo "##             #### #      ###  #   # ####                       ##"
echo "##        #   #     #     #   # #   # #   #                      ##"
echo "##       ###  #     #     #   # #   # #   #                      ##"
echo "##        #   #     #     #   # #   # #   #                      ##"
echo "##             #### #####  ###   ###  ####                       ##"
echo "##                                                               ##"   
echo "##  brought to you by,                                           ##"   
echo "##             ${AUTHORS}                    ##"
echo "##                                                               ##"   
echo "##  ${PROJECT}  ##"  
echo "##                                                               ##"   
echo "###################################################################"
echo

# validate OpenShift host IP.
if [ $# -eq 1 ]; then
	if valid_ip $1; then
		echo "OpenShift host given is a valid IP..."
		HOST_IP=$1
		echo
		echo "Proceeding wiht OpenShift host: $HOST_IP..."
		echo
	else
		# bad argument passed.
		echo "Please provide a valid IP that points to an OpenShift installation..."
		echo
		print_docs
		echo
		exit
	fi
elif [ $# -gt 1 ]; then
	print_docs
	echo
	exit
else
	# no arguments, prodeed with default host.
	print_docs
	echo
	exit
fi

# make some checks first before proceeding.	
command -v oc -v >/dev/null 2>&1 || { echo >&2 "OpenShift command line tooling is required but not installed yet... download here: https://access.redhat.com/downloads/content/290"; exit 1; }

# make some checks first before proceeding.	
if [ -r $SRC_DIR/$EAP ] || [ -L $SRC_DIR/$EAP ]; then
	echo Product EAP sources are present...
	echo
else
	echo Need to download $EAP package from http://developers.redhat.com
	echo and place it in the $SRC_DIR directory to proceed...
	echo
	exit
fi

if [ -r $SRC_DIR/$BPMS ] || [ -L $SRC_DIR/$BPMS ]; then
	echo Product BPM Suite sources are present...
	echo
else
	echo Need to download $BPMS package from http://developers.redhat.com
	echo and place it in the $SRC_DIR directory to proceed...
	echo
	exit
fi

echo "OpenShift commandline tooling is installed..."
echo 
echo "Logging in to OpenShift as $OPENSHIFT_USER..."
echo
#oc login $HOST_IP:8443 --password=$OPENSHIFT_PWD --username=$OPENSHIFT_USER
oc login https://open.paas.redhat.com --token=_KBsCncDvAJCU4E0Ug4EZoGmK-o6XQYVTK0KQsp4DUU

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc login' command!
	exit
fi

echo
echo "Creating a new project..."
echo
oc new-project rhcs-bpms-install-demo 

echo
echo "Setting up a new build..."
echo
oc new-build "jbossdemocentral/developer" --name=rhcs-bpms-install-demo --binary=true

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc new-build' command!
	exit
fi

# need to wait a bit for new build to finish with developer image.
sleep 10 

echo
echo "Importing developer image..."
echo
oc import-image developer

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc import-image' command!
	exit
fi

echo
echo "Starting a build, this takes some time to upload all of the product sources for build..."
echo
oc start-build rhcs-bpms-install-demo --from-dir=. --follow=true --wait=true

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc start-build' command!
	exit
fi

echo
echo "Creating a new application..."
echo
oc new-app rhcs-bpms-install-demo

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc new-app' command!
	exit
fi

echo
echo "Creating an externally facing route by exposing a service..."
echo
oc expose service rhcs-bpms-install-demo --hostname=rhcs-bpms-install-demo.$HOST_IP.xip.io

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc expose service' command!
	exit
fi

echo
echo "===================================================================="
echo "=                                                                  ="
echo "=  Login to JBoss BPM Suite to start developing process projects:  ="
echo "=                                                                  ="
echo "=  http://rhcs-bpms-install-demo.$HOST_IP.xip.io/business-central  ="
echo "=                                                                  ="
echo "=  [ u:erics / p:jbossbpm1! ]                                      ="
echo "=                                                                  ="
echo "=  Note: it takes a few minutes to expose the service...           ="
echo "=                                                                  ="
echo "===================================================================="

