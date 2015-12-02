#!/bin/bash
##====================================
### SETTING FOR YOUR SYSTEM -- START

GATLING_HOME=/usr/local/gatling
GATLING_SIMULATIONS_DIR=$GATLING_HOME/user-files/simulations
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh

GATLING_REPORT_DIR=$GATLING_HOME/results/
GATHER_REPORTS_DIR=$GATLING_HOME/reports/

USER_NAME={{ gatling_run_user }}
### SETTING FOR YOUR SYSTEM -- END
##====================================

REPORT_SUBDIR=$1
PACKAGE_NAME=$2
CLASS_NAME=$3
SIMULATION_NAME="${PACKAGE_NAME}.${CLASS_NAME}"
ORG_HOST=$4

$GATLING_RUNNER -nr -on $GATLING_REPORT_DIR/$REPORT_SUBDIR -bdf $GATLING_HOME/user-files/bodies/$PACKAGE_NAME -s $SIMULATION_NAME  > /tmp/gatling.run.log 2>&1
mv $GATLING_REPORT_DIR/$REPORT_SUBDIR* $GATLING_REPORT_DIR/$REPORT_SUBDIR
scp -i ~/.ssh/gatling_sshkey.priv -oStrictHostKeyChecking=no $GATLING_REPORT_DIR/$REPORT_SUBDIR/simulation.log $USER_NAME@$ORG_HOST:$GATHER_REPORTS_DIR/$REPORT_SUBDIR/simulation-`hostname`.log