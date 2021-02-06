import 'package:flutter/material.dart';

/* Screen where the individual details of each item are shown
   1. Show item name
   2. Show parents of item, and allow adding and removing parents
   3. Show and edit alternate names of the item
   4. Show description text of the item, and add or remove description text
 */

class DetailsScreen extends StatefulWidget {
  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Character Name'), //TODO: Placeholder for item name
      ),
      body: Column(
        children: [
          _WrapListViewer(
            title: 'Parents:',
            items: [
              //TODO: Placeholder for item parents
              'Parent ABC',
              'Parent Goku',
              'Parent Kakarot',
              'Parent Vegeta',
              'Parent Piccolottroti',
              'Parent Of 666 Bastards',
            ],
            generator: (s) => _Parent(s),
          ),
          _WrapListViewer(
            title: 'Alternate names:',
            items: [
              //TODO: Placeholder for nicknames
              'CWAB',
              'Achuth',
              'Pot',
              'Godly',
              'Tillu',
              'Pizza',
              'Moc',
              'Lappy',
              'Macha',
              'Cow',
            ],
            generator: (s) => _Nickname(s),
          )
        ],
      ),
    );
  }
}

class _WrapListViewer extends StatelessWidget {
  final String title;
  final List<String> items;
  final Widget Function(String) generator;

  _WrapListViewer({this.title, this.items, this.generator});

  List<Widget> _generateChildren() {
    final children = <Widget>[];
    for (final item in items) {
      children.add(generator(item));
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.grey),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
            child: Text(title),
          ),
          Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._generateChildren(),
              GestureDetector(
                child: Icon(Icons.add),
                onTap: () {
                  //TODO: Add callback for adding parent
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Parent extends StatelessWidget {
  final String text;

  _Parent(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.0),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          GestureDetector(
            child: Icon(Icons.cancel),
            onTap: () {
              //TODO: Delete parent from list
            },
          ),
        ],
      ),
    );
  }
}

class _Nickname extends StatelessWidget {
  final String text;

  _Nickname(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            child: Text(text),
            onTap: () {
              //TODO: Popup to edit nickname
            },
          ),
          GestureDetector(
            child: Icon(Icons.cancel),
            onTap: () {
              //TODO: Delete nickname from list
            },
          ),
        ],
      ),
    );
  }
}
