#! /bin/bash

SERVER_ADDR=localhost
PORT=7641
MAIN='build/main.js'
TESTDIR='/tmp/storeit-test'
SERVER="../server/build/main.js -u $TESTDIR/userdata"

function clean {
  echo "cleaning first..."
  rm -rf $TESTDIR
}

function init {
  trap "killall background" EXIT
  clean
  mkdir -p $TESTDIR
  npm run build
  ipfs daemon& 2> /dev/null
  node $SERVER& > $TESTDIR/server.log
  echo "starting tests on server '$SERVER_ADDR:$PORT'"
}

function test {
  echo -n .
  $* || echo " Failure."
}

function runcli {
  echo "running client #$1"
  node $MAIN --server $SERVER_ADDR:$PORT --developer $1 -d $TESTDIR/client$1 > $TESTDIR/client$1.log
}

function t1 {
  runcli 1
  sleep 1
  echo "hello world" > $TESTDIR/client1/hello.txt
}

init
test t1
