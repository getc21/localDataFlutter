import 'package:excel/excel.dart';
import 'package:local_example/data_base_helper.dart';
import 'dart:io';

Future<void> importGuestsFromExcel(String filePath, int eventId) async {
  var bytes = File(filePath).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  for (var table in excel.tables.keys) {
    for (var row in excel.tables[table]!.rows) {
      if (row[0] != null && row[0] != 'Nombre') {
        var name = row[0]?.value.toString(); // Convertir a String
        var identityCard = row[1]?.value.toString(); // Convertir a String
        var code = row[2]?.value.toString(); // Convertir a String
        var status = row[3]?.value.toString(); // Convertir a String

        var guest = {
          'event_id': eventId,
          'name': name,
          'identity_card': identityCard,
          'code': code,
          'status': status
        };
        print('Inserting guest: $guest'); // Debug print
        await DatabaseHelper().insertGuest(guest);
      }
    }
  }
}
