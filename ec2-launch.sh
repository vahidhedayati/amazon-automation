#!/bin/bash


#variables required for the instance creation ssh etc
DEFAULT_SSH_USER="ec2-user"


# Your pem file to ssh in with keyname used for ec2-run
keyName="vv"
keyLocation="./vv.pem"
secGroup="sg-8c7e72e4"
ami="ami-1624987f"

# How many seconds to wait before sshing in
WAIT_TIME=120;


#return usage
function usage () {
  echo "$0 -u ubuntu -n instances -a \"httpd tomcat\" "
	echo "$0 -u ec2-user -n 2 -a \"httpd tomcat\""
	echo "where -a adds applications"
	echo "default user is ec2-user no need to define -u if default required"
}


# This function creates the instances and returns the instance id finall gets the server name to pass to setjetty 
function createinstances() { 
	for ((i=0; i < $INSTANCES; i++)) { 
		INSTANCE_ID=$(ec2-run-instances -k $keyName -g $secGroup  -t t1.micro $ami | awk '/INSTANCE/{print $2}')
		echo "created  $INSTANCE_ID waiting $WAIT_TIME seconds" 
		sleep $WAIT_TIME

		SERVER=$(ec2-describe-instances $INSTANCE_ID | awk '/INSTANCE/{print $4}')
		echo "New server name: $SERVER"
		installapps;
	}

}


# This ssh's in to the box and gets the jetty file and installs it
function installapps() { 
	echo "sshing to server and running jetty get on  $SERVER"

	## if user has not been define
	if [ "$SSH_USER" == "" ]; then
		SSH_USER=$DEFAULT_SSH_USER;
	fi
	echo "USER is $SSH_USER"

	#ssh -t -o BatchMode=yes -o LogLevel=Error -l $SSH_USER $SERVER  sudo yum install -y $APPS
	echo "ssh -t -i $keyLocation $SSH_USER@$SERVER -o StrictHostKeyChecking=no -C \"sudo yum install -y $APPS\""
	ssh -t -i $keyLocation $SSH_USER@$SERVER -o StrictHostKeyChecking=no -C "sudo yum install -y $APPS"
}

## Set the bash test case for input variables

while test -n "$1"; do
    case "$1" in
        --help|-h)
           usage
            exit 0
            ;;
	--user|-u)
		SSH_USER=$2;
		shift
	    ;;
        --number|-n)
		INSTANCES=$2;
		# ensure instances is a numeric value given otherwise set to 1 
		if ((INSTANCES)) 2>/dev/null; then
     			INSTANCES=$((INSTANCES))
    		else
      			INSTANCES=1;
    		fi	
		shift
            ;;

        --jettyver|-j)
		APPS=$2;
		createinstances;
		exit 0;
	  ;;
        *)
		echo "Unknown argument: $1"
	 	echo "-h for help";
		exit 1
            ;;
    esac
    shift
done

if [ $# -eq 0 ]; then
        usage;
        exit 1;
fi