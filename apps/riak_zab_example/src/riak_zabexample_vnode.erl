-module(riak_zabexample_vnode).
-behaviour(riak_core_vnode).

%% riak_core_vnode API
-export([start_vnode/1,
         init/1,
         terminate/2,
         handle_command/3,
         is_empty/1,
         delete/1,
         handle_handoff_command/3,
         handoff_starting/2,
         handoff_cancelled/1,
         handoff_finished/2,
         handle_handoff_data/2,
         encode_handoff_item/2]).

-export([hash_key/1]).

-include_lib("riak_core/include/riak_core_vnode.hrl").
-include_lib("riak_zab/include/riak_zab_vnode.hrl").

-record(state, {logs :: dict()}).

start_vnode(I) ->
    riak_core_vnode_master:get_vnode_pid(I, ?MODULE).

init([_Partition]) ->
    {ok, #state{logs=dict:new()}}.

hash_key(Key) ->
    chash:key_of(Key).

handle_command(?ZAB_SYNC{peer=Peer, idxs=Idxs}, _Sender, State) ->
    io:format("V: Synchronizing ~p with ~p :: ~p~n", [self(), Peer, Idxs]),
    riak_zab_vnode:standard_sync(?MODULE, State, Peer, Idxs),
    {reply, ok, State};

handle_command(?ZAB_SYNC_DATA{data={K,V}}, _Sender, State=#state{logs=Logs}) ->
    io:format("Received sync message~n", []),
    io:format("Log(~p) = ~p~n", [K, V]),
    Logs2 = dict:store(K, V, Logs),
    {reply, ok, State#state{logs=Logs2}};

handle_command(?ZAB_REQ{req=Req, zxid=Zxid, sender=Sender, leading=Leading},
               _Master, State) ->
    handle_zab_command(Req, Zxid, Leading, Sender, State);

handle_command(?FOLD_REQ{foldfun=Fun, acc0=Acc0}, _Sender, State=#state{logs=Logs}) ->
    Reply = dict:fold(Fun, Acc0, Logs),
    {reply, Reply, State};

handle_command(_Cmd, _Sender, State) ->
    {noreply, State}.

handle_zab_command({store, Key, Msg}, Zxid, Leading, _Sender,
                   State=#state{logs=Logs}) ->
    Logs2 = dict:append(Key, Msg, Logs),
    io:format("Received store~n"
              "     Zxid: ~p~n"
              "  Leading: ~p~n"
              "      Key: ~p~n"
              "      Msg: ~p~n",  [Zxid, Leading, Key, Msg]),
    io:format("Logs(~p) = ~p~n", [Key, dict:fetch(Key, Logs2)]),
    {reply, ok, State#state{logs=Logs2}};
handle_zab_command({get, Key}, Zxid, Leading, Sender,
                   State=#state{logs=Logs}) ->
    Res = dict:find(Key, Logs),
    io:format("Received get~n"
              "     Zxid: ~p~n"
              "  Leading: ~p~n"
              "      Key: ~p~n", [Zxid, Leading, Key]),
    io:format("Logs(~p) = ~p~n", [Key, Res]),
    maybe_reply(Leading, Sender, Res),
    {reply, ok, State};
handle_zab_command(_Req, _Zxid, _Leading, _Sender, State) ->
    {noreply, State}.

maybe_reply(true, Sender, Res) ->
    io:format("Sending reply to ~p :: ~p~n", [Sender, Res]),
    riak_zab_vnode:reply(Sender, Res),
    ok;
maybe_reply(false, _Sender, _Res) ->
    ok.

handle_handoff_command(Req=?FOLD_REQ{}, Sender, State) ->
    handle_command(Req, Sender, State);
handle_handoff_command(_Cmd, _Sender, State) ->
    {ok, State}.

handoff_starting(_Node, State) ->
    {true, State}.

handoff_cancelled(State) ->
    {ok, State}.

handoff_finished(_TargetNode, State) ->
    {ok, State}.

handle_handoff_data(BinObj, State=#state{logs=Logs}) ->
    {K, V} = binary_to_term(BinObj),
    Logs2 = dict:store(K, V, Logs),
    {reply, ok, State#state{logs=Logs2}}.

encode_handoff_item(K, V) ->
    term_to_binary({K,V}).

is_empty(State=#state{logs=Logs}) ->
    Empty = (dict:size(Logs) == 0),
    {Empty, State}.

delete(State) ->
    {ok, State#state{logs=dict:new()}}.

terminate(_Reason, _State) ->
    ok.
