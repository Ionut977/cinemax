// ignore_for_file: use_build_context_synchronously

import 'package:flixquest/main.dart';
import 'package:flixquest/video_providers/common.dart';
import 'package:flixquest/video_providers/zoro.dart';
import 'package:provider/provider.dart';
import '../../functions/function.dart';
import '../../provider/app_dependency_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../functions/network.dart';
import '../../provider/settings_provider.dart';
import '../../video_providers/flixhq.dart';
import '../../video_providers/names.dart';
import '../../video_providers/superstream.dart';
import '../../services/globle_method.dart';

class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({Key? key}) : super(key: key);

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  List<RegularVideoLinks>? videoLinks;
  FlixHQStreamSources? fqVideoSources;
  SuperstreamStreamSources? superstreamVideoSources;
  DCVAStreamSources? dramacoolStreamSources;
  DCVAStreamSources? viewasianStreamSources;
  ZoroStreamSources? zoroStreamSources;
  List<VideoStatusCheck> videoProvidersCheck = [];
  String ping = "";
  DateTime? start;
  DateTime? end;
  bool checking = false;

  List<VideoProvider> videoProviders = [];
  List<String> messageStrings = [];

  late SettingsProvider prefString =
      Provider.of<SettingsProvider>(context, listen: false);

  late AppDependencyProvider appDependency =
      Provider.of<AppDependencyProvider>(context, listen: false);

  void checkServer() async {
    setState(() {
      checking = true;
      videoProvidersCheck = [];
    });
    for (int i = 0; i < videoProviders.length; i++) {
      videoProvidersCheck.add(VideoStatusCheck(
          codeName: videoProviders[i].codeName,
          fullName: videoProviders[i].fullName,
          end: null,
          isWaiting: true,
          isWorking: false,
          ping: '',
          resultMessage: '',
          start: null,
          waitingMessage: tr("waiting_queue",
              namedArgs: {"server": videoProviders[i].fullName})));
    }
    for (int i = 0; i < videoProviders.length; i++) {
      setState(() {
        videoProvidersCheck[i].waitingMessage =
            '${tr("checking_server")} ${videoProviders[i].fullName}';
        videoProvidersCheck[i].resultMessage = "";
        videoProvidersCheck[i].ping = "";
        videoLinks = null;
        videoProvidersCheck[i].isWaiting = true;
        start = null;
      });
      if (videoProviders[i].codeName == 'flixhq') {
        start = DateTime.now();
        try {
          await getMovieStreamLinksAndSubsFlixHQ(
                  "${appDependency.consumetUrl}movies/flixhq/watch?episodeId=97708&mediaId=movie/watch-no-hard-feelings-97708&server=${appDependency.streamingServerFlixHQ}")
              .then((value) {
            if (mounted) {
              fqVideoSources = value;
              videoLinks = fqVideoSources!.videoLinks;
            }
          });
        } on Exception catch (e) {
          GlobalMethods.showErrorScaffoldMessenger(e.toString(), context);
        }
      } else if (videoProviders[i].codeName == 'superstream') {
        start = DateTime.now();

        try {
          await getSuperstreamStreamingLinks(
                  "${appDependency.flixquestAPIURL}superstream/watch-movie?tmdbId=455980")
              .then((value) {
            if (mounted) {
              superstreamVideoSources = value;
              videoLinks = superstreamVideoSources!.videoLinks;
            }
          });
        } on Exception catch (e) {
          GlobalMethods.showErrorScaffoldMessenger(e.toString(), context);
        }
      } else if (videoProviders[i].codeName == 'dramacool') {
        start = DateTime.now();
        try {
          await getMovieTVStreamLinksAndSubsDCVA(
                  "${appDependency.consumetUrl}movies/dramacool/watch?id=drama-detail/a-different-girl&episodeId=a-different-girl-2021-episode-1&server=${appDependency.streamingServerDCVA}")
              .then((value) {
            if (mounted) {
              dramacoolStreamSources = value;
              videoLinks = dramacoolStreamSources!.videoLinks;
            }
          });
        } on Exception catch (e) {
          GlobalMethods.showErrorScaffoldMessenger(e.toString(), context);
        }
      } else if (videoProviders[i].codeName == 'viewasian') {
        start = DateTime.now();
        try {
          await getMovieTVStreamLinksAndSubsDCVA(
                  "${appDependencyProvider.consumetUrl}movies/viewasian/watch?id=drama/tell-me-you-love-me&episodeId=/watch/tell-me-you-love-me/watching.html\$episode\$1&server=${appDependencyProvider.streamingServerDCVA}")
              .then((value) {
            if (mounted) {
              viewasianStreamSources = value;
              videoLinks = viewasianStreamSources!.videoLinks;
            }
          });
        } on Exception catch (e) {
          GlobalMethods.showErrorScaffoldMessenger(e.toString(), context);
        }
      } else if (videoProviders[i].codeName == 'zoro') {
        start = DateTime.now();
        try {
          await getMovieTVStreamLinksAndSubsZoro(
                  "${appDependencyProvider.consumetUrl}anime/zoro/watch?episodeId=one-piece-movie-1-3096\$episode\$58122\$sub&server=${appDependencyProvider.streamingServerZoro}")
              .then((value) {
            if (mounted) {
              zoroStreamSources = value;
              videoLinks = zoroStreamSources!.videoLinks;
            }
          });
        } on Exception catch (e) {
          GlobalMethods.showErrorScaffoldMessenger(e.toString(), context);
        }
      } else if (videoProviders[i].codeName == 'flixhqS2') {
        start = DateTime.now();
        try {
          await getSuperstreamStreamingLinks(
                  "${appDependency.flixquestAPIURL}flixhq/watch-movie?tmdbId=455980")
              .then((value) {
            if (mounted) {
              superstreamVideoSources = value;
              videoLinks = superstreamVideoSources!.videoLinks;
            }
          });
        } on Exception catch (e) {
          GlobalMethods.showErrorScaffoldMessenger(e.toString(), context);
        }
      }

      end = DateTime.now();
      ping = end!.difference(start!).inMilliseconds.toString();
      videoProvidersCheck[i].ping = ping;

      videoProvidersCheck[i].waitingMessage =
          '${videoProviders[i].fullName} ${tr("server_check_complete")}';

      if (mounted) {
        if (videoLinks == null || videoLinks!.isEmpty) {
          setState(() {
            videoProvidersCheck[i].isWaiting = false;
            videoProvidersCheck[i].resultMessage =
                "${videoProviders[i].fullName} ${tr("server_down")}";
          });
        } else {
          setState(() {
            videoProvidersCheck[i].isWaiting = false;
            videoProvidersCheck[i].isWorking = true;
            videoProvidersCheck[i].resultMessage =
                '${videoProviders[i].fullName} ${tr("server_working")}';
          });
        }
      }
    }
    setState(() {
      checking = false;
    });
  }

  @override
  void initState() {
    videoProviders.addAll(
        parseProviderPrecedenceString(prefString.proPreference)
            .where((provider) => provider != null)
            .cast<VideoProvider>());

    checkServer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(tr("check_server")),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: videoProviders.length,
                      itemBuilder: ((context, index) {
                        return Column(
                          children: [
                            Text(
                              videoProvidersCheck[index].waitingMessage!,
                              style: const TextStyle(
                                fontFamily: 'PoppinsSB',
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                            ),
                            Visibility(
                              visible: !videoProvidersCheck[index].isWaiting! &&
                                  videoProvidersCheck[index].resultMessage !=
                                      null,
                              child: Text(
                                videoProvidersCheck[index].resultMessage!,
                                style: kTextHeaderStyle.copyWith(
                                    color: videoProvidersCheck[index].isWaiting!
                                        ? Colors.white
                                        : videoProvidersCheck[index].isWorking!
                                            ? Colors.green
                                            : Colors.red,
                                    fontSize: 22),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                              ),
                            ),
                            Visibility(
                              visible: !videoProvidersCheck[index].isWaiting!,
                              child: Text(
                                tr("latency", namedArgs: {
                                  "l": videoProvidersCheck[index].ping!
                                }),
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(
                              height: 25,
                            ),
                            const Divider(
                              thickness: 3,
                            ),
                          ],
                        );
                      })),
                  Visibility(
                    visible: !checking,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              checkServer();
                            },
                            child: Text(tr("check"))),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}

class VideoStatusCheck {
  String? waitingMessage;
  String? codeName;
  String? fullName;
  bool? isWorking;
  DateTime? start;
  DateTime? end;
  String? ping;
  String? resultMessage;
  bool? isWaiting;

  VideoStatusCheck(
      {required this.codeName,
      required this.fullName,
      required this.end,
      required this.isWaiting,
      required this.isWorking,
      required this.ping,
      required this.resultMessage,
      required this.start,
      required this.waitingMessage});
}
