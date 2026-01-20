ARG NODE_IMAGE=node:18-alpine
FROM ${NODE_IMAGE}

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

RUN mkdir -p data uploads

RUN apk add --no-cache wget

EXPOSE 3001

CMD ["npm", "start"]
