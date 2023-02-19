import 'package:d2_touch_teams/modules/metadata/program/entities/program_stage_section_data_element.entity.dart';
import 'package:d2_touch_teams/shared/queries/base.query.dart';
import 'package:sqflite/sqlite_api.dart';

class ProgramStageSectionDataElementQuery
    extends BaseQuery<ProgramStageSectionDataElement> {
  ProgramStageSectionDataElementQuery({Database? database})
      : super(database: database);
}
