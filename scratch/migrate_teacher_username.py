import sqlite3

conn = sqlite3.connect("backend/maatribhasha_backend.db")
cursor = conn.cursor()

try:
    cursor.execute("ALTER TABLE teachers ADD COLUMN username VARCHAR(100)")
    print("Added username column to teachers table.")
except sqlite3.OperationalError as e:
    print(f"Column already exists or error: {e}")

cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS ix_teachers_username ON teachers (username)")

# Update existing rows or insert seeded teacher
cursor.execute("UPDATE teachers SET username = 'jh_teacher_01' WHERE email = 'teacher.jharkhand@gov.in'")

# Ensure teacher@test.com exists
cursor.execute("SELECT id FROM teachers WHERE email = 'teacher@test.com'")
if not cursor.fetchone():
    cursor.execute("""
        INSERT INTO teachers (id, user_id, username, name, email, designation, preferred_language, is_active, created_at, updated_at)
        VALUES ('teacher-test-001', '00000000-0000-0000-0000-000000000001', 'teacher01', 'Smt. Anjali Kumari (Primary Teacher)', 'teacher@test.com', 'Primary Teacher', 'Hindi', 1, datetime('now'), datetime('now'))
    """)
    print("Inserted teacher@test.com with username teacher01.")
else:
    cursor.execute("UPDATE teachers SET username = 'teacher01' WHERE email = 'teacher@test.com'")

conn.commit()

cursor.execute("SELECT id, user_id, username, email, name FROM teachers")
rows = cursor.fetchall()
print("Teachers currently in DB:")
for r in rows:
    print(f"  - ID: {r[0]}, user_id: {r[1]}, username: {r[2]}, email: {r[3]}, name: {r[4]}")

conn.close()
