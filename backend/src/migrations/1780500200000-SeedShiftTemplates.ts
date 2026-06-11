import { MigrationInterface, QueryRunner } from "typeorm";

/** Seed 3 shift templates (morning/afternoon/evening) if the shift table is empty. */
export class SeedShiftTemplates1780500200000 implements MigrationInterface {
    name = "SeedShiftTemplates1780500200000";

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            INSERT INTO "shift" ("type", "startTime", "endTime")
            SELECT * FROM (VALUES
              ('morning'::varchar,   '2026-01-01 07:00:00'::timestamp, '2026-01-01 11:00:00'::timestamp),
              ('afternoon'::varchar, '2026-01-01 13:00:00'::timestamp, '2026-01-01 17:00:00'::timestamp),
              ('evening'::varchar,   '2026-01-01 18:00:00'::timestamp, '2026-01-01 21:00:00'::timestamp)
            ) AS v("type", "startTime", "endTime")
            WHERE NOT EXISTS (SELECT 1 FROM "shift")
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `DELETE FROM "shift" WHERE "type" IN ('morning','afternoon','evening')`,
        );
    }
}
