import { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Post-demo review changes: separate doctor/patient notes, cancel-with-reason,
 * and a one-time reschedule flag on appointments.
 */
export class AppointmentReviewFields1780500400000 implements MigrationInterface {
    name = "AppointmentReviewFields1780500400000";

    public async up(q: QueryRunner): Promise<void> {
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "doctorNote" text`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "cancelReason" text`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "canceledBy" character varying`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "rescheduled" boolean NOT NULL DEFAULT false`);
    }

    public async down(q: QueryRunner): Promise<void> {
        await q.query(`ALTER TABLE "appointment" DROP COLUMN IF EXISTS "rescheduled"`);
        await q.query(`ALTER TABLE "appointment" DROP COLUMN IF EXISTS "canceledBy"`);
        await q.query(`ALTER TABLE "appointment" DROP COLUMN IF EXISTS "cancelReason"`);
        await q.query(`ALTER TABLE "appointment" DROP COLUMN IF EXISTS "doctorNote"`);
    }
}
