%%% This is a special process. A special process is aware of system messages
%%% and also implements some standard functions needed (and standarized) in an
%%% OTP environment, so it can be supervised (started/stop), upgraded in a
%%% hot-upgrade fashion, etc.
%%%
%%% See http://www.erlang.org/doc/design_principles/spec_proc.html
%%% For system messages, see: http://www.erlang.org/doc/man/sys.html
-module({{id}}).
%%-----------------------------------------------------------------------------
%% API Function Exports
%%-----------------------------------------------------------------------------
-export([start_link/0, init/1, loop/3]).

%%-----------------------------------------------------------------------------
%% Required OTP Exports
%%-----------------------------------------------------------------------------
-export([
    system_code_change/4, system_continue/3,
    system_terminate/4, write_debug/3
]).

%%-----------------------------------------------------------------------------
%% API Function Definitions
%%-----------------------------------------------------------------------------
%% @doc Starts a new process synchronously. Spawns the process and waits for
%% it to start.
%% See http://www.erlang.org/doc/man/proc_lib.html
start_link() ->
    proc_lib:start_link(?MODULE, init, [self()]).

%%-----------------------------------------------------------------------------
%% API Function Definitions
%%-----------------------------------------------------------------------------
%% @doc Notifies the parent of a successful start and then runs the main loop.
%% When the process has started, it must call init_ack(Parent,Ret) or
%% init_ack(Ret), where Parent is the process that evaluates this function (
%% see start_link/0 above). At this time, Ret is returned.
init(Parent) ->
    register(?MODULE, self()),
    Debug = sys:debug_options([]),
    proc_lib:init_ack(Parent, {ok, self()}),
    loop(Parent, Debug, []).

%%-----------------------------------------------------------------------------
%% Internal Functions
%%-----------------------------------------------------------------------------
%% @doc Our main loop, designed to handle system messages.
loop(Parent, Debug, State) ->
    receive
        {system, From, Request} ->
            sys:handle_system_msg(
                Request, From, Parent, ?MODULE, Debug, State
            );
        Msg ->
            % Let's print unknown messages.
            sys:handle_debug(
                Debug, fun ?MODULE:write_debug/3, ?MODULE, {in, Msg}
            ),
            ?MODULE:loop(Parent, Debug, State)
    end.

%% @doc Called by sys:handle_debug().
write_debug(Dev, Event, Name) ->
    io:format(Dev, "~p event = ~p~n", [Name, Event]).

%% @doc http://www.erlang.org/doc/man/sys.html#Mod:system_continue-3
system_continue(Parent, Debug, State) ->
    io:format("Continue!~n"),
    ?MODULE:loop(Parent, Debug, State).

%% @doc http://www.erlang.org/doc/man/sys.html#Mod:system_terminate-4
system_terminate(Reason, _Parent, _Debug, _State) ->
    io:format("Terminate!~n"),
    exit(Reason).

%% @doc http://www.erlang.org/doc/man/sys.html#Mod:system_code_change-4
system_code_change(State, _Module, _OldVsn, _Extra) ->
    io:format("Changed code!~n"),
    {ok, State}.

