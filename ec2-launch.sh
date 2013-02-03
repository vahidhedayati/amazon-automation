#!/bin/bash

##############################################################################
# Bash script written by Vahid Hedayati Jan 2013
##############################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#
##############################################################################

#variables required for the instance creation ssh etc
DEFAULT_SSH_USER="ec2-user"
DEFAULT_INSTANCE_TYPE="t1.micro"

# Your pem file to ssh in with keyname used for ec2-run
keyName="vv"
keyLocation="./vv.pem"
secGroup="sg-8c7e72e4"
DEFAULT_AMU_ID="ami-1624987f"

# How many seconds to wait before sshing in
WAIT_TIME=120;


#return usage
function usage () {
	echo "REFER TO http://aws.amazon.com/amazon-linux-ami/"
  echo "$0 -u ubuntu -n instances -t instance_type -z singapore -s is32  -a \"httpd tomcat\" "|
	echo "$0 -u ec2-user -n 2 -t m1.small -z oregon -s ebs64 -a \"httpd tomcat\""
	echo "-- above will create 2 instances of m1.small"
	echo "$0 -u ec2-user -n 2  -z ireland -s cgebs64  -a \"httpd tomcat\""
	echo "-- not -t sets default value of t1.micro"
	echo "-- -a adds applications"
	echo "default user is ec2-user no need to define -u if default required"
}


# This function creates the instances and returns the instance id finall gets the server name to pass to setjetty 
function createinstances() { 

	if [ "$INSTANCE_TYPE" == "" ]; then
                INSTANCE_TYPE=$DEFAULT_INSTANCE_TYPE;
        fi

	map_amu_id;

	for ((i=0; i < $INSTANCES; i++)) { 
		INSTANCE_ID=$(ec2-run-instances -k $keyName -g $secGroup  -t $INSTANCE_TYPE $AMU_ID | awk '/INSTANCE/{print $2}')
		echo "created  $INSTANCE_ID waiting $WAIT_TIME seconds" 
		sleep $WAIT_TIME

		SERVER=$(ec2-describe-instances $INSTANCE_ID | awk '/INSTANCE/{print $4}')
		echo "New server name: $SERVER"
		installapps;
	}

}


# This ssh's in to the box and gets the jetty file and installs it
function installapps() { 
	echo "sshing to server and setting up defined rpms on  $SERVER"

	## if user has not been define
	if [ "$SSH_USER" == "" ]; then
		SSH_USER=$DEFAULT_SSH_USER;
	fi
	echo "USER is $SSH_USER"

	#ssh -t -o BatchMode=yes -o LogLevel=Error -l $SSH_USER $SERVER  sudo yum install -y $APPS
	COMMAND="ssh -t -i $keyLocation $SSH_USER@$SERVER -o StrictHostKeyChecking=no -C \"sudo yum install -y $APPS\""
	echo $COMMAND
	$(COMMAND)
}


function map_amu_id() { 

	if [ "$ZONE" == "" ]; then 
		AMU_ID=$DEFAULT_AMU_ID;
	else

		declare -A virginia
		virginia=([ebs32]=ami-1a249873 [ebs64]=ami-1624987f [is32]=ami-10249879 [is64]=ami-e8249881 [ccebs64]=ami-08249861 [cgebs64]=ami-02f54a6b)
		declare -A oregon
		oregon=([ebs32]=ami-2231bf12 [ebs64]=ami-2a31bf1a [is32]=ami-2c31bf1c [is64]=ami-2e31bf1e [ccebs64]=ami-2431bf14)
		declare -A california
		california=([ebs32]=ami-19f9de5c [ebs64]=ami-1bf9de5e [is32]=ami-27f9de62 [is64]=ami-21f9de64)
		declare -A ireland
		ireland=([ebs32]=ami-937474e7 [ebs64]=ami-c37474b7 [is32]=ami-cf7474bb [is64]=ami-b57474c1 [ccebs64]=ami-d97474ad [cgebs64]=ami-1b02026f)
		declare -A singapore
		singapore=([ebs32]=ami-a2a7e7f0 [ebs64]=ami-a6a7e7f4 [is32]=ami-aaa7e7f8 [is64]=ami-a8a7e7fa)
		declare -A tokyo
		tokyo=([ebs32]=ami-486cd349 [ebs64]=ami-4e6cd34f [is32]=ami-586cd359 [is64]=ami-5a6cd35b)
		declare -A sydney
		sydney=([ebs32]=ami-b3990e89 [ebs64]=ami-bd990e87 [is32]=ami-bf990e85 [is64]=ami-43990e79)
		declare -A saopaolo
		saopaolo=([ebs32]=ami-e209d0ff [ebs64]=ami-1e08d103 [is32]=ami-1a08d107 [is64]=ami-1608d10b)


		if [[ $zone =~ virginia ]]; then
			sid=${virginia[$STYPE]}
		elif  [[ $zone =~ oregon ]]; then
        		sid=${oregon[$STYPE]}
		elif  [[ $zone =~ california ]]; then
        		sid=${california[$STYPE]}
		elif  [[ $zone =~ ireland ]]; then
        		sid=${ireland[$STYPE]}
		elif  [[ $zone =~ singapore ]]; then
        		sid=${singapore[$STYPE]}
		elif  [[ $zone =~ tokyo ]]; then
        		sid=${tokyo[$STYPE]}
		elif  [[ $zone =~ sydney ]]; then
        		sid=${sydney[$STYPE]}
		elif  [[ $zone =~ saopaolo ]]; then
        		sid=${saopaolo[$STYPE]}
		fi

		if [ "$sid" == "" ]; then
			AMU_ID=$DEFAULT_AMU_ID;
		else
			AMU_ID=$sid;
		fi


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
	--itype|-t)
		INSTANCE_TYPE=$2;
		shift
	     ;;	
	--zone|-z)
		ZONE=$2;
		shift;
            ;;
	--stype|-s)
		STYPE=$2;
		shift;
	   ;;
        --apps|-a)
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

