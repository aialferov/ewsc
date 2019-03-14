# Erlang WebSocket client library

[![License: Apache-2.0][Apache 2.0 Badge]][Apache 2.0]
[![GitHub Release Badge]][GitHub Releases]

Provides functions for working with WebSockets as a client. Based on the 
[modified][modified_wsock] version of the [wsock] library.

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

See [ssl] and [gen_tcp] Erlang modules documentation for more information about
possible connection options.

## License

Copyright 2018-2019 Anton Alferov (@aialferov)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


<!-- Links -->

[modified_wsock]: http://github.com/aialferov/wsock
[wsock]: http://github.com/madtrick/wsock
[ssl]: http://erlang.org/doc/man/ssl.html
[gen_tcp]: http://erlang.org/doc/man/gen_tcp.html

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/aialferov/ewsc/releases
[GitHub Release Badge]: https://img.shields.io/github/release/aialferov/ewsc/all.svg?style=flat-square
