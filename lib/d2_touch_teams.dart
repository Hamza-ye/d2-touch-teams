library d2_touch_teams;

import 'package:d2_touch_teams/modules/auth/user/user.module.dart';
import 'package:d2_touch_teams/modules/data/aggregate/aggregate.module.dart';
import 'package:d2_touch_teams/modules/data/tracker/tracked_entity_instance.module.dart';
import 'package:d2_touch_teams/modules/file_resource/file_resource.module.dart';
import 'package:d2_touch_teams/modules/metadata/dataset/data_set.module.dart';
import 'package:d2_touch_teams/modules/metadata/option_set/option_set.module.dart';
import 'package:d2_touch_teams/modules/metadata/organisation_unit/organisation_unit.module.dart';
import 'package:d2_touch_teams/modules/metadata/program/program.module.dart';
import 'package:d2_touch_teams/modules/notification/notification.module.dart';
import 'package:d2_touch_teams/shared/utilities/http_client.util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'core/database/database_manager.dart';
import 'modules/auth/user/entities/user.entity.dart';
import 'modules/auth/user/models/auth-token.model.dart';
import 'modules/auth/user/models/login-response.model.dart';
import 'modules/auth/user/queries/user.query.dart';
import 'modules/auth/user/queries/user_organisation_unit.query.dart';
import 'modules/metadata/dashboard/dashboard.module.dart';
import 'modules/metadata/data_element/data_element.module.dart';

class D2TouchTeams {
  static Future<void> initialize({String? databaseName,
    bool? inMemory,
    DatabaseFactory? databaseFactory}) async {
    final newDatabaseName = databaseName ?? await D2TouchTeams.getDatabaseName();
    if (newDatabaseName != null) {
      DatabaseManager(
          databaseName: newDatabaseName,
          inMemory: inMemory,
          databaseFactory: databaseFactory);

      await DatabaseManager.instance.database;
      await UserModule.createTables();
      await OrganisationUnitModule.createTables();
      await DataElementModule.createTables();
      await DataSetModule.createTables();
      await ProgramModule.createTables();
      await DashboardModule.createTables();
      await TrackedEntityInstanceModule.createTables();
      await AggregateModule.createTables();
      await OptionSetModule.createTables();
      await NotificationModule.createTables();
      await FileResourceModule.createTables();
    }
  }

  static Future<bool> isAuthenticated(
      {Future<SharedPreferences>? sharedPreferenceInstance,
        bool? inMemory,
        DatabaseFactory? databaseFactory}) async {
    WidgetsFlutterBinding.ensureInitialized();
    final databaseName = await D2TouchTeams.getDatabaseName(
        sharedPreferenceInstance: sharedPreferenceInstance);

    if (databaseName == null) {
      return false;
    }

    await D2TouchTeams.initialize(
        databaseName: databaseName,
        inMemory: inMemory,
        databaseFactory: databaseFactory);

    User? user = await D2TouchTeams.userModule.user.getOne();

    return user?.isLoggedIn ?? false;
  }

