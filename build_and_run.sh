#! /usr/bin/env bash
docker build -t rust_one_image . && \
docker run -it --rm -p 4943:4943 --name Rust_one_container -v "$(pwd)":/canister rust_one_image