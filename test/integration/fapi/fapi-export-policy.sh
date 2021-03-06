#!/bin/bash

set -e
source helpers.sh

start_up

setup_fapi

function cleanup {
    tss2_delete --path /
    shut_down
}

trap cleanup EXIT

KEY_PATH="HS/SRK/myRSASign"
POLICY_NAME=policy_pcr
POLICY_DATA=$TEMP_DIR/pol_pcr16_0.json
JSON_POLICY=policy/pcr-policy
EXPORTED_POLICY=$TEMP_DIR/exported-pcr-policy

tss2_provision

tss2_import --path $JSON_POLICY --importData $POLICY_DATA

tss2_createkey --path $KEY_PATH --type "noDa, sign" --policyPath $JSON_POLICY \
    --authValue ""

tss2_exportpolicy --path $KEY_PATH --jsonPolicy $EXPORTED_POLICY --force

if [ ! -s $EXPORTED_POLICY ]
then
     echo "Exported policy is empty"
     exit 1
fi

expect <<EOF
# Try with missing path
spawn tss2_exportpolicy --jsonPolicy $EXPORTED_POLICY
set ret [wait]
if {[lindex \$ret 2] || [lindex \$ret 3] != 1} {
    Command has not failed as expected\n"
    exit 1
}
EOF

expect <<EOF
# Try with missing jsonPolicy
spawn tss2_exportpolicy --path $KEY_PATH
set ret [wait]
if {[lindex \$ret 2] || [lindex \$ret 3] != 1} {
    Command has not failed as expected\n"
    exit 1
}
EOF

exit 0