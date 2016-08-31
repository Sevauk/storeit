#! /bin/bash

# RANDOM=0 TODO: tests shouldn't be random but for now we lack tests
SERVER_ADDR=localhost
PORT=7641
MAIN='build/main.js'
TESTDIR='/tmp/storeit-test'
SERVER="../server/build/main.js -u $TESTDIR/userdata"
CLIENT_COUNT=0
SRC='test-ressources/'

function clean {
  echo "cleaning first..."
  rm -rf $TESTDIR
}

function build {
  echo "building..."
 # npm run build > /dev/null && (cd ../server/; npm run build > /dev/null; cd - > /dev/null)
}

function init {
  trap "trap - EXIT && kill -- -$$" SIGINT SIGTERM EXIT
  clean
  mkdir -p $TESTDIR
  build
  (ipfs daemon > /dev/null 2>&1)&
  node $SERVER --logfile $TESTDIR/server.log&
  echo "cat $TESTDIR/server.log"
  echo "starting tests on server '$SERVER_ADDR:$PORT'"
}

function test {
  #echo -n .
  $*
  return $?
}

function runcli {
  echo "running client #$CLIENT_COUNT with account developer$1"
  echo "cat $TESTDIR/client$CLIENT_COUNT.log"
  node $MAIN --server $SERVER_ADDR:$PORT --developer $1 -d $TESTDIR/client$CLIENT_COUNT --logfile $TESTDIR/client$CLIENT_COUNT.log&
  return $((CLIENT_COUNT++))
}

function select_client {
  echo $(($RANDOM % $1))
}

function ssleep {
  echo -n "."
  sleep $1
}

function someone {
  echo $TESTDIR/client$(select_client $1)
}

function playWithFS {
  MAX=$1
  cp $SRC/hello.txt $(someone $MAX)/hi.txt
  ##ssleep 0.5
  ##mkdir $(someone $MAX)/pic
  ##ssleep 0.5
  ##cp $SRC/logo.png $(someone $MAX)/pic
  ##ssleep 0.5
  ##cli=$(someone $MAX)
  ##mv $cli/pic/logo.png $cli/pic/renamed.png
  ##ssleep 0.5
  ##mv $cli/pic/renamed.png $cli/renamed.png
}

function t1 {
  runcli 1
  sleep 1
  runcli 1
  sleep 1

  playWithFS 2
  sleep 1
  tree $TESTDIR > $TESTDIR/diff.txt
  diff $TESTDIR/diff.txt $SRC/diff1.txt
}

function t2 {
  runcli 0
  runcli 0
  runcli 0
  runcli 0
  runcli 1
  runcli 1
  runcli 1
  runcli 1
  runcli 2
  runcli 2
  runcli 3
  runcli 4
  sleep 1

  playWithFS 4
  echo "waiting 3sec..."
  sleep 3
  tree $TESTDIR > $TESTDIR/diff.txt
}

init
(test t1 &&
#test t2 &&
echo "test passed successfully") || echo "tests failure"
