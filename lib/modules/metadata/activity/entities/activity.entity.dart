import 'package:d2_touch_teams/core/annotations/index.dart';
import 'package:d2_touch_teams/modules/metadata/project/entities/project.entity.dart';
import 'package:d2_touch_teams/modules/user_enrollment/assignment/entities/assignment.entity.dart';
import 'package:d2_touch_teams/modules/user_enrollment/team/entities/team.entity.dart';
import 'package:d2_touch_teams/shared/entities/identifiable.entity.dart';

@AnnotationReflectable
@Entity(tableName: 'activity', apiResourceName: 'activities')
class Activity extends IdentifiableEntity {
  @ManyToOne(table: Project, joinColumnName: 'project')
  dynamic project;

  @Column(nullable: true)
  String? startDate;

  @Column(nullable: true)
  String? endDate;

  @Column(nullable: true)
  Object? programs;

  @Column(type: ColumnType.BOOLEAN)
  bool inactive;

  @OneToMany(table: Assignment)
  List<Assignment>? assignments;

  @OneToMany(table: Team)
  List<Team>? teams;

  Activity(
      {required String id,
      String? created,
      String? lastUpdated,
      required String name,
      required String shortName,
      this.project,
      String? code,
      String? displayName,
      this.startDate,
      this.endDate,
      this.programs,
      required this.inactive,
      this.assignments,
      this.teams,
      required dirty})
      : super(
            id: id,
            name: name,
            shortName: shortName,
            displayName: displayName,
            code: code,
            created: created,
            lastUpdated: lastUpdated,
            dirty: dirty);

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
        id: json['id'],
        name: json['name'],
        created: json['created'],
        shortName: json['shortName'],
        code: json['code'],
        displayName: json['displayName'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        project: json['project'],
        inactive: json['inactive'],
        programs: json['programs']?.toString() ?? null,
        assignments: (json['assignments'] ?? [])
            .map<Assignment>((assignment) => Assignment.fromJson(
                {...assignment, 'team': json['id'], 'dirty': false}))
            .toList(),
        teams: (json['teams'] ?? [])
            .map<Assignment>((team) => Team.fromJson(
                {...team, 'activity': json['id'], 'dirty': false}))
            .toList(),
        dirty: json['dirty']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lastUpdated'] = this.lastUpdated;
    data['id'] = this.id;
    data['created'] = this.created;
    data['name'] = this.name;
    data['shortName'] = this.shortName;
    data['code'] = this.code;
    data['displayName'] = this.displayName;
    data['startDate'] = this.startDate;
    data['endDate'] = this.endDate;
    data['project'] = this.project;
    data['programs'] = this.programs;
    data['assignments'] = this.assignments;
    data['teams'] = this.teams;
    data['inactive'] = this.inactive;
    data['dirty'] = this.dirty;
    return data;
  }
}
