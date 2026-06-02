import {
    CanActivate,
    ExecutionContext,
    Injectable,
    UnauthorizedException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { JwtService } from "@nestjs/jwt";
import { IS_PUBLIC_KEY } from "../decorators/public.decorator";

/**
 * Global guard: lets @Public() routes through, otherwise requires a valid
 * Bearer JWT and attaches the decoded payload to request.user.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
    constructor(
        private readonly reflector: Reflector,
        private readonly jwt: JwtService,
    ) {}

    canActivate(ctx: ExecutionContext): boolean {
        const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
            ctx.getHandler(),
            ctx.getClass(),
        ]);
        if (isPublic) return true;

        const req = ctx.switchToHttp().getRequest();
        const auth: string = req.headers["authorization"] ?? "";
        const token = auth.startsWith("Bearer ") ? auth.slice(7) : null;
        if (!token) throw new UnauthorizedException();

        try {
            req.user = this.jwt.verify(token);
            return true;
        } catch {
            throw new UnauthorizedException();
        }
    }
}
