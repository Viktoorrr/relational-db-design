-- =====================================================================
-- Assignment: Bug Tracker
-- Authors:    Ľubomír Gálik, Viktor Čaloud
-- =====================================================================

DROP TABLE User_Programming_Language CASCADE CONSTRAINTS;
DROP TABLE Module_Bug CASCADE CONSTRAINTS;
DROP TABLE Ticket_Bug CASCADE CONSTRAINTS;
DROP TABLE "User" CASCADE CONSTRAINTS;
DROP TABLE Programming_Language CASCADE CONSTRAINTS;
DROP TABLE Programmer CASCADE CONSTRAINTS;
DROP TABLE Module CASCADE CONSTRAINTS;
DROP TABLE Ticket CASCADE CONSTRAINTS;
DROP TABLE Patch CASCADE CONSTRAINTS;
DROP TABLE Bug CASCADE CONSTRAINTS;

-- Drop sequences
DROP SEQUENCE seq_user;
DROP SEQUENCE seq_language;

DROP SEQUENCE seq_module;
DROP SEQUENCE seq_patch;
DROP SEQUENCE seq_bug;
DROP SEQUENCE seq_ticket;

-- Drop triggers
DROP TRIGGER trg_user_id;
DROP TRIGGER trg_language_id;

DROP TRIGGER trg_module_id;
DROP TRIGGER trg_patch_id;
DROP TRIGGER trg_bug_id;
DROP TRIGGER trg_ticket_id;


-- Table definitions
-- [User] 0..N - knows -> 0..N [Programming_Language]
CREATE TABLE "User" (
    id_user INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    reward_balance NUMBER(10,2) NOT NULL,
    bank_account VARCHAR2(50) NOT NULL
                      CHECK (REGEXP_LIKE(
                              bank_account, '^\d+(-\d+)?/\d{4}$'))
);

CREATE TABLE Programming_Language (
    id_language INT PRIMARY KEY NOT NULL,
    name VARCHAR2(50) NOT NULL
);

CREATE TABLE User_Programming_Language (
    id_user INT NOT NULL,
    id_language INT NOT NULL,
    CONSTRAINT pk_user_language PRIMARY KEY (id_user, id_language),
    CONSTRAINT fk_userlang_user FOREIGN KEY (id_user) REFERENCES "User"(id_user) ON DELETE CASCADE,
    CONSTRAINT fk_userlang_language FOREIGN KEY (id_language) REFERENCES Programming_Language(id_language) ON DELETE CASCADE
);

----
-- [User] <= [Programmer] -- Generalisation/specialisation
-- Implementation of the generalisation/specialisation relationship (User => Programmer)
-- Chosen approach: separate table for the supertype + separate table for the subtype sharing the supertype's PK.
-- The User table holds the shared attributes of the supertype.
-- The Programmer table represents the subtype; its PK is also a FK referencing User,
-- which guarantees that every Programmer is also a User.
---- 
CREATE TABLE Programmer (
    id_programmer INT PRIMARY KEY NOT NULL,
    CONSTRAINT fk_prog_user FOREIGN KEY (id_programmer) REFERENCES "User"(id_user) ON DELETE CASCADE
);

CREATE TABLE Module(
    id_module INT PRIMARY KEY NOT NULL,
    id_language INT NOT NULL,
    id_responsible_programmer INT NOT NULL,
    name VARCHAR2(100) NOT NULL,
    CONSTRAINT fk_module_lang FOREIGN KEY (id_language) REFERENCES Programming_Language(id_language) ON DELETE CASCADE,
    CONSTRAINT fk_module_prog FOREIGN KEY (id_responsible_programmer) REFERENCES Programmer(id_programmer) ON DELETE CASCADE
);

