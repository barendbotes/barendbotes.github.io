FROM nginx:1.22.0-alpine
COPY _site/ /usr/share/nginx/html
EXPOSE 80

# EXPOSE 80

# CMD ["nginx", "-g", "daemon off;"]