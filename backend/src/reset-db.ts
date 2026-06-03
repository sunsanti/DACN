/**
 * One-off DEV utility: wipe all data and re-seed the admin account + 3 shift
 * templates (morning / afternoon / evening). Schema + migration history are kept.
 *
 *   cd backend && npx ts-node src/reset-db.ts
 *
 * WARNING: destructive — truncates every data table.
 */
import "reflect-metadata";
import * as bcrypt from "bcrypt";
import { AppDataSource } from "./data-source";

async function main() {
    await AppDataSource.initialize();
    const q = (sql: string, params?: any[]) => AppDataSource.query(sql, params);

    // 1) wipe all data (keep schema + the "migrations" table)
    await q(
        `TRUNCATE TABLE account, "medical_report", appointment, "shiftAssignment", shift, patient, doctor RESTART IDENTITY CASCADE`,
    );

    // 2) re-seed the admin account
    const hash = await bcrypt.hash("Admin@123", 10);
    await q(
        `INSERT INTO account (email, "passwordHash", role) VALUES ($1, $2, 'admin')`,
        ["admin@dacn.local", hash],
    );

    // 3) seed 3 shift templates (time-of-day; registerShift combines with a real date)
    await q(
        `INSERT INTO shift (type, "startTime", "endTime") VALUES
            ('morning',   $1, $2),
            ('afternoon', $3, $4),
            ('evening',   $5, $6)`,
        [
            "2026-01-01 07:00:00", "2026-01-01 11:00:00", // Sáng  (4h)
            "2026-01-01 13:00:00", "2026-01-01 17:00:00", // Chiều (4h)
            "2026-01-01 18:00:00", "2026-01-01 21:00:00", // Tối   (3h)
        ],
    );

    const shifts = await q(`SELECT id, type, "startTime", "endTime" FROM shift ORDER BY id`);
    console.log("✅ Database reset.");
    console.log("   Admin: admin@dacn.local / Admin@123");
    console.log("   Shift templates:", JSON.stringify(shifts));
    await AppDataSource.destroy();
}

main().catch((e) => {
    console.error("Reset failed:", e);
    process.exit(1);
});
