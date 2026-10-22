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
    let slot: string; // a free slot inside the doctor's shift
    const email = `e2e_${Date.now()}@dacn.local`;
    const cccd = `9${String(Date.now()).slice(-11)}`; // unique 12 digits, not in the BHYT registry

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
                cccd,
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
                cccd,
            })
            .expect(409));

    it("login wrong password → 401", () =>
        request(app.getHttpServer())
            .post("/auth/login")
            .send({ email, password: "wrong-pass" })
            .expect(401));

    it("list-appointment without token → 401", () =>
        request(app.getHttpServer()).get("/patient/list-appointment").expect(401));

    it("patient cannot create a doctor → 403", () =>
        request(app.getHttpServer())
            .post("/auth/register-doctor")
            .set("Authorization", `Bearer ${token}`)
            .expect(403));

    it("admin creates a doctor (multipart, avatar required) to book against", async () => {
        const admin = await request(app.getHttpServer())
            .post("/auth/login")
            .send({ email: "admin@dacn.local", password: "Admin@123" })
            .expect(201);
        const png = Buffer.from(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
            "base64",
        );
        const docEmail = `e2e_doc_${Date.now()}@dacn.local`;
        const res = await request(app.getHttpServer())
            .post("/auth/register-doctor")
            .set("Authorization", `Bearer ${admin.body.accessToken}`)
            .field("email", docEmail)
            .field("password", "Test@123")
            .field("name", "E2E Doctor")
            .field("age", "40")
            .field("dateOfBirth", "1986-01-01")
            .field("gender", "male")
            .field("phone", "0900000002")
            .field("address", "abc")
            .attach("avatar", png, { filename: "a.png", contentType: "image/png" })
            .expect(201);
        doctorId = res.body.doctorId;
        expect(doctorId).toBeDefined();

        // booking needs a shift: doctor registers one 2 days ahead, patient picks its first free slot
        const doc = await request(app.getHttpServer())
            .post("/auth/login")
            .send({ email: docEmail, password: "Test@123" })
            .expect(201);
        const D = `Bearer ${doc.body.accessToken}`;
        const tpl = await request(app.getHttpServer()).get("/doctor/shift-templates").set("Authorization", D).expect(200);
        const date = new Date(Date.now() + 2 * 864e5).toISOString().slice(0, 10);
        await request(app.getHttpServer())
            .post("/doctor/register-shift")
            .set("Authorization", D)
            .send({ shiftId: tpl.body[0].id, date })
            .expect(201);
        const av = await request(app.getHttpServer())
            .get(`/doctor/availability?doctorId=${doctorId}&date=${date}`)
            .set("Authorization", `Bearer ${token}`)
            .expect(200);
        slot = av.body[0];
        expect(slot).toBeDefined();
    });

    it("create-appointment persists DTO values with confirmCondition=1", async () => {
        const res = await request(app.getHttpServer())
            .post("/patient/create-appointment")
            .set("Authorization", `Bearer ${token}`)
            .send({
                apTime: slot,
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
