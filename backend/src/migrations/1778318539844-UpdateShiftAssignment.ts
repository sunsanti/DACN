import { MigrationInterface, QueryRunner } from "typeorm";

export class UpdateShiftAssignment1778318539844 implements MigrationInterface {
    name = 'UpdateShiftAssignment1778318539844'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "shiftAssignment" ("id" SERIAL NOT NULL, "type" character varying NOT NULL, "startTime" TIMESTAMP NOT NULL, "endTime" TIMESTAMP NOT NULL, "status" character varying NOT NULL, "doctorId" integer, "shiftId" integer, CONSTRAINT "PK_09a1692f57920180194e1ea491d" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "shift" DROP COLUMN "emergency"`);
        await queryRunner.query(`ALTER TABLE "shiftAssignment" ADD CONSTRAINT "FK_05c4344270ec8513fe22586212d" FOREIGN KEY ("doctorId") REFERENCES "doctor"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "shiftAssignment" ADD CONSTRAINT "FK_0a198e8a10da2915e0181fdbf1d" FOREIGN KEY ("shiftId") REFERENCES "shift"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "shiftAssignment" DROP CONSTRAINT "FK_0a198e8a10da2915e0181fdbf1d"`);
        await queryRunner.query(`ALTER TABLE "shiftAssignment" DROP CONSTRAINT "FK_05c4344270ec8513fe22586212d"`);
        await queryRunner.query(`ALTER TABLE "shift" ADD "emergency" integer NOT NULL`);
        await queryRunner.query(`DROP TABLE "shiftAssignment"`);
    }

}
