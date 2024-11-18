FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt-get -y install git make cmake wget curl gcc g++ clang llvm lld

RUN apt update && apt-get -y install jq

# ------------------------------------------------------------------------------

# Force the cache to break if there have been new commits
ADD https://api.github.com/repos/jhonnold/berserk/git/refs/heads/main /.git-hashref

# ------------------------------------------------------------------------------

# Determine the default Network via the API
RUN echo $(curl http://chess.grantnet.us/api/networks/Berserk/ |jq -r '.default.sha') >> /.default-net

# Download the default Network, using GRANTNET_USER and GRANTNET_PASS secrets
RUN --mount=type=secret,id=GRANTNET_USER --mount=type=secret,id=GRANTNET_PASS \
    curl -X POST \
       -F "username=$(cat /run/secrets/GRANTNET_USER)" \
       -F "password=$(cat /run/secrets/GRANTNET_PASS)" \
       http://chess.grantnet.us/api/networks/Berserk/$(cat /.default-net)/ \
       --output berserk.default.nn

# Clone and build from main
RUN git clone https://github.com/jhonnold/berserk.git && \
    cd berserk/src && \
    git checkout main && \
    make build -j ARCH=native EXE=berserk CC=clang EVALFILE=../../berserk.default.nn

CMD [ "./berserk/src/berserk" ]
