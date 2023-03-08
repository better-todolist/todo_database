import 'package:objectbox/objectbox.dart';
import 'package:todo_record/time_representation/representation.dart';
import 'package:todo_record/time_representation/time_limit.dart';

@Entity()
class TodoItem {
  @Id()
  int id;

  String message;
  int priority;
  ToOne<DeathLineTime> timeToEnd = ToOne<DeathLineTime>();
  ToMany<TodoGroup> groups = ToMany<TodoGroup>();
  int tagsBitmap;
  TodoItem(
      {this.id = 0,
      required this.message,
      this.priority = 5,
      required this.groups,
      required this.timeToEnd,
      required this.tagsBitmap});
}

@Entity()
class DeathLineTime {
  @Id()
  int id;

  int? timeType;
  int ddlType;
  @Property(type: PropertyType.date)
  DateTime? time;

  DeathLineTime({
    this.id = 0,
    required this.ddlType,
    this.timeType,
    this.time,
  }) {
    assertTimeMod(TimeMod.values[ddlType],
        timeType == null ? null : TimeType.values[timeType!], time);
  }
}

assertTimeMod(TimeMod mod, TimeType? timeType, DateTime? time) {
  if (mod == TimeMod.deathLine) {
    assert(time != null);
    assert(timeType != null);
  }
}

@Entity()
class TodoGroup {
  @Id()
  int id;
  String? title;

  ToMany<SubTodo> subTodos = ToMany();

  TodoGroup({this.id = 0, required this.title, required this.subTodos});
}

@Entity()
class SubTodo {
  @Id()
  int id;

  String content;
  bool isDone;

  SubTodo({this.id = 0, required this.content, required this.isDone});
}
