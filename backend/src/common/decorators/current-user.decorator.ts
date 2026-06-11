import { createParamDecorator, ExecutionContext } from "@nestjs/common";
import { JwtPayload } from "../../auth/jwt-payload.interface";

/** Injects the authenticated user (JWT payload) set by JwtAuthGuard. */
export const CurrentUser = createParamDecorator(
    (_data: unknown, ctx: ExecutionContext): JwtPayload => {
        return ctx.switchToHttp().getRequest().user;
    },
);
