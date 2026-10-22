import { MigrationInterface, QueryRunner } from "typeorm";

/**
 * CCCD on patient (BHYT is now looked up by CCCD in a read-only registry, replacing the
 * self-declared card), BHYT-covered flags on the price list / bill lines, payment state on
 * appointments, SePay webhook log and admin notifications.
 */
export class CccdBhytPayment1780500800000 implements MigrationInterface {
    name = "CccdBhytPayment1780500800000";

    public async up(q: QueryRunner): Promise<void> {
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "cccd" character varying(12) UNIQUE`);
        for (const c of ["insuranceNumber", "insuranceValidFrom", "insuranceValidTo"]) {
            await q.query(`ALTER TABLE "patient" DROP COLUMN IF EXISTS "${c}"`);
        }

        // Read-only national BHYT data (stand-in for BHXH). Seeded here; no API writes to it.
        await q.query(`CREATE TABLE IF NOT EXISTS "bhyt_registry" (
            "id" SERIAL PRIMARY KEY,
            "cccd" character varying(12) NOT NULL UNIQUE,
            "cardNumber" character varying(15) NOT NULL UNIQUE,
            "fullName" character varying NOT NULL,
            "birthDate" date NOT NULL,
            "validFrom" date NOT NULL,
            "validTo" date NOT NULL
        )`);
        await q.query(`INSERT INTO "bhyt_registry" ("cccd", "cardNumber", "fullName", "birthDate", "validFrom", "validTo") VALUES
            ('079203000111', 'DN4790000000001', 'Trần Thu Hà',     '2002-06-15', '2026-01-01', '2030-12-31'),
            ('079096000222', 'HC3790000000002', 'Nguyễn Văn Bình', '1996-03-10', '2026-01-01', '2030-12-31'),
            ('048085000333', 'TE1480000000003', 'Lê Minh Châu',    '1985-11-20', '2026-01-01', '2030-12-31'),
            ('001090000444', 'GD4010000000004', 'Phạm Thị Dung',   '1990-01-05', '2024-01-01', '2025-12-31'),
            ('079099000555', 'DN4790000000005', 'Hoàng Gia Huy',   '1999-09-09', '2026-01-01', '2030-12-31')
            ON CONFLICT DO NOTHING`);

        await q.query(`ALTER TABLE "disease" ADD COLUMN IF NOT EXISTS "bhytCovered" boolean NOT NULL DEFAULT true`);
        await q.query(`ALTER TABLE "appointment_item" ADD COLUMN IF NOT EXISTS "bhytCovered" boolean NOT NULL DEFAULT true`);

        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "examFeeCovered" boolean`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "insuranceCardNumber" character varying(15)`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "paymentMethod" character varying`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "paymentStatus" character varying NOT NULL DEFAULT 'unpaid'`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "paidAt" TIMESTAMP`);
        await q.query(`ALTER TABLE "appointment" ADD COLUMN IF NOT EXISTS "paidBy" integer`);

        await q.query(`CREATE TABLE IF NOT EXISTS "payment_transaction" (
            "id" SERIAL PRIMARY KEY,
            "sepayId" bigint NOT NULL UNIQUE,
            "appointmentId" integer REFERENCES "appointment"("id") ON DELETE SET NULL,
            "amount" integer NOT NULL,
            "content" text NOT NULL,
            "matched" boolean NOT NULL,
            "createdAt" TIMESTAMP NOT NULL DEFAULT now()
        )`);
        await q.query(`CREATE TABLE IF NOT EXISTS "notification" (
            "id" SERIAL PRIMARY KEY,
            "title" character varying NOT NULL,
            "body" text NOT NULL,
            "appointmentId" integer,
            "readAt" TIMESTAMP,
            "createdAt" TIMESTAMP NOT NULL DEFAULT now()
        )`);
    }

    public async down(q: QueryRunner): Promise<void> {
        await q.query(`DROP TABLE IF EXISTS "notification"`);
        await q.query(`DROP TABLE IF EXISTS "payment_transaction"`);
        for (const c of ["paidBy", "paidAt", "paymentStatus", "paymentMethod", "insuranceCardNumber", "examFeeCovered"]) {
            await q.query(`ALTER TABLE "appointment" DROP COLUMN IF EXISTS "${c}"`);
        }
        await q.query(`ALTER TABLE "appointment_item" DROP COLUMN IF EXISTS "bhytCovered"`);
        await q.query(`ALTER TABLE "disease" DROP COLUMN IF EXISTS "bhytCovered"`);
        await q.query(`DROP TABLE IF EXISTS "bhyt_registry"`);
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "insuranceNumber" character varying(15)`);
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "insuranceValidFrom" date`);
        await q.query(`ALTER TABLE "patient" ADD COLUMN IF NOT EXISTS "insuranceValidTo" date`);
        await q.query(`ALTER TABLE "patient" DROP COLUMN IF EXISTS "cccd"`);
    }
}