-- [Patch] - A user submits a patch; a programmer approves it
CREATE TABLE Patch(
    id_patch INT PRIMARY KEY NOT NULL,
    id_approver INT NOT NULL, -- approves
    id_submitter INT NOT NULL, -- submits
    created_date DATE NOT NULL,
    deployed_date DATE NULL,
    status VARCHAR2(100) NOT NULL,
    description VARCHAR2(255) NOT NULL,
    CONSTRAINT fk_patch_approver FOREIGN KEY (id_approver) REFERENCES Programmer(id_programmer) ON DELETE CASCADE,
    CONSTRAINT fk_patch_submitter FOREIGN KEY (id_submitter) REFERENCES "User"(id_user) ON DELETE CASCADE
);

-- [Bug] - A patch fixes a bug
CREATE TABLE Bug(
    id_bug INT PRIMARY KEY NOT NULL,
    id_patch INT DEFAULT NULL, -- fixes
    --id_programmer INT DEFAULT NULL,
    priority INT NOT NULL,
    risk_level VARCHAR2(50) NULL,
    description VARCHAR2(255) NOT NULL,
    vulnerability NUMBER(1) NOT NULL CHECK (vulnerability IN (0,1)),
    CONSTRAINT fk_bug_patch FOREIGN KEY (id_patch) REFERENCES Patch(id_patch) ON DELETE SET NULL
);

-- [Ticket] - A user creates a ticket; a programmer resolves it
CREATE TABLE Ticket(
    id_ticket INT PRIMARY KEY NOT NULL,
    id_creator INT NOT NULL, -- creates
    id_solver INT DEFAULT NULL, -- solves
    created_date DATE NOT NULL,
    status VARCHAR2(50) NOT NULL,
    description VARCHAR2(255) NOT NULL,
    CONSTRAINT fk_ticket_creator FOREIGN KEY (id_creator) REFERENCES "User"(id_user) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_solver FOREIGN KEY (id_solver) REFERENCES Programmer(id_programmer) ON DELETE CASCADE
);  

CREATE TABLE Module_Bug (
    id_module INT NOT NULL,
    id_bug INT NOT NULL,
    CONSTRAINT pk_module_bug PRIMARY KEY (id_module, id_bug),
    CONSTRAINT fk_modbug_module FOREIGN KEY (id_module) REFERENCES Module(id_module) ON DELETE CASCADE,
    CONSTRAINT fk_modbug_bug FOREIGN KEY (id_bug) REFERENCES Bug(id_bug) ON DELETE CASCADE
);


CREATE TABLE Ticket_Bug (
    id_ticket INT NOT NULL,
    id_bug INT NOT NULL,
    CONSTRAINT pk_ticket_bug PRIMARY KEY (id_ticket, id_bug),
    CONSTRAINT fk_ticketbug_ticket FOREIGN KEY (id_ticket) REFERENCES Ticket(id_ticket) ON DELETE CASCADE,
    CONSTRAINT fk_ticketbug_bug FOREIGN KEY (id_bug) REFERENCES Bug(id_bug) ON DELETE CASCADE
);


-- Create sequences for automatic primary key generation
CREATE SEQUENCE seq_user START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_language START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_module START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_patch START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_bug START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ticket START WITH 1 INCREMENT BY 1;


-- Create triggers for automatic primary key population
CREATE TRIGGER trg_user_id
BEFORE INSERT ON "User"
FOR EACH ROW
BEGIN
    IF :NEW.id_user IS NULL THEN
        SELECT seq_user.NEXTVAL INTO :NEW.id_user FROM DUAL;
    END IF;
END;
/

CREATE TRIGGER trg_language_id
BEFORE INSERT ON Programming_Language
FOR EACH ROW
BEGIN
    IF :NEW.id_language IS NULL THEN
        SELECT seq_language.NEXTVAL INTO :NEW.id_language FROM DUAL;
    END IF;
END;
/



CREATE TRIGGER trg_module_id
BEFORE INSERT ON Module
FOR EACH ROW
BEGIN
    IF :NEW.id_module IS NULL THEN
        SELECT seq_module.NEXTVAL INTO :NEW.id_module FROM DUAL;
    END IF;
