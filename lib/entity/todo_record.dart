import 'package:objectbox/objectbox.dart';
import 'package:todo_record/time_representation/time_limit.dart';

@Entity()
class TodoItem {
  @Id()
  int id;

  String message;
  @Property(type: PropertyType.int)
  Priority priority;
  DeathLineTime timeToEnd;
  List<TodoGroup> groups;

  TodoItem(
      {this.id = 0,
      required this.message,
      this.priority = Priority.level5,
      this.groups = const [],
      required this.timeToEnd});
}

enum Priority {
  level0,
  level1,
  level2,
  level3,
  level4,
  level5,
  level6,
  level7,
  level8,
  level9,
}

class DeathLineTime {
  TimeMod timeType;
  @Property(type: PropertyType.date)
  DateTime? time;

  DeathLineTime({this.timeType = TimeMod.limitless, this.time}) {
    switch (timeType) {
      case TimeMod.deathLine:
        assert(time != null);
        break;
      default:
        {}
    }
    ;
  }
}

class TodoGroup {
  String? title;
  List<SubTodo> subTodos;

  TodoGroup(this.title, [this.subTodos = const []]);
}

class SubTodo {
  String content;
  bool isDone;

  SubTodo(this.content, [this.isDone = false]);
}
