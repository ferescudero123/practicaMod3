# Usa la imagen oficial de PostgreSQL
FROM postgres:15
# Copia el script SQL al directorio de inicialización de PostgreSQL
COPY init.sql /docker-entrypoint-initdb.d/
COPY save_data.sql /docker-entrypoint-initdb.d/
# PostgreSQL ejecutará automáticamente los scripts en /docker-entrypoint-initdb.d/