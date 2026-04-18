import psycopg2

DB_NAME = 'cost'
DB_USER = 'postgres'
DB_PASSWORD = 'dbcost1'
DB_HOST = 'localhost'
DB_PORT = 5432

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?client_encoding=utf8"

def get_connection():
    return psycopg2.connect(DATABASE_URL)