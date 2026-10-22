import { MigrationInterface, QueryRunner } from "typeorm";

/** Health / hospital news links shown in the patient home carousel. */
export class CreateNews1780500600000 implements MigrationInterface {
    name = "CreateNews1780500600000";

    public async up(q: QueryRunner): Promise<void> {
        await q.query(`CREATE TABLE IF NOT EXISTS "news" (
            "id" SERIAL PRIMARY KEY,
            "title" character varying(200) NOT NULL,
            "url" character varying(2000) NOT NULL,
            "imagePath" character varying NOT NULL,
            "createdAt" TIMESTAMP NOT NULL DEFAULT now()
        )`);
    }

    public async down(q: QueryRunner): Promise<void> {
        await q.query(`DROP TABLE IF EXISTS "news"`);
    }
}
