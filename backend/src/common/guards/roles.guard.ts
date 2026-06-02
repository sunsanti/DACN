import {
    CanActivate,
    ExecutionContext,
    ForbiddenException,
    Injectable,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { AccountRole } from "../../auth/entities/account.entity";
import { ROLES_KEY } from "../decorators/roles.decorator";

/**
 * Runs after JwtAuthGuard. If a route declares @Roles(...), require that
 * request.user.role is one of them; otherwise allow.
 */
@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private readonly reflector: Reflector) {}

    canActivate(ctx: ExecutionContext): boolean {
        const roles = this.reflector.getAllAndOverride<AccountRole[]>(ROLES_KEY, [
            ctx.getHandler(),
            ctx.getClass(),
        ]);
        if (!roles || roles.length === 0) return true;

        const { user } = ctx.switchToHttp().getRequest();
        if (!user || !roles.includes(user.role)) {
            throw new ForbiddenException("Không đủ quyền truy cập");
        }
        return true;
    }
}
