export interface JwtPayload {
    sub: number;
    role: "patient" | "doctor" | "admin";
    patientId?: number;
    doctorId?: number;
}
