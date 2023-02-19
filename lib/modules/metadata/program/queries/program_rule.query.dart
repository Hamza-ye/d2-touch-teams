import 'package:d2_touch_teams/core/annotations/index.dart';
import 'package:d2_touch_teams/core/utilities/repository.dart';
import 'package:d2_touch_teams/modules/metadata/program/entities/program_rule.entity.dart';
import 'package:d2_touch_teams/modules/metadata/program/entities/program_rule_action.entity.dart';
import 'package:d2_touch_teams/shared/queries/base.query.dart';
import 'package:reflectable/reflectable.dart';
import 'package:sqflite/sqflite.dart';

class ProgramRuleQuery extends BaseQuery<ProgramRule> {
  ProgramRuleQuery({Database? database}) : super(database: database);

  ProgramRuleQuery withActions() {
    final programRuleAction = Repository<ProgramRuleAction>();
    final Column? relationColumn = programRuleAction.columns.firstWhere(
        (column) =>
            column.relation?.referencedEntity?.tableName == this.tableName);

    if (relationColumn != null) {
      ColumnRelation relation = ColumnRelation(
          referencedColumn: relationColumn.relation?.attributeName,
          attributeName: 'programRuleActions',
          primaryKey: this.primaryKey?.name,
          relationType: RelationType.OneToMany,
          referencedEntity: Entity.getEntityDefinition(
              AnnotationReflectable.reflectType(ProgramRuleAction)
                  as ClassMirror),
          referencedEntityColumns: Entity.getEntityColumns(
              AnnotationReflectable.reflectType(ProgramRuleAction)
                  as ClassMirror,
              false));
      this.relations.add(relation);
    }

    return this;
  }
}
