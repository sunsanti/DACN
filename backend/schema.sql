-- =====================================================================
-- DACN — Database schema (PostgreSQL)
-- Database: dacn_db
-- Generated from TypeORM entities in backend/src/**/entities/*.entity.ts
--
-- Tables: patient, doctor, shift, appointment, "shiftAssignment"
-- Conventions follow what TypeORM generates for this project:
--   * PK            -> SERIAL
--   * string        -> character varying (no length)
--   * number (int)  -> integer
--   * Date          -> TIMESTAMP (without time zone)
--   * relation FK   -> <relation>Id integer, nullable, ON DELETE NO ACTION
-- Columns are NOT NULL unless the entity marks { nullable: true }.
-- =====================================================================

BEGIN;

-- Drop in reverse-dependency order so re-running is clean.
DROP TABLE IF EXISTS "shiftAssignment" CASCADE;
DROP TABLE IF EXISTS "appointment"     CASCADE;
DROP TABLE IF EXISTS "shift"           CASCADE;
DROP TABLE IF EXISTS "doctor"          CASCADE;
DROP TABLE IF EXISTS "patient"         CASCADE;

-- ---------------------------------------------------------------------
-- patient  (PatientEntity)
-- ---------------------------------------------------------------------
CREATE TABLE "patient" (
    "id"        SERIAL            NOT NULL,
    "name"      character varying NOT NULL,
    "gender"    character varying NOT NULL,
    "age"       integer           NOT NULL,
    "birthDate" TIMESTAMP         NOT NULL,
    "email"     character varying NOT NULL,
    "phone"     character varying NOT NULL,
    "address"   character varying NOT NULL,
    "createAt"  TIMESTAMP         NOT NULL,
    "avatar"    character varying NOT NULL,
    CONSTRAINT "PK_patient" PRIMARY KEY ("id")
);

-- ---------------------------------------------------------------------
-- doctor  (DoctorEntity)
-- ---------------------------------------------------------------------
CREATE TABLE "doctor" (
    "id"          SERIAL            NOT NULL,
    "name"        character varying NOT NULL,
    "age"         integer           NOT NULL,
    "dateOfBirth" TIMESTAMP         NOT NULL,
    "gender"      character varying NOT NULL,
    "phone"       character varying NOT NULL,
    "address"     character varying NOT NULL,
    "email"       character varying NOT NULL,
    CONSTRAINT "PK_doctor" PRIMARY KEY ("id")
);

-- ---------------------------------------------------------------------
-- shift  (ShiftEntity)
-- type: 'morning' | 'afternoon'  (stored as varchar)
-- ---------------------------------------------------------------------
CREATE TABLE "shift" (
    "id"        SERIAL            NOT NULL,
    "type"      character varying NOT NULL,
    "startTime" TIMESTAMP         NOT NULL,
    "endTime"   TIMESTAMP         NOT NULL,
    CONSTRAINT "PK_shift" PRIMARY KEY ("id")
);

-- ---------------------------------------------------------------------
-- appointment  (AppointmentEntity)
-- confirmCondition: 1 = pending (chua xac nhan), 0 = confirmed (da xac nhan)
-- ---------------------------------------------------------------------
CREATE TABLE "appointment" (
    "id"               SERIAL            NOT NULL,
    "apTime"           TIMESTAMP         NOT NULL,
    "confirmDate"      TIMESTAMP                  ,   -- nullable
    "address"          character varying NOT NULL,
    "note"             text                       ,   -- nullable
    "confirmCondition" integer           NOT NULL,
    "doctorName"       character varying NOT NULL,
    "patientId"        integer                    ,   -- FK -> patient(id)
    "doctorId"         integer                    ,   -- FK -> doctor(id)
    CONSTRAINT "PK_appointment" PRIMARY KEY ("id")
);

-- ---------------------------------------------------------------------
-- shiftAssignment  (ShiftAssignmentEntity)
-- Join entity carrying lifecycle state for a doctor working a shift.
-- status: 'ACTIVE' | 'CANCELED' | 'REPLACED'  (stored as varchar)
-- NOTE: `duration` is integer per TypeORM default, but the service stores
--       fractional hours (e.g. 12 - h + m/60). Consider double precision.
-- ---------------------------------------------------------------------
CREATE TABLE "shiftAssignment" (
    "id"        SERIAL            NOT NULL,
    "type"      character varying NOT NULL,
    "startTime" TIMESTAMP         NOT NULL,
    "endTime"   TIMESTAMP         NOT NULL,
    "status"    character varying NOT NULL,
    "duration"  integer           NOT NULL,
    "doctorId"  integer                    ,   -- FK -> doctor(id)
    "shiftId"   integer                    ,   -- FK -> shift(id)
    CONSTRAINT "PK_shiftAssignment" PRIMARY KEY ("id")
);

-- ---------------------------------------------------------------------
-- Foreign keys  (ON DELETE NO ACTION ON UPDATE NO ACTION — TypeORM default)
-- ---------------------------------------------------------------------
ALTER TABLE "appointment"
    ADD CONSTRAINT "FK_appointment_patient"
    FOREIGN KEY ("patientId") REFERENCES "patient" ("id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "appointment"
    ADD CONSTRAINT "FK_appointment_doctor"
    FOREIGN KEY ("doctorId") REFERENCES "doctor" ("id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "shiftAssignment"
    ADD CONSTRAINT "FK_shiftAssignment_doctor"
    FOREIGN KEY ("doctorId") REFERENCES "doctor" ("id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE "shiftAssignment"
    ADD CONSTRAINT "FK_shiftAssignment_shift"
    FOREIGN KEY ("shiftId") REFERENCES "shift" ("id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;

COMMIT;
