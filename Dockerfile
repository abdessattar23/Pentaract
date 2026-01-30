############################################################################################
#### SERVER (Rust)
############################################################################################

FROM rust:1.75-slim AS chef
WORKDIR /app
RUN cargo install cargo-chef

FROM chef AS planner
COPY ./pentaract .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY ./pentaract .
RUN cargo build --release

############################################################################################
#### UI
############################################################################################

FROM node:21-slim AS ui
WORKDIR /app
COPY ./ui .
RUN npm install -g pnpm
RUN pnpm install
ENV VITE_API_BASE=/api
RUN pnpm run build

############################################################################################
#### RUNTIME
############################################################################################

FROM debian:bookworm-slim AS runtime
WORKDIR /app
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/pentaract /app/pentaract
COPY --from=ui /app/dist /app/ui

EXPOSE 8000
ENTRYPOINT ["/app/pentaract"]
