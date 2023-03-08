import 'package:objectbox/objectbox.dart';

@Entity()
class FilterRecord {
  @Id()
  int id;

  int filterId;
  bool isInFilter;
  int type;
  FilterRecord(
      {this.id = 0, required this.filterId, this.isInFilter = false, required this.type});
}

