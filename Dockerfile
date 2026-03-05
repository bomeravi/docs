FROM nginx:1.27-alpine

WORKDIR /usr/share/nginx/html

RUN rm -rf ./*
COPY --chown=nginx:nginx . .

# Use non-root user for security
USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
