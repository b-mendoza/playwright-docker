FROM ubuntu:noble AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

ARG fnm_install_dir="/opt/fnm"
ARG node_version="v20.17.0"

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl unzip && \
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${fnm_install_dir}" && \
    ln -s ${fnm_install_dir}/fnm /usr/bin && chmod +x /usr/bin/fnm && \
    fnm install ${node_version} && \
    fnm default ${node_version} --corepack-enabled && \
    node --version && \
    npm --version && \
    pnpm --version && \
    rm -rf /var/lib/apt/lists/*

COPY . /app

WORKDIR /app

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
