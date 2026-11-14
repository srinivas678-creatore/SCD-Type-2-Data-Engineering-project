
SERVER = r"DESKTOP-VVK35NS\SQLSERVERBI"
DATABASE = "scd_type2_db"
DRIVER = "ODBC Driver 18 for SQL Server"

CONNECTION_STRING = (
    f"DRIVER={{{DRIVER}}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
    
)
