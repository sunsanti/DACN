import { MigrationInterface, QueryRunner } from "typeorm";

/** Doctor profile photo (server path under /uploads/avatars, '' = none). */
export class AddDoctorAvatar1780500500000 implements MigrationInterface {
    name = "AddDoctorAvatar1780500500000";

    public async up(q: QueryRunner): Promise<void> {
        await q.query(`ALTER TABLE "doctor" ADD COLUMN IF NOT EXISTS "avatar" character varying NOT NULL DEFAULT ''`);
    }

    public async down(q: QueryRunner): Promise<void> {
        await q.query(`ALTER TABLE "doctor" DROP COLUMN IF EXISTS "avatar"`);
    }
}
