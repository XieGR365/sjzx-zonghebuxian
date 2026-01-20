ARG NODE_IMAGE=node:18-alpine
FROM ${NODE_IMAGE} as builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

ARG NGINX_IMAGE=nginx:alpine
FROM ${NGINX_IMAGE}

COPY --from=builder /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
