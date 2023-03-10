library todo_database;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:todo_database/entity/filter_record.dart';
import 'package:todo_database/entity/tags.dart';
import 'package:todo_database/entity/todo_record.dart';
import 'package:todo_database/objectbox.g.dart';
import 'package:todo_database/utils.dart';
import 'package:todo_record/database/database.dart';
import 'package:todo_record/record/common.dart';
import 'package:todo_record/record/sub_todo.dart';
import 'package:todo_record/record/todo_record.dart';
import 'package:todo_record/tag.dart';
import 'package:todo_record/time_representation/representation.dart';
import 'package:todo_record/time_representation/time_limit.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store) {
    // if there is no priority filter, set it
    var db = ObjectBoxDatabase(this);
    if (db.getFilter(FilterType.priority).isEmpty) {
      db.saveFilter(priorityFilter: List.generate(10, (index) => true).asMap());
    }
    if (db.getFilter(FilterType.tag).length != db.getTagMap().length) {
      var filter = db.getFilter(FilterType.tag);
      db
          .getTagMap()
          .entries
          .where((element) => !filter.containsKey(element.key))
          .forEach((element) {
        filter[element.key] = true;
      });

      db.saveFilter(tagFilter: filter);
    }
  }

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    print(docsDir);
    final store = await openStore(directory: p.join(docsDir.path, "todo-obx"));

    return ObjectBox._create(store);
  }
}

class ObjectBoxDatabase extends Database {
  final ObjectBox objectBox;

  ObjectBoxDatabase(this.objectBox);

  @override
  List<ContainId<TodoRecord>> findAllTodoRecord(
      {Map<dynamic, dynamic> filter = const {}}) {
    var tagSet = (getTagMap()).keys.toSet();
    final itemBox = objectBox.store.box<TodoItem>();
    var todos = itemBox.getAll().map((todoItem) {
      // groups
      var groups = todoItem.groups.map((element) {
        return SubTodoGroup(
            element.title,
            element.subTodos
                .map((element) =>
                    SubRecord(element.content)..setState(state: element.isDone))
                .toList());
      }).toList();

      // ddl
      var ddlDb = todoItem.timeToEnd.target ??
          DeathLineTime(ddlType: TimeMod.limitless.index);
      TimeToEnd ddl;
      switch (TimeMod.values[ddlDb.ddlType]) {
        case TimeMod.deathLine:
          {
            TimeRepresentation ddlTime;
            assert(ddlDb.timeType != null);
            assert(ddlDb.time != null);
            switch (TimeType.values[ddlDb.timeType!]) {
              case TimeType.per30Min:
                ddlTime = Per30MinTime(ddlDb.time!);
                break;
              case TimeType.perDay:
                ddlTime = PerDayTime(ddlDb.time!);
                break;
              case TimeType.perWeek:
                ddlTime = PerWeekTime(ddlDb.time!);
                break;
              case TimeType.perMonth:
                ddlTime = PerMonthTime(ddlDb.time!);
                break;
              case TimeType.perYear:
                ddlTime = PerYearTime(ddlDb.time!);
                break;
            }
            ddl = DeathLine(ddlTime);
          }
          break;
        case TimeMod.limitless:
          ddl = Limitless();
      }
      // priority
      assert(
          todoItem.priority >= 0 && todoItem.priority < Priority.values.length);
      // tags
      TagBitmap(todoItem.tagsBitmap).assertTag(tagSet);
      return ContainId(
          todoItem.id,
          TodoRecord(todoItem.message, end: ddl, groups: groups)
            ..setBitmap(todoItem.tagsBitmap)
            ..setPriority(priority: Priority.values[todoItem.id]));
    }).toList();
    return todos;
  }

