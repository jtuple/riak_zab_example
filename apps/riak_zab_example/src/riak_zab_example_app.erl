-module(riak_zab_example_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    riak_core_util:start_app_deps(riak_zab_example),

    case riak_zab_example_sup:start_link() of
        {ok, Pid} ->
            riak_core:register_vnode_module(riak_zabexample_vnode),
            riak_core_node_watcher:service_up(riak_zabexample, self()),
            {ok, Pid};
        {error, Reason} ->
            {error, Reason}
    end.

stop(_State) ->
    ok.
