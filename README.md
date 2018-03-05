# Erlang WebSocket client library

Provides functions for working with WebSockets as a client. Based on
[wsock](http://github.com/madtrick/wsock) library.

## Usage

Connect to the WebSocket echo server:

```
1> {ok, S} = ewsc:connect("wss://echo.websocket.org").
{ok,{sslsocket,{gen_tcp,#Port<0.68832>,tls_connection,
                        undefined},
               <0.1362.0>}}
```

Send data and receive response:

```
2> ewsc:send(S, "data"). % or ewsc:send(S, <<"data">>).
ok

3> ewsc:recv(S, 1000). % timeout im milliseconds
{ok,[<<"data">>]}
```

Send ping and receive response:

```
4> ewsc:send(S, ping).
ok

5> ewsc:recv(S, 1000).
{ok,[pong]}
```

Try to receive something:

```
6> ewsc:recv(S, 1000).
{error,timeout}
```

If that was ping from the server, respond on it:

```
7> ewsc:recv(S, 1000).
{ok,[ping]}

8> ewsc:send(S, pong).
ok
```

Send close, receive confirmation and try to receive anything else:

```
9> ewsc:send(S, close).
ok

10> ewsc:recv(S, 1000).
{ok,[close]}

11> ewsc:recv(S, 1000).
{error,closed}
```

The connection can be modified with additional headers and connection options:

```
Headers = [{"Authorization", "Basic dXNlcm5hbWU6cGFzc3dvcmQK"}].
Options = [{cacertfile, "ca.pem"}].
ewsc:connect("wss://echo.websocket.org", Headers, Options).
```

See [ssl](http://erlang.org/doc/man/ssl.html)
and [gen_tcp](http://erlang.org/doc/man/gen_tcp.html) Erlang modules
documentation for more information about possible connection options.
