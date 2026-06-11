import { MigrationInterface, QueryRunner } from "typeorm";

/** duration stores fractional hours -> change INTEGER to double precision. */
export class AlterShiftDurationDouble1780500300000 implements MigrationInterface {
    name = "AlterShiftDurationDouble1780500300000";

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "shiftAssignment" ALTER COLUMN "duration" TYPE double precision`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE "shiftAssignment" ALTER COLUMN "duration" TYPE integer USING ROUND("duration")`,
        );
    }
}
