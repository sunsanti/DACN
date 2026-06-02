import { MigrationInterface, QueryRunner } from "typeorm";
import * as bcrypt from "bcrypt";

export class CreateAccount1780500000000 implements MigrationInterface {
    name = "CreateAccount1780500000000";

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "account" (
            "id" SERIAL NOT NULL,
            "email" character varying NOT NULL,
            "passwordHash" character varying NOT NULL,
            "role" character varying NOT NULL,
            "patientId" integer,
            "doctorId" integer,
            "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
            CONSTRAINT "UQ_account_email" UNIQUE ("email"),
            CONSTRAINT "REL_account_patient" UNIQUE ("patientId"),
            CONSTRAINT "REL_account_doctor" UNIQUE ("doctorId"),
            CONSTRAINT "PK_account" PRIMARY KEY ("id")
        )`);
        await queryRunner.query(`ALTER TABLE "account"
            ADD CONSTRAINT "FK_account_patient" FOREIGN KEY ("patientId")
            REFERENCES "patient"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "account"
            ADD CONSTRAINT "FK_account_doctor" FOREIGN KEY ("doctorId")
            REFERENCES "doctor"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);

        // Seed the first admin account. Change the password after first login.
        const hash = await bcrypt.hash("Admin@123", 10);
        await queryRunner.query(
            `INSERT INTO "account" ("email", "passwordHash", "role") VALUES ($1, $2, 'admin')`,
            ["admin@dacn.local", hash],
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "account" DROP CONSTRAINT "FK_account_doctor"`);
        await queryRunner.query(`ALTER TABLE "account" DROP CONSTRAINT "FK_account_patient"`);
        await queryRunner.query(`DROP TABLE "account"`);
    }
}
