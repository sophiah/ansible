#!/bin/bash
##################################################################################################################
#Gatling scale out/cluster run script:
#If you are using the packer images this should run out of the box
#Before running this script some assumptions are made:
#1) Public keys were exchange inorder to ssh with no password promot (ssh-copy-id on all remotes)
#2) Check  read/write permissions on all folders declared in this script.
#3) Gatling installation (GATLING_HOME variable) is the same on all hosts
#4) Assuming all hosts has the same user name (if not change in script)
##################################################################################################################

if [ $# -lt 2 ]; then
  echo "Usage: package simultaion_name"
  exit
fi

#Assuming same user name for all hosts
USER_NAME={{ gatling_run_user }}

#Remote hosts list
HOSTS=( {{ groups["gatling_slave"] | join(" ") }} )

#Assuming all Gatling installation in same path (with write permissions)
GATLING_HOME=/usr/local/gatling
GATLING_SIMULATIONS_DIR=$GATLING_HOME/user-files/simulations
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh

#Change to your simulation class name
PACKAGE_NAME=$1
CLASS_NAME=$2
SIMULATION_NAME="${1}.${2}"

#No need to change this
GATLING_REPORT_DIR=$GATLING_HOME/results/
GATHER_REPORTS_DIR=$GATLING_HOME/reports/


echo "Starting Gatling cluster run for simulation: $SIMULATION_NAME"
CURRTIME=`date "+%Y%m%d-%H%M%S"`
REPORT_SUBDIR=$SIMULATION_NAME-$CURRTIME
MY_HOST=`hostname`

sshkey_path=`readlink -f ~{{ gatling_run_user }}/.ssh/gatling_sshkey.priv`
ssh_option="-i $sshkey_path -oStrictHostKeyChecking=no"

mkdir -p $GATHER_REPORTS_DIR/$REPORT_SUBDIR

for HOST in "${HOSTS[@]}"
do
  echo "Copying simulations to host: $HOST"
  scp ${ssh_option} -r $GATLING_HOME/user-files/* $USER_NAME@$HOST:$GATLING_HOME/user-files
done

for HOST in "${HOSTS[@]}"
do
  echo "Running simulation on host: $HOST"
  ssh ${ssh_option} -n -f $USER_NAME@$HOST "nohup $GATLING_HOME/bin/gatling_cluster_slave.sh $REPORT_SUBDIR $PACKAGE_NAME $CLASS_NAME $MY_HOST &"
done

echo "Running simulation on localhost"
$GATLING_RUNNER -nr -on $GATLING_REPORT_DIR/$REPORT_SUBDIR -bdf $GATLING_HOME/user-files/bodies/$PACKAGE_NAME -s $SIMULATION_NAME


echo "Gathering result file from localhost"
mv $GATLING_REPORT_DIR/$REPORT_SUBDIR* $GATLING_REPORT_DIR/$REPORT_SUBDIR
cp $GATLING_REPORT_DIR/$REPORT_SUBDIR/simulation.log $GATHER_REPORTS_DIR/$REPORT_SUBDIR


for HOST in "${HOSTS[@]}"
do
  CURRENT_HOST=`echo $HOST | tr '[:upper:]' '[:lower:]' | awk -F. '{ print $1 }'`
  echo -n "Checking result file from host: $CURRENT_HOST"
  while [ 1 ]
  do
    if [ -f "${GATHER_REPORTS_DIR}/$REPORT_SUBDIR/simulation-$CURRENT_HOST.log" ]; then
        echo " ..... got"
        break
    fi
  done
done

echo "Aggregating simulations"
$GATLING_RUNNER -ro ${GATHER_REPORTS_DIR}/$REPORT_SUBDIR
