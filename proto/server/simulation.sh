#run_client cli1
#run_client cli2
#sleep 0.5
#cd /tmp/cli2/storeit
#git init --bare
#sleep 0.5
#kill_client cli2
#rm -rf /tmp/cli2
#run_client cli2

run_client cli1
run_client cli2
sleep 1
cp -r /var/log /tmp/cli2/storeit
sleep 105
kill_client cli2
run_client cli2
#open /tmp/cli2/storeit
