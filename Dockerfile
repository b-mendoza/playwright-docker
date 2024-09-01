FROM ubuntu:noble AS base

WORKDIR /app

COPY . /app

RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    ca-certificates curl unzip && \
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/opt/fnm" && \
    ln -s /opt/fnm/fnm /usr/local/bin/fnm && \
    fnm install v20.17.0 && \
    fnm default v20.17.0 && \
    eval "$(fnm env --use-on-cd)" && \
    corepack enable && \
    corepack prepare pnpm@latest --activate

FROM base AS prod-deps

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile && \
    pnpm run build

FROM base

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist

ENV PORT=3000

EXPOSE $PORT

ENTRYPOINT ["pnpm", "run"]
CMD ["preview"]
