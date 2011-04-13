%% -*- tab-width: 4;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
{application,riak_zab_example,
             [{description,[]},
              {vsn,"0.1.0"},
              {registered,[]},
              {applications, [
                              kernel,
                              stdlib,
                              riak_core,
                              riak_zab
                             ]},
              {mod,{riak_zab_example_app,[]}},
              {env,[]},
              {modules, [
                         riak_zab_example_app,
                         riak_zab_example_sup,
                         riak_zabexample_vnode
                        ]}
             ]}.
