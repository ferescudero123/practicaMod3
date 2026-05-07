import psycopg2

#Conexión a la BD
def conectar():
    try:
        conexion = psycopg2.connect(
            host = "localhost",
            database = "escuela_db",
            user = "admin",
            password = "admin123",
            port="5432"
        )
        return conexion
    except Exception as e:
        print("Error al conectar: ", e)
        return None