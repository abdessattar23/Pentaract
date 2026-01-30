############################################################################################
#### SERVER (Rust)
############################################################################################

FROM rust:1.75-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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
