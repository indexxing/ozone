FROM node:20.11-alpine3.18 as build

WORKDIR /usr/src/ozone
RUN corepack enable

# Install root deps and build
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn
COPY . .
RUN yarn build

# Replace root package with service package
RUN rm -rf node_modules .next/cache
RUN mv service/package.json package.json && mv service/yarn.lock yarn.lock
RUN yarn --production

# final stage
FROM node:20.11-alpine3.18

RUN apk add --update dumb-init
ENV TZ=Etc/UTC

WORKDIR /usr/src/ozone
COPY --from=build /usr/src/ozone /usr/src/ozone
COPY --from=build /usr/src/ozone/node_modules /usr/src/ozone/node_modules

RUN chown -R node:node .

ENTRYPOINT ["dumb-init", "--"]
EXPOSE 3000
ENV OZONE_PORT=3000
ENV NODE_ENV=production
USER node
CMD ["node", "./service"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/ozone
LABEL org.opencontainers.image.description="Ozone Moderation Service Web UI"
LABEL org.opencontainers.image.licenses=MIT
