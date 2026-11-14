
import pyodbc
from src.config import CONNECTION_STRING


def get_connection():
    try:
        connection = pyodbc.connect(CONNECTION_STRING)
        print("SQL Server connected successfully!")
        return connection

    except pyodbc.Error as error:
        print("Database connection failed!")
        print("Error:", error)
        raise


def test_connection():
    connection = get_connection()

    try:
        cursor = connection.cursor()
        cursor.execute("SELECT DB_NAME()")

        database_name = cursor.fetchone()[0]

        print("Connected Database:", database_name)

        cursor.close()

    finally:
        connection.close()