END;
/

CREATE TRIGGER trg_patch_id
BEFORE INSERT ON Patch
FOR EACH ROW
BEGIN
    IF :NEW.id_patch IS NULL THEN
        SELECT seq_patch.NEXTVAL INTO :NEW.id_patch FROM DUAL;
    END IF;
END;
/

CREATE TRIGGER trg_bug_id
BEFORE INSERT ON Bug
FOR EACH ROW
BEGIN
    IF :NEW.id_bug IS NULL THEN
        SELECT seq_bug.NEXTVAL INTO :NEW.id_bug FROM DUAL;
    END IF;
END;
/

CREATE TRIGGER trg_ticket_id
BEFORE INSERT ON Ticket
FOR EACH ROW
BEGIN
    IF :NEW.id_ticket IS NULL THEN
        SELECT seq_ticket.NEXTVAL INTO :NEW.id_ticket FROM DUAL;
    END IF;
END;
/


-- Insert sample data

-- Programming_Language (will receive IDs: 1, 2, 3)
INSERT INTO Programming_Language (id_language, name) VALUES (NULL, 'SQL');
INSERT INTO Programming_Language (id_language, name) VALUES (NULL, 'Python');
INSERT INTO Programming_Language (id_language, name) VALUES (NULL, 'C++');

-- User (will receive IDs: 1, 2, 3)
INSERT INTO "User" (id_user, first_name, last_name, age, reward_balance, bank_account) 
VALUES (NULL, 'Ján', 'Novák', 25, 150.50, '123456/0800');
INSERT INTO "User" (id_user, first_name, last_name, age, reward_balance, bank_account) 
VALUES (NULL, 'Eva', 'Bystrá', 32, 0.00, '11-987654321/0100');
INSERT INTO "User" (id_user, first_name, last_name, age, reward_balance, bank_account) 
VALUES (NULL, 'Peter', 'Tester', 21, 50.00, '555444/0900');

-- User_Programming_Language (references User 1, 2 and Language 1, 2)
INSERT INTO User_Programming_Language (id_user, id_language) VALUES (1, 1);
INSERT INTO User_Programming_Language (id_user, id_language) VALUES (2, 1);
INSERT INTO User_Programming_Language (id_user, id_language) VALUES (2, 2);

-- Programmer (ID 2, so that User Eva Bystrá becomes a programmer)
-- Inserting 2 directly; the trigger skips it (IF :NEW.id_programmer IS NULL)
INSERT INTO Programmer (id_programmer) VALUES (2);

-- Module (will receive IDs: 1, 2)
INSERT INTO Module (id_module, name, id_responsible_programmer, id_language) 
VALUES (NULL, 'Core Engine', 2, 2);
INSERT INTO Module (id_module, name, id_responsible_programmer, id_language) 
VALUES (NULL, 'Database Layer', 2, 1);

-- Ticket (will receive IDs: 1, 2)
INSERT INTO Ticket (id_ticket, id_creator, id_solver, created_date, status, description) 
VALUES (NULL, 1, 2, TO_DATE('2026-03-01', 'YYYY-MM-DD'), 'In progress', 'Application crashes on login.');
INSERT INTO Ticket (id_ticket, id_creator, id_solver, created_date, status, description) 
VALUES (NULL, 3, NULL, TO_DATE('2026-03-15', 'YYYY-MM-DD'), 'New', 'Slow data loading.');

-- Patch (will receive ID: 1)
INSERT INTO Patch (id_patch, id_submitter, id_approver, created_date, deployed_date, status, description) 
VALUES (NULL, 3, 2, TO_DATE('2026-03-18', 'YYYY-MM-DD'), TO_DATE('2026-03-20', 'YYYY-MM-DD'), 'Deployed', 'Input security fix.');

