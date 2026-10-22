import { MigrationInterface, QueryRunner } from "typeorm";

/**
 * BHYT card on patient, admin price list (disease), and the bill snapshot written
 * when a doctor completes an appointment (totals on appointment + one appointment_item per disease).
 */
export class AddInsuranceAndPricing1780500700000 implements MigrationInterface {
    name = "AddInsuranceAndPricing1780500700000";

    public async up(q: QueryRunner): Promise<void> {
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "insuranceNumber" character varying(15)`);
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "insuranceValidFrom" date`);
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "insuranceValidTo" date`);

        await q.query(`CREATE TABLE IF NOT EXISTS "disease" (
            "id" SERIAL PRIMARY KEY,
            "name" character varying(200) NOT NULL UNIQUE,
            "price" integer NOT NULL CHECK ("price" >= 0),
            "active" boolean NOT NULL DEFAULT true
        )`);

        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "examFee" integer`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "total" integer`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "insuranceRate" real`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "insuranceCovered" integer`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "payable" integer`);

        await q.query(`CREATE TABLE IF NOT EXISTS "appointment_item" (
            "id" SERIAL PRIMARY KEY,
            "appointmentId" integer NOT NULL REFERENCES "appointment"("id") ON DELETE CASCADE,
            "name" character varying(200) NOT NULL,
            "price" integer NOT NULL
        )`);
    }

    public async down(q: QueryRunner): Promise<void> {
        await q.query(`DROP TABLE IF EXISTS "appointment_item"`);
        for (const c of ["payable", "insuranceCovered", "insuranceRate", "total", "examFee"]) {
            await q.query(`ALTER TABLE "appointment" DROP COLUMN IF EXISTS "${c}"`);
        }
        await q.query(`DROP TABLE IF EXISTS "disease"`);
        for (const c of ["insuranceValidTo", "insuranceValidFrom", "insuranceNumber"]) {
            await q.query(`ALTER TABLE "patient" DROP COLUMN IF EXISTS "${c}"`);
        }
    }
}
