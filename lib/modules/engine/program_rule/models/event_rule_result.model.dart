import 'package:d2_touch_teams/modules/data/tracker/entities/event.entity.dart';
import 'package:d2_touch_teams/modules/metadata/program/entities/program_rule_action.entity.dart';

class EventRuleResult {
  Event event;
  List<ProgramRuleAction> programRuleActions;
  EventRuleResult({required this.event, required this.programRuleActions});
}
