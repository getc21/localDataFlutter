import 'package:flutter/material.dart';
import 'package:local_example/data_base_helper.dart';
import 'package:local_example/import_data_from_excel.dart';

import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventListPage(),
    );
  }
}

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    var events = await DatabaseHelper().getEvents();
    print(events);
    setState(() {
      _events = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Manager'),
      ),
      body: ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          var event = _events[index];
          return Card(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        EventDetailPage(eventId: event['id'])),
              );
              },
              child: Container(
                child: Column(
                  children: [
                    Text(event['name']),
                    Text(event['description']),
                    Text(event['location']),
                    Text(event['time']),
                    Text(event['date'])
                  ],
                ),
              )),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEventPage()),
          ).then((_) => _loadEvents());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEventPage extends StatefulWidget {
  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre del evento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: 'Descripción del evento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Lugar del evento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Hora del evento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a time';
                  }
                  return null;
                },
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    _timeController.text = pickedTime.format(context);
                  }
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(labelText: 'Fecha del evento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  return null;
                },
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _dateController.text = pickedDate.toString().split(' ')[0];
                  }
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        var event = {
                          'name': _nameController.text,
                          'description': _descriptionController.text,
                          'location': _locationController.text,
                          'time': _timeController.text,
                          'date': _dateController.text,
                        };

                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['xlsx'],
                        );

                        // Muestra el AlertDialog después de que se importen los invitados
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                  '¿Deseas añadir el evento y la lista de invitados?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Cierra el AlertDialog
                                  },
                                  child: Text('No'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (result != null) {
                                      int eventId = await DatabaseHelper()
                                          .insertEvent(event);
                                      await importGuestsFromExcel(
                                          result.files.single.path!, eventId);
                                    }
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Sí'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    icon: Icon(Icons.import_export),
                    label: Text('Importar invitados'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}


class EventDetailPage extends StatefulWidget {
  final int eventId;

  EventDetailPage({required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  List<Map<String, dynamic>> _guestsList = [];

  @override
  void initState() {
    super.initState();
    _loadGuests(widget
        .eventId); // Llama a _loadGuests() para cargar los datos iniciales
  }

  Future<void> _loadGuests(int eventId) async {
    var guests = await DatabaseHelper().getGuests(eventId);
    print('Loaded guests: $guests'); // Debug print
    setState(() {
      _guestsList = guests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _guestsList.isEmpty
          ? Center(child: Text('No hay invitados para este evento.'))
          : ListView.builder(
              itemCount: _guestsList.length,
              itemBuilder: (context, index) {
                var guest = _guestsList[index];
                return ListTile(
                  title: Text(guest['name']),
                  subtitle: Text('Cédula: ${guest['identity_card']}'),
                  trailing: Text(
                      'Código: ${guest['code']} - Estado: ${guest['status']}'),
                );
              },
            ),
    );
  }
}
