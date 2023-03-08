import 'package:objectbox/objectbox.dart';

@Entity()
class TagStore {
  @Id()
  int id;
  int tagId;
  String msg;

  TagStore({this.id = 0, required this.tagId, required this.msg}) {
    assert(tagId >= 0 && tagId < 32);
  }
}
