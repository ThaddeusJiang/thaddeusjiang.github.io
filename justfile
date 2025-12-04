_ensure-tiddlywiki:
    #!/usr/bin/env sh
    if ! command -v tiddlywiki >/dev/null 2>&1; then
        mise use -g npm:tiddlywiki
    fi

start: _ensure-tiddlywiki
    #!/usr/bin/env sh
    PORT=8000
    (sleep 2 && open -a Safari http://localhost:$PORT) &
    tiddlywiki --listen port=$PORT username=TJ