-- Bug (will receive IDs: 1, 2)
-- First bug is fixed by Patch with ID 1
INSERT INTO Bug (id_bug, id_patch, priority, risk_level, description, vulnerability) 
VALUES (NULL, 1, 1, 'High', 'SQL Injection in login form', 1);
INSERT INTO Bug (id_bug, id_patch, priority, risk_level, description, vulnerability) 
VALUES (NULL, NULL, 2, NULL, 'Error in data format parsing', 0);

-- Junction tables: referencing real generated IDs (1, 2)
-- (not the original hardcoded values 101, 500, 501, etc.!)
INSERT INTO Ticket_Bug (id_ticket, id_bug) VALUES (1, 1);
INSERT INTO Ticket_Bug (id_ticket, id_bug) VALUES (1, 2);

INSERT INTO Module_Bug (id_module, id_bug) VALUES (2, 1);
INSERT INTO Module_Bug (id_module, id_bug) VALUES (1, 2);

COMMIT;

--------------------------------------------------------------------------------
-- PROJECT PART 3
--------------------------------------------------------------------------------

-- 1. Query joining 2 tables
-- What data it retrieves: Finds the full name of the user (programmer) responsible for a given module.
-- Application use: Displays module detail with its assigned owner, so others know who to contact for technical issues.
SELECT M.name AS Module_Name, U.first_name, U.last_name
FROM Module M
JOIN "User" U ON M.id_responsible_programmer = U.id_user
WHERE M.name = 'Core Engine';


-- 2. Query joining 2 tables
-- What data it retrieves: Returns the current status of a specific ticket and the last name of its creator.
-- Application use: Quick ticket detail view for support staff or a user dashboard tracking the status of reported issues.
SELECT T.id_ticket, T.status, U.last_name AS Creator_Last_Name
FROM Ticket T
JOIN "User" U ON T.id_creator = U.id_user
WHERE T.id_ticket = 1;


-- 3. Query joining 3 tables
-- What data it retrieves: Finds the module(s) containing a specific bug (here bug ID 1), along with its description.
-- Application use: Impact analysis for a specific bug. Helps developers immediately locate which parts of the codebase (modules) need to be changed for a fix.
SELECT B.description, M.name AS Module_Name
FROM Bug B
JOIN Module_Bug MB ON B.id_bug = MB.id_bug
JOIN Module M ON MB.id_module = M.id_module
WHERE B.id_bug = 1;


-- 4. Query with GROUP BY and aggregate function
-- What data it retrieves: Counts the programming languages assigned to each user and lists only those who know more than one language.
-- Application use: Developer skill analysis. Useful for finding versatile candidates for complex multi-language modules or for distributing rewards.
SELECT U.first_name, U.last_name, U.bank_account,
  COUNT(UPL.id_language) AS Num_Languages
FROM "User" U
JOIN User_Programming_Language UPL ON UPL.id_user = U.id_user
GROUP BY U.first_name, U.last_name, U.bank_account
HAVING COUNT(UPL.id_language) > 1
ORDER BY U.last_name, U.first_name;


-- 5. Query with GROUP BY and aggregate function
-- What data it retrieves: Counts how many distinct bugs each deployed patch fixes.
-- Application use: Patch effectiveness statistics. Shows managers which patches were the most impactful and resolved the most reported issues at once.
SELECT P.description AS Patch_Info, COUNT(B.id_bug) AS Solved_Bugs_Count
FROM Patch P
JOIN Bug B ON P.id_patch = B.id_patch
GROUP BY P.description;


-- 6. Query with EXISTS predicate
-- What data it retrieves: Lists all users who have successfully submitted at least one patch to the system.
-- Application use: Filter active contributors, e.g. for sending out rewards, bonuses, or acknowledgements.
SELECT U.first_name, U.last_name, U.bank_account
FROM "User" U
WHERE EXISTS (
    SELECT 1 FROM Patch P WHERE P.id_submitter = U.id_user
)
ORDER BY U.last_name, U.first_name;


