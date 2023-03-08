import 'package:flutter_test/flutter_test.dart';

import 'package:todo_database/todo_database.dart';
import 'package:path_provider/path_provider.dart';
void main() {
  test('adds one to input values', ()  async{
    final docsDir = await getApplicationDocumentsDirectory();
    print(docsDir);
  });
}
