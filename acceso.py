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

#CREATE - Insertar alumno
def insertar_alumno(nombre, edad, correo):
    conexion = conectar()
    cursor = conexion.cursor()
    query = "INSERT INTO alumnos(nombre, edad, correo) VALUES (%s, %s, %s);"
    cursor.execute(query,(nombre, edad, correo))
    conexion.commit()
    cursor.close()
    conexion.close()
    print("Alumno insertado correctamente")

#READ - Consultar alumno
def consultar_alumno():
    print("Aquí haremos consultas")

#UPDATE - Actualizar alumno
def actualizar_alumno(id, nombre):
    print("Aquí haremos actualizaciones")

#DELETE - Eliminar alumno
def eliminar_alumno(id):
    print("Aquí eliminaremos")

#Menú principal
def menu():
    while True:
        print("\n--- Menú CRUD ---")
        print("1. Insertar alumno")
        print("2. Consultar alumno")
        print("3. Actualizar alumno")
        print("4. Eliminar alumno")
        print("5. Salir")

        opcion = input("Selecciona una opción: ")

        if opcion == "1":
            nombre = input("Nombre: ")
            edad = int(input("Edad: "))
            correo = input("Correo: ")
            insertar_alumno(nombre, edad, correo)
        elif opcion == "2":
            consultar_alumno()
        elif opcion == "3":
            id = int(input("ID del alumno: "))
            nombre = input("Nombre: ")
            actualizar_alumno(id, nombre)
        elif opcion == "4":
            id = int(input("ID del alumno: "))
            eliminar_alumno(id)
        elif opcion == "5":
            print("Saliendo de la aplicación...")
            break
        else:
            print("Opción no válida...")

if __name__ == "__main__":
    menu()    