  @override
  Map<int, bool> getFilter(FilterType type) {
    final filterBox = objectBox.store.box<FilterRecord>();

    var query = (filterBox.query(FilterRecord_.type.equals(type.index))
          ..order(FilterRecord_.filterId))
        .build();
    var result = query
        .find()
        .asMap()
        .map((key, value) => MapEntry(value.filterId, value.isInFilter));

    return result;
  }

  @override
  TagMap getTagMap() {
    final tagBox = objectBox.store.box<TagStore>();

    var map = tagBox
        .query(TagStore_.tagId.between(0, 31))
        .build()
        .find()
        .asMap()
        .map((_, v) => MapEntry(v.tagId, Tag(v.msg, v.tagId)));
    return map;
  }

  @override
  saveFilter({Map<int, bool>? priorityFilter, Map<int, bool>? tagFilter}) {
    final filterBox = objectBox.store.box<FilterRecord>();
    if (priorityFilter != null) {
      var old = filterBox
          .query(FilterRecord_.type.equals(FilterType.priority.index))
          .build()
          .find()
          .map((e) => e.id)
          .toList();
      filterBox.removeMany(old);

      var filters = priorityFilter.entries.map((e) {
        assert(e.key >= 0 && e.key < Priority.values.length);
        return FilterRecord(
            filterId: e.key,
            type: FilterType.priority.index,
            isInFilter: e.value);
      });

      filterBox.putMany(filters.toList());
    }

    if (tagFilter != null) {
      var old = filterBox
          .query(FilterRecord_.type.equals(FilterType.tag.index))
          .build()
          .find()
          .map((e) => e.id)
          .toList();
      filterBox.removeMany(old);

      var tagSet = (getTagMap()).keys.toSet();
      var filters = tagFilter.entries.map((e) {
        assert(tagSet.contains(e.key));
        return FilterRecord(
            filterId: e.key, type: FilterType.tag.index, isInFilter: e.value);
      });

      filterBox.putMany(filters.toList());
    }
  }

  @override
  saveTag({required Tag tag}) {
    final tagBox = objectBox.store.box<TagStore>();
    tagBox.put(TagStore(tagId: tag.id, msg: tag.msg));
  }

  @override
  Future<void> saveTodoRecord(TodoRecord record, {int id = 0}) async {
    var groups = record.groups
        .map((group) => TodoGroup(
            title: group.title,
            subTodos: ToMany(
                items: group.list
                    .map((e) =>
                        SubTodo(content: e.message, isDone: e.isFinish()))
                    .toList())))
        .toList();

    DeathLineTime ddl;
    switch (record.end.getMod()) {
      case TimeMod.deathLine:
        {
          assert(record.end.getTime() != null);

          ddl = DeathLineTime(
              ddlType: record.end.getMod().index,
              timeType: record.end.getTime()!.getType().index,
              time: record.end.getTime()!.getTime());
        }
        break;
      case TimeMod.limitless:
        ddl = DeathLineTime(ddlType: record.end.getMod().index);
        break;
    }

    var todoItem = TodoItem(
        id: id,
        message: record.message,
        groups: ToMany(items: groups),
        timeToEnd: ToOne(target: ddl),
        priority: record.getPriority().index,
        tagsBitmap: record.getBitmap().toInt());

    var todoItemBox = objectBox.store.box<TodoItem>();
    todoItemBox.put(todoItem);
  }

  @override
  Future<void> removeTodoRecord(int id) async {
    final todoBox = objectBox.store.box<TodoItem>();

    todoBox.remove(id);
  }

  @override
  Future<void> removeTag({required Tag tag}) {
    final tagBox = objectBox.store.box<TagStore>();
    final todoBox = objectBox.store.box<TodoItem>();

    var effects = todoBox.getAll()
      ..forEach((element) {
        element.tagsBitmap =
            TagBitmap(element.tagsBitmap).removeTag(tagId: tag.id);
      });
    todoBox.putMany(effects, mode: PutMode.update);
    tagBox.remove(tag.id);
    throw UnimplementedError();
  }
}
