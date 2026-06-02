import { Test, TestingModule } from "@nestjs/testing";
import { INestApplication, ValidationPipe } from "@nestjs/common";
import request from "supertest";
import { AppModule } from "./../src/app.module";

/**
 * E2E smoke test for the patient vertical slice (F01 + F02).
 * Boots the real AppModule against the dev DB. Uses a random email per run
 * so it can run repeatedly without colliding with existing data.
 * The /ai/report path is intentionally NOT covered here — it needs the Python
 * AI service (:8000) running; verify that manually / from the app.
 */
describe("Patient flow (e2e)", () => {
    let app: INestApplication;
    let token: string;
    let doctorId: number;
    const email = `e2e_${Date.now()}@dacn.local`;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();
        app = moduleFixture.createNestApplication();
        app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
        await app.init();
    });

    afterAll(async () => {
        await app.close();
    });

    it("register → returns a patient token", async () => {
        const res = await request(app.getHttpServer())
            .post("/auth/register")
            .send({
                email,
                password: "Test@123",
                name: "E2E Patient",
                gender: "male",
                age: 22,
                birthDate: "2003-01-01",
                phone: "0900000001",
                address: "abc",
            })
            .expect(201);
        expect(res.body.role).toBe("patient");
        expect(res.body.accessToken).toBeDefined();
        expect(res.body.patientId).toBeDefined();
        token = res.body.accessToken;
    });

    it("register duplicate email → 409", () =>
        request(app.getHttpServer())
            .post("/auth/register")
            .send({
                email,
                password: "Test@123",
                name: "Dup",
                gender: "male",
                age: 22,
                birthDate: "2003-01-01",
                phone: "0900000001",
                address: "abc",
            })
            .expect(409));

    it("login wrong password → 401", () =>
        request(app.getHttpServer())
            .post("/auth/login")
            .send({ email, password: "wrong-pass" })
            .expect(401));

    it("list-appointment without token → 401", () =>
        request(app.getHttpServer()).get("/patient/list-appointment").expect(401));

    it("create a doctor (any authenticated user) to book against", async () => {
        const res = await request(app.getHttpServer())
            .post("/doctor/create-doctor")
            .set("Authorization", `Bearer ${token}`)
            .expect(201);
        doctorId = res.body.id;
        expect(doctorId).toBeDefined();
    });

    it("create-appointment persists DTO values with confirmCondition=1", async () => {
        const res = await request(app.getHttpServer())
            .post("/patient/create-appointment")
            .set("Authorization", `Bearer ${token}`)
            .send({
                apTime: "2026-07-01T09:00:00.000Z",
                address: "Phong kham A",
                doctorId,
                note: "dau dau",
            })
            .expect(201);
        expect(res.body.address).toBe("Phong kham A");
        expect(res.body.note).toBe("dau dau");
        expect(res.body.confirmCondition).toBe(1);
        expect(res.body.doctor.id).toBe(doctorId);
    });

    it("list-appointment returns only the logged-in patient's appointments", async () => {
        const res = await request(app.getHttpServer())
            .get("/patient/list-appointment")
            .set("Authorization", `Bearer ${token}`)
            .expect(200);
        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThan(0);
        expect(res.body.every((a: any) => a.address === "Phong kham A")).toBe(true);
    });
});
