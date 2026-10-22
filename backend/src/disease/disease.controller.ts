import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post } from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { DiseaseService } from "./disease.service";
import { CreateDiseaseDTO, UpdateDiseaseDTO } from "./disease.dto";
import { Roles } from "../common/decorators/roles.decorator";
import { CurrentUser } from "../common/decorators/current-user.decorator";
import type { JwtPayload } from "../auth/jwt-payload.interface";

/** Bảng giá bệnh / dịch vụ. Trả kèm phí khám cố định để app tạm tính. */
@ApiTags("diseases")
@ApiBearerAuth()
@Controller("diseases")
export class DiseaseController {
    constructor(private readonly diseaseService: DiseaseService) {}

    @Roles("admin", "doctor")
    @Get()
    list(@CurrentUser() user: JwtPayload) {
        return this.diseaseService.list(user.role !== "admin");
    }

    @Roles("admin")
    @Post()
    create(@Body() dto: CreateDiseaseDTO) {
        return this.diseaseService.create(dto);
    }

    @Roles("admin")
    @Patch(":id")
    update(@Param("id", ParseIntPipe) id: number, @Body() dto: UpdateDiseaseDTO) {
        return this.diseaseService.update(id, dto);
    }
}
