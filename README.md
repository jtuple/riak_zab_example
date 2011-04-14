riak_zab_example
================

Quick Start
-----------

Assuming you already have Erlang installed, clone this repository, and build
it: make. Assuming all goes well, build a development release: make devrel.

Now, you can play around with things. For simplicity, I'm going to assume
you're running within a X session and have xterm. Other scenarios are left
as an exercise to the reader.

Start four Erlang nodes running riak_zab_example:
     > xterm -hold -e './dev/dev1/bin/riak_zab_example console' &
     > xterm -hold -e './dev/dev2/bin/riak_zab_example console' &
     > xterm -hold -e './dev/dev3/bin/riak_zab_example console' &
     > xterm -hold -e './dev/dev4/bin/riak_zab_example console' &

Join the four nodes into a single cluster. Joining all four nodes together
sometimes results in riak_core making an unbalanced ring.  This doesn't seem to
occur if we first build a three node cluster, then add the fourth node. Note:
You'll want to ensure that ringready returns TRUE (as shown) before moving to
the next step.

     > ./dev/dev1/bin/riak-zab-admin join dev2@127.0.0.1
     Sent join request to dev2@127.0.0.1
     > ./dev/dev2/bin/riak-zab-admin join dev3@127.0.0.1
     Sent join request to dev3@127.0.0.1
     > ./dev/dev3/bin/riak-zab-admin join dev1@127.0.0.1
     Sent join request to dev1@127.0.0.1
     > ./dev/dev1/bin/riak-zab-admin ringready
     TRUE All nodes agree on the ring ['dev1@127.0.0.1','dev2@127.0.0.1',
                                       'dev3@127.0.0.1']

     > ./dev/dev4/bin/riak-zab-admin join dev1@127.0.0.1
     Sent join request to dev1@127.0.0.1
     > ./dev/dev4/bin/riak-zab-admin ringready
     TRUE All nodes agree on the ring ['dev1@127.0.0.1','dev2@127.0.0.1',
                                       'dev3@127.0.0.1','dev4@127.0.0.1']

Fire up Zab on all the nodes.
     > ./dev/dev1/bin/riak-zab-admin zab-up
     > ./dev/dev2/bin/riak-zab-admin zab-up
     > ./dev/dev3/bin/riak-zab-admin zab-up
     > ./dev/dev4/bin/riak-zab-admin zab-up

Assuming all goes well, you should see a few info messages on the node consoles
that end with different ensembles successfully electing a leader. If the ring
ended up being balanced, you should have a riak_zab state similar to the
following.
     > ./dev/dev1/bin/riak-zab-admin info
     ================================ Riak Zab Info ================================
     Ring size:     64
     Ensemble size: 3
     Nodes:         ['dev1@127.0.0.1','dev2@127.0.0.1','dev3@127.0.0.1',
                     'dev4@127.0.0.1']
     ================================== Ensembles ==================================
     Ensemble     Ring   Leader                         Nodes
     -------------------------------------------------------------------------------
            1    25.0%   dev2@127.0.0.1                 ['dev1@127.0.0.1',
                                                         'dev2@127.0.0.1',
                                                         'dev3@127.0.0.1']
     -------------------------------------------------------------------------------
            2    25.0%   dev2@127.0.0.1                 ['dev1@127.0.0.1',
                                                         'dev2@127.0.0.1',
                                                         'dev4@127.0.0.1']
     -------------------------------------------------------------------------------
            3    25.0%   dev3@127.0.0.1                 ['dev1@127.0.0.1',
                                                         'dev3@127.0.0.1',
                                                         'dev4@127.0.0.1']
     -------------------------------------------------------------------------------
            4    25.0%   dev3@127.0.0.1                 ['dev2@127.0.0.1',
                                                         'dev3@127.0.0.1',
                                                         'dev4@127.0.0.1']
     -------------------------------------------------------------------------------

Up to this point you're dealing with standard riak_core / riak_zab. Now, let's play
around a bit with the command set provided by riak_zab_example. The example app
implements a simple list based log. There is a store command that appends elements
to a list, and a get command that retrieves the current list. In your Erlang consoles,
you can use commands in the following form:
     riak_zab_util:command(100, {store, 100, 1}, riak_zabexample_vnode_master).
     riak_zab_util:command(100, {store, 100, 6}, riak_zabexample_vnode_master).
     riak_zab_util:command(200, {store, 200, 1}, riak_zabexample_vnode_master).
     riak_zab_util:command(200, {store, 200, 6}, riak_zabexample_vnode_master).
     riak_zab_util:sync_command(100, {get, 100}, riak_zabexample_vnode_master).
     riak_zab_util:sync_command(200, {get, 200}, riak_zabexample_vnode_master).

Feel free to kill/restart nodes as desired, as well as send commands while a
node is down and see what happens when the node restarts. For more verbose
output, you can modify the riak_zab source in deps/riak_zab/src and enable
all the DOUT defines to print output to the console and recompile. This
should probably be made easier in the future.
