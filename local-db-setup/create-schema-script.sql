-- 1. Drop the user if it already exists (this removes all objects owned by the user)
DROP USER STUDY_USER CASCADE;

-- 2. Recreate the user with a password
CREATE USER STUDY_USER IDENTIFIED BY Study1234;

-- 3. Allow the user to log in
GRANT CREATE SESSION TO STUDY_USER;

-- 4. Grant privileges needed for Flyway + app migrations
GRANT CREATE TABLE TO STUDY_USER;
GRANT CREATE SEQUENCE TO STUDY_USER;
GRANT CREATE VIEW TO STUDY_USER;
GRANT CREATE TRIGGER TO STUDY_USER;
GRANT CREATE PROCEDURE TO STUDY_USER;

-- Optional: classic roles (not strictly required in modern Oracle, but sometimes used)
GRANT CONNECT, RESOURCE TO STUDY_USER;

-- 5. Assign tablespace and unlimited quota
ALTER USER STUDY_USER DEFAULT TABLESPACE USERS;
ALTER USER STUDY_USER QUOTA UNLIMITED ON USERS;

-- (Optional) Verify grants
SELECT privilege FROM dba_sys_privs WHERE grantee = 'STUDY_USER';
