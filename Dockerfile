# Builds a docker image with all the dependencies needed
# to run build.sh.
# Note that the project directory must be mounted when
# running the image resulting from this Dockerfile.

FROM debian:stable-slim

RUN apt update && apt install -y build-essential curl git liblua5.4-dev lua5.4 sudo tree zip

# install rust and cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="$PATH:/root/.cargo/bin"

# cache the dependencies of the cargo project
WORKDIR /cargo-deps-project
COPY esp-generator/Cargo.toml esp-generator/Cargo.lock /cargo-deps-project/
RUN mkdir /cargo-deps-project/src && \
    echo 'fn main() {}' > /cargo-deps-project/src/main.rs && \
    cargo build --release

# install lua, luarocks, teal and cyan
RUN curl -sf -L https://luarocks.org/releases/luarocks-3.11.1.tar.gz | tar zx
RUN cd luarocks-3.11.1 && ./configure && make && sudo make install
RUN luarocks install tl && luarocks install cyan

WORKDIR /workdir
CMD ["./build.sh"]