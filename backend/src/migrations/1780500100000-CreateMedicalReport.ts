import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateMedicalReport1780500100000 implements MigrationInterface {
    name = "CreateMedicalReport1780500100000";

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "medical_report" (
            "id" SERIAL NOT NULL,
            "appointmentId" integer,
            "pdf" bytea NOT NULL,
            "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
            CONSTRAINT "PK_medical_report" PRIMARY KEY ("id")
        )`);
        await queryRunner.query(`ALTER TABLE "medical_report"
            ADD CONSTRAINT "FK_report_appointment" FOREIGN KEY ("appointmentId")
            REFERENCES "appointment"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "medical_report" DROP CONSTRAINT "FK_report_appointment"`);
        await queryRunner.query(`DROP TABLE "medical_report"`);
    }
}
