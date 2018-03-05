-module(ewsc).

-export([
    connect/1, connect/2, connect/3,
    disconnect/1,

    send/2,
    recv/1, recv/2
]).

-include_lib("wsock/include/wsock.hrl").

-define(ConnectOptions, [
    binary,
    {active, false}
]).

connect(Url) -> connect(Url, [], []).
connect(Url, Headers) -> connect(Url, Headers, []).

connect(Url, Headers, Options) when is_list(Url) ->
    case http_uri:parse(Url) of
        {ok, Result} -> connect(Result, Headers, Options);
        {error, Reason} -> {error, Reason}
    end;

connect({Schema, _UserInfo, Host, Port, Path, Query}, Headers, Options) ->
    connect({tcp_module(Schema), Host, Port, Path ++ Query}, Headers, Options);

connect({Tcp, Host, Port, Resource}, Headers, Options) -> cpf_funs:do_while([
    {socket, fun Tcp:connect/3, [Host, Port, ?ConnectOptions ++ Options]},
    {request, fun wsock_handshake:open/3, [Resource, Host, Port]},
    {request_encoded, fun wsock_http_encode/2, [{request}, Headers]},
    {send, fun Tcp:send/2, [{socket}, {request_encoded}]},
    {response, fun Tcp:recv/2, [{socket}, 0]},
    {response_decoded, fun wsock_http:decode/2, [{response}, response]},
    {handled_response, fun wsock_handshake:handle_response/2,
                       [{response_decoded}, {request}]},
    {connection, fun(Socket) -> {ok, Socket} end, [{socket}]}
]).

disconnect(Socket) -> (tcp_module(Socket)):close(Socket).

send(Socket, Data) when is_list(Data) ->
    tcp_send(Socket, wsock_message:encode(Data, [mask, binary]));

send(Socket, ping) ->
    tcp_send(Socket, wsock_message:encode([], [mask, ping]));

send(Socket, pong) ->
    tcp_send(Socket, wsock_message:encode([], [mask, pong]));

send(Socket, close) ->
    tcp_send(Socket, wsock_message:encode([], [close]));

send(Socket, {close, {StatusCode, Data}}) ->
    tcp_send(Socket, wsock_message:encode({StatusCode, Data}, [mask, close])).

recv(Socket) -> recv(Socket, infinity).
recv(Socket, Timeout) -> recv_decode(Socket, Timeout, [], false). 

recv_decode(Socket, Timeout, ReceivedMessages, FragmentedMessage) ->
    case tcp_recv(Socket, Timeout) of
        {ok, Packet} -> recv_decode(
            Socket, Timeout, Packet,
            ReceivedMessages, FragmentedMessage
        );
        {error, Reason} -> {error, Reason}
    end.

recv_decode(Socket, Timeout, Packet, ReceivedMessages, FragmentedMessage) ->
    case decode(Packet, ReceivedMessages, FragmentedMessage) of
        {done, Messages} -> {ok, lists:reverse(Messages)};
        {{fragmented, Message}, Messages} ->
            recv_decode(Socket, Timeout, Messages, {fragmented, Message})
    end.

decode(Packet, ReceivedMessages, FragmentedMessage) ->
    DecodedMessages = case FragmentedMessage of
        {fragmented, Message} -> wsock_message:decode(Packet, Message, []);
        false -> wsock_message:decode(Packet, [])
    end,
    lists:foldl(fun read_message/2, {done, ReceivedMessages}, DecodedMessages).

read_message(Message = #message{type = fragmented}, {done, Messages}) ->
    {{fragmented, Message}, Messages};

read_message(#message{type = ping}, {done, Messages}) ->
    {done, [ping|Messages]};

read_message(#message{type = pong}, {done, Messages}) ->
    {done, [pong|Messages]};

read_message(#message{type = close}, {done, Messages}) ->
    {done, [close|Messages]};

read_message(#message{payload = Payload}, {done, Messages}) ->
    {done, [Payload|Messages]}.

wsock_http_encode(HandshakeRequest, Headers) ->
    Message = HandshakeRequest#handshake.message,
    wsock_http:encode(Message#http_message{
        headers = Message#http_message.headers ++ Headers
    }).

tcp_send(Socket, Packet) -> (tcp_module(Socket)):send(Socket, Packet).
tcp_recv(Socket, Timeout) -> (tcp_module(Socket)):recv(Socket, 0, Timeout).

tcp_module(wss) -> ssl;
tcp_module(https) -> ssl;
tcp_module(Scheme) when is_atom(Scheme) -> gen_tcp;

tcp_module(_Socket = {sslsocket, _, _}) -> ssl;
tcp_module(Socket) when is_port(Socket) -> gen_tcp.
