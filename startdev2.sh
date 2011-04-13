xterm -hold -e './dev/dev1/bin/riak_zab_example console' &
sleep 0.5
xterm -hold -e './dev/dev2/bin/riak_zab_example console' &
sleep 0.5
xterm -hold -e './dev/dev3/bin/riak_zab_example console' &

sleep 5s

./dev/dev1/bin/riak-zab-admin join dev2@127.0.0.1
./dev/dev2/bin/riak-zab-admin join dev3@127.0.0.1
./dev/dev3/bin/riak-zab-admin join dev1@127.0.0.1
