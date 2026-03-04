"""Utility script to drop and recreate the qu_community database."""
import psycopg2

conn = psycopg2.connect(
    dbname='postgres', user='postgres', password='54321',
    host='localhost', port='5432'
)
conn.autocommit = True
cur = conn.cursor()

# Kill existing connections
cur.execute(
    "SELECT pg_terminate_backend(pid) "
    "FROM pg_stat_activity "
    "WHERE datname = 'qu_community' AND pid != pg_backend_pid()"
)

cur.execute("DROP DATABASE IF EXISTS qu_community")
cur.execute("CREATE DATABASE qu_community")
print("Database qu_community recreated successfully!")

cur.close()
conn.close()