-- 7. Query with IN and nested SELECT
-- What data it retrieves: Retrieves the names of all modules that currently have at least one bug reported against them.
-- Application use: Overview of problematic system areas. Helps project management identify the most error-prone modules requiring the most attention.
SELECT M.name AS Module_Name
FROM Module M
WHERE M.id_module IN (
  SELECT DISTINCT MB.id_module
  FROM Module_Bug MB
)
ORDER BY M.name;

---------------------------------------------------------
-- PROJECT PART 4
---------------------------------------------------------

-- Trigger that ensures a patch cannot be deployed before its creation date
CREATE OR REPLACE TRIGGER trg_validate_patchdate
BEFORE INSERT OR UPDATE ON Patch
FOR EACH ROW
BEGIN
    IF :NEW.deployed_date IS NOT NULL AND :NEW.deployed_date < :NEW.created_date THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error - Deployment date cannot be earlier than creation date');
    END IF;
END;
/

--- DEMO ---
-- This trigger should raise an error:
-- UPDATE Patch SET deployed_date = TO_DATE('2026-03-01', 'YYYY-MM-DD') WHERE id_patch = 1;

-- Trigger that automatically rewards a user when their patch is deployed
CREATE OR REPLACE TRIGGER trg_automatic_reward
AFTER UPDATE OF status ON Patch
FOR EACH ROW
WHEN (NEW.status = 'Deployed' AND OLD.status != 'Deployed')
BEGIN
    UPDATE "User"
    SET reward_balance = reward_balance + 100
    WHERE id_user = :NEW.id_submitter;
END;
/

--- DEMO ---
-- UPDATE Patch SET status = 'Deployed' WHERE id_patch = 1;
-- SELECT reward_balance FROM "user" WHERE id_user = 3


-- MODULE REPORT PROCEDURE
CREATE OR REPLACE PROCEDURE proc_programmer_report(
    p_programmer_id IN "User".id_user%TYPE
) IS 
    CURSOR cur_modules IS
        SELECT M.name AS Module_Name, COUNT(mb.id_bug) AS Bug_Count
        FROM Module M
        LEFT JOIN Module_Bug MB ON M.id_module = MB.id_module
        WHERE M.id_responsible_programmer = p_programmer_id
        GROUP BY M.name;

    v_mod_name Module.name%TYPE;
    v_bug_count NUMBER;
BEGIN
    OPEN cur_modules;
    LOOP
        FETCH cur_modules INTO v_mod_name, v_bug_count;
        EXIT WHEN cur_modules%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Module: ' || v_mod_name || ' - Bugs: ' || v_bug_count);
    END LOOP;
    CLOSE cur_modules;
END;
/
-- CALL proc_programmer_report(2); -- Call for programmer with ID 2 (Eva Bystrá)


CREATE OR REPLACE PROCEDURE proc_assign_patch_to_bug(p_bug_id IN INT, p_patch_id IN INT)
IS
    v_bug Bug%ROWTYPE;
    v_patch_exists INT;
BEGIN
    -- Check that the bug exists
    SELECT * INTO v_bug FROM Bug WHERE id_bug = p_bug_id;
    
    -- Check that the patch exists
    SELECT COUNT(*) INTO v_patch_exists FROM Patch WHERE id_patch = p_patch_id;
    
    IF v_patch_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'No patch found with this ID.');
    END IF;

    UPDATE Bug SET id_patch = p_patch_id WHERE id_bug = p_bug_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Patch ' || p_patch_id || ' successfully assigned to bug ' || p_bug_id);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Bug with ID ' || p_bug_id || ' was not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
        ROLLBACK;
END;
/
-- Usage: EXEC proc_assign_patch_to_bug(2, 1);

EXPLAIN PLAN FOR
SELECT m.name, COUNT(b.id_bug)
FROM Module m
JOIN Module_Bug mb ON m.id_module = mb.id_module
JOIN Bug b ON mb.id_bug = b.id_bug
WHERE b.priority = 1
GROUP BY m.name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX idx_bug_priority ON Bug(priority);

