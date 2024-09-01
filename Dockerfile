FROM ubuntu:noble AS base

# ARG fnm_installation_directory="/fnm"
ARG node_version=20.17.0

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl unzip && \
    # Adding `fnm`
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "./fnm" && \
    cp ./fnm/fnm /usr/bin && \
    # Installing Node.js
    fnm install "$node_version" && \
    corepack enable && \
    # Cleaning up
    rm -rf /var/lib/apt/lists/*

COPY . /app

WORKDIR /app

FROM base AS prod-deps

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile && \
    pnpm run build


FROM base

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist

ENV PORT=3000

EXPOSE $PORT

ENTRYPOINT ["pnpm", "run"]
CMD ["preview"]
