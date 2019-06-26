import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:searxer/SearchResult.dart';
import 'package:searxer/SettingsPage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Searx.dart';
import 'Settings.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Searxer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Searxer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  final TextEditingController _controller = new TextEditingController();
  List<SearchResult> results = new List();
  String searchTerm = "";
  double progress = 0;
  ScrollController _scrollController =
      new ScrollController(keepScrollOffset: false);
  int _page = 0;

  void initPrefs() async {
    baseURL = await Settings().getURL();
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  Future<void> showimg(String url) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Image.network(url),
          );
        });
  }

  Widget _searchItemBuilder(BuildContext context, int index) {
    if (index != results.length)
      return new Column(children: <Widget>[
        ListTile(
          title: new Text(results[index].title),
          leading: results[index].seed != null
              ? new Container(
                  child: new Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        new Text(results[index].seed.toString(),
                            style: TextStyle(color: Colors.green)),
                        new Text(results[index].leech.toString(),
                            style: TextStyle(color: Colors.blue)),
                      ]),
                  //alignment: Alignment(0, 0),
                  width: 40,
                )
              : results[index].thumb != null
                  ? GestureDetector(
                      onTap: () {
                        showimg(results[index].img);
                      },
                      child: new Image.network(results[index].thumb,
                          width: 60, height: 40),
                    )
                  : null,
          trailing: results[index].magnet != null
              ? new Container(child: MaterialButton(
                  onPressed: () async {
                    openURL(results[index].magnet);
                  },
                  child: new Icon(
                    Icons.link,
                    color: Colors.white,
                    size: 18,
                  ),
                  color: Colors.blue,
                  shape: CircleBorder(),
                  height: 42,
                ), width: 50,)
              : null,
          subtitle: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(
                results[index].purl ?? "",
                style: TextStyle(
                  color: Colors.blue,
                ),
                textAlign: TextAlign.start,
              ),
              results[index].description != null ? new Text(results[index].description ?? ""):Container(),
              results[index].engine != null
                  ? new Text(
                      results[index].engine,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    )
                  : new Container(),
            ],
          ),
          onTap: () async {
            openURL(results[index].url);
          },
        )
      ]);
    else if (results.length != 0)
      return new FlatButton.icon(
          onPressed: () {
            _page++;
            search(searchTerm, page: _page);
          },
          icon: new Icon(Icons.more_horiz),
          label: new Text("more"));
    else
      return new Container();
  }

  void openURL(String URL) async {
    if (await canLaunch(URL)) {
      await launch(
        URL,
        enableJavaScript: true,
      );
    } else {
      throw 'Could not launch ${URL}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text("Searxer"),
        actions: <Widget>[
          new IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
                showFilterDialog();
              }),
          new IconButton(
              icon: Icon(Icons.category),
              onPressed: () {
                showCategoryDialog();
              }),
          new PopupMenuButton(
            itemBuilder: (context) {
              return Searx.TIME_RANGE_NAMES.map((String range) {
                return PopupMenuItem(
                  child: new Text(
                    range,
                    style: TextStyle(
                        fontWeight: (Searx.TIME_RANGE_NAMES[timeRange] == range)
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                  value: range,
                );
              }).toList();
            },
            icon: new Icon(Icons.date_range),
            onSelected: (String range) {
              timeRange = Searx.TIME_RANGE_NAMES.indexOf(range);
              setState(() {
                search(searchTerm);
              });
            },
          ),
          new IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              }),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Container(
              child: progress != 0
                  ? new LinearProgressIndicator(
                      value: progress,
                    )
                  : new Container(),
              height: 2,
            ),
            new Container(
              padding: EdgeInsets.all(6),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new AutoCompleteTextField<String>(
                      itemSubmitted: (item) => search(item),
                      controller: _controller,
                      itemBuilder: (context, suggestion) => new Padding(
                            child: new ListTile(title: new Text(suggestion)),
                            padding: EdgeInsets.all(0.0),
                          ),
                      itemFilter: (suggestion, input) => suggestion
                          .toLowerCase()
                          .startsWith(input.toLowerCase()),
                      suggestions: suggestions,
                      key: key,
                      textChanged: (String text) async {
                        if (await Settings().getAutoComplete())
                          Searx().getAutoComplete(text);
                        searchTerm = text;
                      },
                      textSubmitted: search,
                      clearOnSubmit: false,
                      onFocusChanged: (hasFocus) {},
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black),
                            gapPadding: 0),
                        contentPadding: EdgeInsets.all(8),
                        suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              suggestions.clear();
                              WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(key.currentState.textField.focusNode));
                            }),
                      ),
                    
                    ),
                  ),
                  new IconButton(
                    color: Colors.blueAccent,
                    icon: new Icon(Icons.search),
                    onPressed: () => search(searchTerm),
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.start,
              ),
            ),
            new Expanded(
              child: new NotificationListener(
                child: new ListView.builder(
                  itemBuilder: _searchItemBuilder,
                  itemCount: results.length + 1,
                  shrinkWrap: true,
                  controller: _scrollController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void search(String text, {int page = 0}) async {
    _page = page;
    setState(() {
      progress = null;
    });
    searchTerm = text;
    if (page == 0) results.clear();
    if (searchTerm != null && searchTerm != "")
      results.addAll(await Searx().getSearchResults(searchTerm, page: page));
    setState(() {
      progress = 0;
    });
  }

  Future<bool> showCategoryDialog() {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return new CategoryDialog();
      },
    ).then((var a) {
      search(searchTerm);
    });
  }

  Future<bool> showFilterDialog() {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return new FilterDialog();
      },
    ).then((var a) {
      search(searchTerm);
    });
  }
}

class CategoryDialog extends StatefulWidget {
  @override
  CategoryDialogState createState() => new CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialog> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = new List();
    children.addAll(categories.keys.map((String category) {
      return new CheckboxListTile(
        value: categories[category],
        onChanged: (bool state) {
          setState(() {
            categories.update(category, (bool a) => state);
          });
        },
        title: new Text(category),
      );
    }).toList());
    children.add(new FlatButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: new Text("Apply")));
    return SimpleDialog(
      title: new Text("Categories"),
      children: children,
    );
  }
}

class FilterDialog extends StatefulWidget {
  @override
  FilterDialogState createState() => new FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = new List();
    children.addAll(engines.keys.map((String engine) {
      return new CheckboxListTile(
        value: engines[engine],
        onChanged: (bool state) {
          setState(() {
            engines.update(engine, (bool a) => state);
          });
        },
        title: new Text(engine),
      );
    }).toList());
    children.add(new FlatButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: new Text("Apply")));
    return SimpleDialog(
      title: new Text("Searx engines"),
      children: children,
    );
  }
}