  static Future<String?> getDatabaseName(
      {Future<SharedPreferences>? sharedPreferenceInstance}) async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs =
    await (sharedPreferenceInstance ?? SharedPreferences.getInstance());
    return prefs.getString('databaseName');
  }

  static Future<bool> setDatabaseName({required String databaseName,
    Future<SharedPreferences>? sharedPreferenceInstance}) async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs =
    await (sharedPreferenceInstance ?? SharedPreferences.getInstance());
    return prefs.setString('databaseName', databaseName);
  }

  static Future<LoginResponseStatus> logIn({required String username,
    required String password,
    required String url,
    Future<SharedPreferences>? sharedPreferenceInstance,
    bool? inMemory,
    DatabaseFactory? databaseFactory,
    Dio? dioTestClient}) async {
    WidgetsFlutterBinding.ensureInitialized();
    HttpResponse userResponse = await HttpClient.get(
        'me.json?fields=id,name,created,lastUpdated,birthday,gender,displayName,jobTitle,surname,employer,email,firstName,phoneNumber,nationality,userCredentials[code,id,name,lastLogin,displayName,username,userRoles[id,name,code]],organisationUnits[id,code,name],dataViewOrganisationUnits[id,code,name],userGroups[id,name],authorities,programs,dataSets',
        baseUrl: url,
        username: username,
        password: password,
        dioTestClient: dioTestClient);

    if (userResponse.statusCode == 401) {
      return LoginResponseStatus.WRONG_CREDENTIALS;
    }

    if (userResponse.statusCode == 500) {
      return LoginResponseStatus.SERVER_ERROR;
    }

    final uri = Uri
        .parse(url)
        .host;
    final String databaseName = '${username}_$uri';

    await D2TouchTeams.initialize(
        databaseName: databaseName,
        inMemory: inMemory,
        databaseFactory: databaseFactory);

    await D2TouchTeams.setDatabaseName(
        databaseName: databaseName,
        sharedPreferenceInstance:
        sharedPreferenceInstance ?? SharedPreferences.getInstance());

    UserQuery userQuery = UserQuery();

    Map<String, dynamic> userData = userResponse.body;
    userData['password'] = password;
    userData['isLoggedIn'] = true;
    userData['username'] = username;
    userData['baseUrl'] = url;
    userData['authTye'] = 'basic';
    userData['dirty'] = true;

    final user = User.fromApi(userData);
    await userQuery.setData(user).save();

    await UserOrganisationUnitQuery().setData(user.organisationUnits).save();

    return LoginResponseStatus.ONLINE_LOGIN_SUCCESS;
  }

  static Future<bool> logOut() async {
    WidgetsFlutterBinding.ensureInitialized();
    bool logOutSuccess = false;
    try {
      User? currentUser = await D2TouchTeams.userModule.user.getOne();

      currentUser?.isLoggedIn = false;
      currentUser?.dirty = true;

      await D2TouchTeams.userModule.user.setData(currentUser).save();

      logOutSuccess = true;
    } catch (e) {}
    return logOutSuccess;
  }

  static Future<LoginResponseStatus> setToken({required String instanceUrl,
    required Map<String, dynamic> userObject,
    required Map<String, dynamic> tokenObject,
    Future<SharedPreferences>? sharedPreferenceInstance,
    bool? inMemory,
    DatabaseFactory? databaseFactory,
    Dio? dioTestClient}) async {
    final uri = Uri
        .parse(instanceUrl)
        .host;
    final String databaseName = '$uri';
    await D2TouchTeams.initialize(
        databaseName: databaseName,
        inMemory: inMemory,
        databaseFactory: databaseFactory);

    await D2TouchTeams.setDatabaseName(
        databaseName: databaseName,
        sharedPreferenceInstance:
        sharedPreferenceInstance ?? SharedPreferences.getInstance());

    AuthToken token = AuthToken.fromJson(tokenObject);

    List<dynamic> authorities = [];

    userObject['userCredentials']['userRoles'].forEach((role) {

      List<dynamic> authoritiesToAdd = role["authorities"].map((auth) {
        return auth as String;
      }).toList();

      authorities.addAll(authoritiesToAdd);
    });

    userObject['token'] = token.accessToken;
    userObject['tokenType'] = token.tokenType;
    userObject['tokenExpiry'] = token.expiresIn;
    userObject['refreshToken'] = token.refreshToken;
    userObject['isLoggedIn'] = true;
    userObject['dirty'] = true;
    userObject['baseUrl'] = instanceUrl;
    userObject['authType'] = "token";
    userObject['authorities'] = authorities;

    final user = User.fromApi(userObject);
    await UserQuery().setData(user).save();

    await UserOrganisationUnitQuery().setData(user.organisationUnits).save();

    return LoginResponseStatus.ONLINE_LOGIN_SUCCESS;
  }

  static Future<List<Map>> rawQuery(
      {required String query, required List args}) async {
    final Database db = await DatabaseManager.instance.database;

    final List<Map> queryResult = await db.rawQuery(query.toString(), args);

    return queryResult;
  }

  static UserModule userModule = UserModule();

  static OrganisationUnitModule organisationUnitModule =
  OrganisationUnitModule();

  static DataElementModule dataElementModule = DataElementModule();

  static DataSetModule dataSetModule = DataSetModule();

  static ProgramModule programModule = ProgramModule();

  static DashboardModule dashboardModule = DashboardModule();

  static TrackedEntityInstanceModule trackerModule =
  TrackedEntityInstanceModule();

  static AggregateModule aggregateModule = AggregateModule();

  static NotificationModule notificationModule = NotificationModule();

  static OptionSetModule optionSetModule = OptionSetModule();

  static FileResourceModule fileResourceModule = FileResourceModule();
}