EXPLAIN PLAN FOR
SELECT m.name, COUNT(b.id_bug)
FROM Module m
JOIN Module_Bug mb ON m.id_module = mb.id_module
JOIN Bug b ON mb.id_bug = b.id_bug
WHERE b.priority = 1
GROUP BY m.name;



SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--- GRANT PRIVILEGES TO SECOND TEAM MEMBER ---

GRANT ALL ON Bug TO xlogin00;
GRANT ALL ON Patch TO xlogin00;
GRANT ALL ON "User" TO xlogin00;
GRANT SELECT ON Module TO xlogin00;
GRANT SELECT ON Programming_Language TO xlogin00;
GRANT SELECT ON Module_Bug TO xlogin00;
GRANT SELECT ON Programmer TO xlogin00;
GRANT SELECT ON User_Programming_Language TO xlogin00;
GRANT SELECT ON Ticket TO xlogin00;
GRANT SELECT ON Ticket_Bug TO xlogin00;
GRANT EXECUTE ON proc_programmer_report TO xlogin00;
GRANT EXECUTE ON proc_assign_patch_to_bug TO xlogin00;

WITH UserActivity AS (
    SELECT 
        u.id_user,
        u.first_name || ' ' || u.last_name as full_name,
        (SELECT COUNT(*) FROM Patch p WHERE p.id_submitter = u.id_user) as patches_count,
        (SELECT COUNT(*) FROM Ticket t WHERE t.id_creator = u.id_user) as tickets_count
    FROM "User" u
)
SELECT 
    full_name,
    patches_count,
    tickets_count,
    CASE 
        WHEN patches_count > 5 THEN 'Power Contributor'
        WHEN patches_count BETWEEN 1 AND 5 THEN 'Active User'
        WHEN tickets_count > 0 THEN 'Reporter'
        ELSE 'Passive Observer'
    END as user_rank
FROM UserActivity
ORDER BY patches_count DESC;

-- NOTE: This query calculates contribution statistics for each user
-- and assigns them a textual rank based on the number of patches submitted and tickets created.

--- MATERIALIZED VIEW xlogin00: module and bug report
CREATE MATERIALIZED VIEW xlogin00.mv_module_bug_report AS
SELECT 
    m.id_module,
    m.name AS module_name,
    u.first_name || ' ' || u.last_name AS responsible_programmer,
    pl.name AS programming_language,
    COUNT(DISTINCT mb.id_bug) AS total_bugs,
    COUNT(DISTINCT CASE WHEN b.priority = 1 THEN b.id_bug END) AS critical_bugs,
    COUNT(DISTINCT CASE WHEN b.vulnerability = 1 THEN b.id_bug END) AS vulnerable_bugs,
    TRUNC(SYSDATE) AS last_refresh_date
FROM Module m
JOIN "User" u ON m.id_responsible_programmer = u.id_user
JOIN Programming_Language pl ON m.id_language = pl.id_language
LEFT JOIN Module_Bug mb ON m.id_module = mb.id_module
LEFT JOIN Bug b ON mb.id_bug = b.id_bug
GROUP BY m.id_module, m.name, u.first_name, u.last_name, pl.name;


--- DEMO: Initial read of the materialised view
SELECT * FROM xlogin00.mv_module_bug_report
ORDER BY total_bugs DESC;


--- DEMO: Manual refresh of the materialised view
BEGIN
    DBMS_MVIEW.REFRESH('xlogin00.mv_module_bug_report', method => 'C');
    DBMS_OUTPUT.PUT_LINE('Materialised view refreshed successfully.');
END;
/


--- DEMO: Read the materialised view after refresh
SELECT module_name, total_bugs, critical_bugs, vulnerable_bugs, last_refresh_date
FROM xlogin00.mv_module_bug_report
WHERE total_bugs > 0
ORDER BY critical_bugs DESC, vulnerable_bugs DESC;