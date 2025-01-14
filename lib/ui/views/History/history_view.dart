import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:rutorrentflutter/enums/enums.dart';
import 'package:rutorrentflutter/models/history_item.dart';
import 'package:rutorrentflutter/models/mode.dart';
import 'package:rutorrentflutter/theme/app_state_notifier.dart';
import 'package:rutorrentflutter/ui/shared/shared_styles.dart';
import 'package:rutorrentflutter/ui/views/history/history_viewmodel.dart';
import 'package:rutorrentflutter/ui/widgets/dumb_widgets/loading_shimmer.dart';
import 'package:rutorrentflutter/ui/widgets/smart_widgets/search_bar/search_bar_view.dart';
import 'package:stacked/stacked.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HistoryViewModel>.reactive(
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'History',
            style: TextStyle(fontWeight: FontWeight.w400),
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.filter_list),
              ),
              itemBuilder: (context) {
                return model.choices
                    .map((e) => PopupMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ))
                    .toList();
              },
              onSelected: (choice) {
                model.selectedChoice = choice;
                choice == 'All'
                    ? model.loadHistoryItems()
                    : model.loadHistoryItems(
                        lastHrs: int.parse(choice.split(' ')[2]));
              },
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => model.refreshHistoryList(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              physics: ScrollPhysics(),
              child: Column(
                children: [
                  SearchBarWidget(
                    screen: Screens.TorrentHistoryViewScreen,
                  ),
                  ListTile(
                    title: Text(
                      'Files (${model.torrentHistoryDisplayList.value.length})',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  model.isBusy
                      ? LoadingShimmer().loadingEffect(context)
                      : (model.torrentHistoryDisplayList.value.length != 0)
                          ? ValueListenableBuilder(
                              valueListenable: model.torrentHistoryDisplayList,
                              builder:
                                  (context, List<HistoryItem> items, snapshot) {
                                return ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      onLongPress: () {
                                        _showRemoveDialog(
                                            items[index].hash, model, context);
                                      },
                                      title: SizedBox(
                                          width: 40,
                                          child: Text(items[index].name,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(4),
                                        width: 70,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                          color: getHistoryStatusColor(
                                              context, items[index].action),
                                        )),
                                        child: Text(
                                            HistoryItem.historyStatus[
                                                items[index].action]!,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: getHistoryStatusColor(
                                                  context, items[index].action),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            )),
                                      ),
                                      subtitle: Text(
                                        '${DateFormat('HH:mm dd MMM yy').format(DateTime.fromMillisecondsSinceEpoch(items[index].actionTime * 1000))} | ${filesize(items[index].size)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  },
                                );
                              })
                          : Center(
                              child: SvgPicture.asset(
                                Mode.isDarkMode
                                    ? 'assets/logo/empty.svg'
                                    : 'assets/logo/empty_dark.svg',
                                width: 120,
                                height: 120,
                              ),
                            ),
                ],
              ),
            ),
          ),
        ),
      ),
      viewModelBuilder: () => HistoryViewModel(),
    );
  }

  Color getHistoryStatusColor(BuildContext context, int action) {
    switch (action) {
      case 1: // Added
        return Theme.of(context).colorScheme.secondary;
      case 2: // Finished
        return !AppStateNotifier.isDarkModeOn ? kGreenActiveLT : kGreenActiveDT;
      case 3: // Deleted
        return !AppStateNotifier.isDarkModeOn ? kRedErrorLT : kRedErrorDT;
      default:
        return !AppStateNotifier.isDarkModeOn ? Colors.black : Colors.white;
    }
  }

  _showRemoveDialog(String hashValue, HistoryViewModel model, context) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                'Remove torrent from history',
                style: TextStyle(fontSize: 15),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Yes!',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  onPressed: () => model.removeHistoryItem(hashValue),
                ),
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ));
  }
}
