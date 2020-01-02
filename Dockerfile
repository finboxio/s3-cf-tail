ARG NODE_VERSION=12.4

###
# @base
# Setup base image with default node/env/config
###
FROM mhart/alpine-node:$NODE_VERSION AS base

ARG ROOT_DIR=/usr/src
ARG NODE_ENV=dev

ENV ROOT_DIR=$ROOT_DIR
ENV NODE_ENV=$NODE_ENV
ENV PATH=$PATH:$ROOT_DIR/node_modules/.bin
ENV NODE_PATH=$ROOT_DIR/app

WORKDIR $ROOT_DIR

# Default command
ENTRYPOINT [ "./node_modules/.bin/npmx", "run" ]
CMD [ "tail" ]


###
# @base => @installed
# Build image with dev npm modules
###
FROM base AS installed

# Set up .npmrc
ARG NPM_MAX_SOCKETS=50
RUN echo "registry=https://registry.npmjs.org/" > /root/.npmrc && \
    echo "maxsockets=${NPM_MAX_SOCKETS}" >> /root/.npmrc && \
    echo "progress=false" >> /root/.npmrc

# Install app dependencies
ADD package.json package-lock.json .babelrc .npmrc ./
RUN apk add --no-cache git alpine-sdk python && \
    npm install && \
    apk del python alpine-sdk


###
# @installed => @dev
# Add source to installed modules for dev image
# (Source is added after install to avoid rebuilding unnecessarily)
###
FROM installed AS dev
COPY app $ROOT_DIR/app


###
# @dev => @build
# Build production app
###
FROM dev AS build
ENV NODE_ENV=production
RUN npm run build && \
    npm prune --production && \
    npm install --production


###
# @base => @production
# Create image with only built source and production dependencies
###
FROM base AS production
ENV NODE_ENV=production

COPY --from=build $ROOT_DIR/.npmrc $ROOT_DIR/.npmrc
COPY --from=build $ROOT_DIR/package.json $ROOT_DIR/package.json
COPY --from=build $ROOT_DIR/package-lock.json $ROOT_DIR/package-lock.json
COPY --from=build $ROOT_DIR/node_modules $ROOT_DIR/node_modules
COPY --from=build $ROOT_DIR/build $ROOT_DIR/app
