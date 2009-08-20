#!/bin/sh

# L1Trigger O2O - set IOVs

nflag=0
oflag=0
while getopts 'noh' OPTION
  do
  case $OPTION in
      n) nflag=1
          ;;
      o) oflag=1
          ;;
      h) echo "Usage: [-n] runnum tsckey"
          echo "  -n: no RS"
          echo "  -o: overwrite RS keys"
          exit
          ;;
  esac
done
shift $(($OPTIND - 1))

# arguments
run=$1
key=$2

release=CMSSW_3_1_0
version=006

echo "`date` : o2o-setIOV.sh $run $key" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log

if [ $# -lt 2 ]
    then
    echo "Wrong number of arguments.  Usage: $0 [-n] runnum tsckey" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log
    exit 127
fi

# set up environment variables
cd /cmsnfshome0/nfshome0/popcondev/L1Job/${release}/o2o
source /nfshome0/cmssw2/scripts/setup.sh
eval `scramv1 run -sh`

# Check for semaphore file
if [ -f o2o-setIOV.lock ]
    then
    echo "$0 already running.  Aborting process."
    exit 50
else
    touch o2o-setIOV.lock
fi

# Delete semaphore and exit if any signal is trapped
# KILL signal (9) is not trapped even though it is listed below.
trap "rm -f o2o-setIOV.lock; mv tmp.log tmp.log.save; exit" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64

# run script; args are run key tagbase
rm -f tmp.log
echo "`date` : setting TSC IOVs" >& tmp.log
$CMSSW_BASE/src/CondTools/L1Trigger/scripts/runL1-O2O-iov.sh -x ${run} ${key} CRAFT09 >> tmp.log 2>&1
o2ocode1=$?

o2ocode2=0
if [ ${nflag} -eq 0 ]
    then
    echo "`date` : setting RS keys and IOVs" >> tmp.log 2>&1
    if [ ${oflag} -eq 0 ]
	then
	$CMSSW_BASE/src/CondTools/L1Trigger/scripts/runL1-O2O-rs.sh -x ${run} CRAFT09 >> tmp.log 2>&1
	o2ocode2=$?
    else
	$CMSSW_BASE/src/CondTools/L1Trigger/scripts/runL1-O2O-rs.sh -x -o ${run} CRAFT09 >> tmp.log 2>&1
	o2ocode2=$?
    fi
fi

if [ ${o2ocode2} -eq 66 ]
    then
    echo "The OMDS user name or password is incorrect.  Check that /nfshome0/centraltspro/secure/authentication.xml is up to date." | tee -a tmp.log
fi

cat tmp.log | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log
#cat tmp.log >> /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log 2>&1 # use w/o ssh
#cat tmp.log # causes timeout

# log TSC key and RS keys
echo "runNumber=${run} tscKey=${key}" >> /nfshome0/popcondev/L1Job/keylogs/tsckeys.txt

if [ ${nflag} -eq 0 ]
    then
    grep KEYLOG tmp.log | sed 's/KEYLOG //' >> /nfshome0/popcondev/L1Job/keylogs/rskeys.txt
fi

rm -f tmp.log

echo "cmsRun status (TSC) ${o2ocode1}" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log
echo "cmsRun status (RS) ${o2ocode2}" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log
o2ocode=`echo ${o2ocode1} + ${o2ocode2} | bc`
echo "exit code ${o2ocode}" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log

if [ ${o2ocode} -eq 0 ]
    then
    echo "o2o-setIOV.sh successful"
else
    echo "o2o-setIOV.sh error!"
fi

echo "`date` : o2o-setIOV.sh finished : ${run} ${key}" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log
echo "" | tee -a /nfshome0/popcondev/L1Job/o2o-setIOV-${version}.log

# Delete semaphore file
rm -f o2o-setIOV.lock

exit ${o2ocode}
