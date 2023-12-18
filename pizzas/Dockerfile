FROM node:18.19.0-bookworm-slim AS builder
RUN mkdir /home/node/app
COPY index.js /home/node/app
COPY package.json /home/node/app
COPY package-lock.json /home/node/app
RUN cd /home/node/app && npm ci --only=production

FROM node:18.19.0-bookworm-slim
COPY --from=builder /home/node/app /home/node/app
WORKDIR /home/node/app
USER node
EXPOSE 3000
CMD ["node", "index.js"]
