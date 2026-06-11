import { SetMetadata } from "@nestjs/common";
import { AccountRole } from "../../auth/entities/account.entity";

export const ROLES_KEY = "roles";

/** Restricts a route to the given account roles (checked by RolesGuard). */
export const Roles = (...roles: AccountRole[]) => SetMetadata(ROLES_KEY, roles);
