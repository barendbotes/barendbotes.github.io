FROM nginx:stable-alpine
COPY _site /usr/share/nginx/html


# EXPOSE 80

# CMD ["nginx", "-g", "daemon off;"]