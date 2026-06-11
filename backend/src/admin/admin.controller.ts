import { Controller, Get } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { AdminService } from "./admin.service";
import { Roles } from "../common/decorators/roles.decorator";

@ApiTags("admin")
@ApiBearerAuth()
@Roles("admin")
@Controller("admin")
export class AdminController {
    constructor(private readonly adminService: AdminService) {}

    /** Worked hours + computed salary per doctor. */
    @Get("doctor-salaries")
    doctorSalaries() {
        return this.adminService.doctorSalaries();
    }
}
