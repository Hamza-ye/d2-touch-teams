import 'package:d2_touch_teams/modules/data/tracker/entities/tracked-entity.entity.dart';
import 'package:d2_touch_teams/modules/metadata/program/entities/program_rule_action.entity.dart';

class TrackerRuleResult {
  TrackedEntityInstance trackedEntityInstance;
  List<ProgramRuleAction> programRuleActions;
  TrackerRuleResult(
      {required this.trackedEntityInstance, required this.programRuleActions});
}
