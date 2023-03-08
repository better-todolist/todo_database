import 'package:todo_record/record/common.dart';

class TagBitmap with Tagable {
  TagBitmap(int bitmap){
    setBitmap(bitmap);
  }

  assertTag(Set<int> tagIdSet) {
    assert(tagIdSet.containsAll(getAllTagId()));
  }
}
