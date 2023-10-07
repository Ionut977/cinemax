// ignore_for_file: use_build_context_synchronously, avoid_print
import '/api/endpoints.dart';
import '/functions/network.dart';
import '/main.dart';
import '/widgets/common_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:better_player/better_player.dart';
import 'package:startapp_sdk/startapp.dart';
import '../../models/sub_languages.dart';
import '../../models/tv_stream.dart';
import '../../provider/app_dependency_provider.dart';
import '../../provider/settings_provider.dart';
import '/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../../screens/common/player.dart';

class TVVideoLoader extends StatefulWidget {
  const TVVideoLoader(
      {required this.metadata,
      required this.download,
      required this.route,
      Key? key})
      : super(key: key);

  final List metadata;
  final bool download;
  final StreamRoute route;

  @override
  State<TVVideoLoader> createState() => _TVVideoLoaderState();
}

class _TVVideoLoaderState extends State<TVVideoLoader> {
  List<TVResults>? tvShows;
  List<TVEpisodes>? epi;
  TVVideoSources? tvVideoSources;
  List<TVVideoLinks>? tvVideoLinks;
  List<TVVideoSubtitles>? tvVideoSubs;
  TVInfo? tvInfo;
  double loadProgress = 0.00;
  late SettingsProvider settings =
      Provider.of<SettingsProvider>(context, listen: false);
  late AppDependencyProvider appDep =
      Provider.of<AppDependencyProvider>(context, listen: false);

  /// TMDB Route
  TVTMDBRoute? tvInfoTMDB;

  var startAppSdk = StartAppSdk();
  StartAppInterstitialAd? interstitialAd;

  void loadInterstitialAd() {
    startAppSdk.loadInterstitialAd().then((interstitialAd) {
      setState(() {
        this.interstitialAd = interstitialAd;
      });
    }).onError<StartAppException>((ex, stackTrace) {
      debugPrint("Error loading Interstitial ad: ${ex.message}");
    }).onError((error, stackTrace) {
      debugPrint("Error loading Interstitial ad: $error");
    });
  }

  @override
  void initState() {
    super.initState();
    if (appDependencyProvider.enableADS) {
      startAppSdk.setTestAdsEnabled(false);
      loadInterstitialAd();
    }
    loadVideo();
  }

  String processVttFileTimestamps(String vttFile) {
    final lines = vttFile.split('\n');
    final processedLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('-->') && line.trim().length == 23) {
        String endTimeModifiedString =
            '${line.trim().substring(0, line.trim().length - 9)}00:${line.trim().substring(line.trim().length - 9)}';
        String finalStr = '00:$endTimeModifiedString';
        processedLines.add(finalStr);
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  void loadVideo() async {
    print(settings.defaultSubtitleLanguage);
    try {
      late int totalSeasons;
      if (widget.route == StreamRoute.flixHQ) {
        await fetchTVDetails(
                Endpoints.tvDetailsUrl(widget.metadata.elementAt(7), "en"))
            .then(
          (value) async {
            totalSeasons = value.numberOfSeasons!;
            print(totalSeasons);
            await fetchTVForStream(Endpoints.searchMovieTVForStream(
                    widget.metadata.elementAt(1), appDep.consumetUrl))
                .then((value) async {
              if (mounted) {
                setState(() {
                  tvShows = value;
                });
              }
              print("point 1");
              for (int i = 0; i < tvShows!.length; i++) {
                if (tvShows![i].seasons == totalSeasons &&
                    tvShows![i].type == 'TV Series') {
                  print("point 2");
                  await getTVStreamEpisodes(Endpoints.getMovieTVStreamInfo(
                          tvShows![i].id!, appDep.consumetUrl))
                      .then((value) async {
                    setState(() {
                      tvInfo = value;
                      epi = tvInfo!.episodes;
                    });

                    for (int k = 0; k < epi!.length; k++) {
                      if (epi![k].episode == widget.metadata.elementAt(3) &&
                          epi![k].season == widget.metadata.elementAt(4)) {
                        print("point 3");
                        await getTVStreamLinksAndSubs(
                                Endpoints.getMovieTVStreamLinks(
                                    epi![k].id!,
                                    tvShows![i].id!,
                                    appDep.consumetUrl,
                                    appDep.streamingServer))
                            .then((value) {
                          if (mounted) {
                            setState(() {
                              tvVideoSources = value;
                            });
                          }
                          tvVideoLinks = tvVideoSources!.videoLinks;
                          tvVideoSubs = tvVideoSources!.videoSubtitles;
                        });
                        break;
                      }
                    }
                  });

                  break;
                }

                if (tvShows![i].seasons == (totalSeasons - 1) &&
                    tvShows![i].type == 'TV Series') {
                  print("point 4");
                  await getTVStreamEpisodes(Endpoints.getMovieTVStreamInfo(
                          tvShows![i].id!, appDep.consumetUrl))
                      .then((value) async {
                    setState(() {
                      tvInfo = value;
                      epi = tvInfo!.episodes;
                    });

                    for (int k = 0; k < epi!.length; k++) {
                      if (epi![k].episode == widget.metadata.elementAt(3) &&
                          epi![k].season == widget.metadata.elementAt(4)) {
                        print("point 5");
                        await getTVStreamLinksAndSubs(
                                Endpoints.getMovieTVStreamLinks(
                                    epi![k].id!,
                                    tvShows![i].id!,
                                    appDep.consumetUrl,
                                    appDep.streamingServer))
                            .then((value) {
                          setState(() {
                            tvVideoSources = value;
                          });
                          tvVideoLinks = tvVideoSources!.videoLinks;
                          tvVideoSubs = tvVideoSources!.videoSubtitles;
                        });
                        break;
                      }
                    }
                  });

                  break;
                }
              }
            });
          },
        );
      } else {
        await getTVStreamEpisodesTMDB(Endpoints.getMovieTVStreamInfoTMDB(
                widget.metadata.elementAt(7).toString(),
                "tv",
                appDep.consumetUrl))
            .then((value) async {
          setState(() {
            tvInfoTMDB = value;
          });
          if (tvInfoTMDB!.id != null &&
              tvInfoTMDB!.seasons != null &&
              tvInfoTMDB!.seasons![widget.metadata.elementAt(4) - 1]
                      .episodes![widget.metadata.elementAt(3) - 1].id !=
                  null) {
            await getTVStreamLinksAndSubs(Endpoints.getMovieTVStreamLinksTMDB(
                    appDep.consumetUrl,
                    tvInfoTMDB!.seasons![widget.metadata.elementAt(4) - 1]
                        .episodes![widget.metadata.elementAt(3) - 1].id!,
                    tvInfoTMDB!.id!,
                    appDep.streamingServer))
                .then((value) {
              setState(() {
                tvVideoSources = value;
              });
              tvVideoLinks = tvVideoSources!.videoLinks;
              tvVideoSubs = tvVideoSources!.videoSubtitles;
            });
          }
        });
      }

      Map<String, String> videos = {};
      List<BetterPlayerSubtitlesSource> subs = [];

      late int foundIndex;

      for (int i = 0; i < supportedLanguages.length; i++) {
        if (supportedLanguages[i].languageCode ==
            settings.defaultSubtitleLanguage) {
          foundIndex = i;
          break;
        }
      }
      if (tvVideoSubs != null) {
        if (supportedLanguages[foundIndex].englishName == '') {
          for (int i = 0; i < tvVideoSubs!.length - 1; i++) {
            setState(() {
              loadProgress = (i / tvVideoSubs!.length) * 100;
              print(loadProgress);
            });
            await getVttFileAsString(tvVideoSubs![i].url!).then((value) {
              subs.addAll({
                BetterPlayerSubtitlesSource(
                    name: tvVideoSubs![i].language!,
                    content: processVttFileTimestamps(value),
                    selectedByDefault: tvVideoSubs![i].language == 'English' ||
                            tvVideoSubs![i].language == 'English - English' ||
                            tvVideoSubs![i].language == 'English - SDH' ||
                            tvVideoSubs![i].language == 'English 1' ||
                            tvVideoSubs![i].language == 'English - English [CC]'
                        ? true
                        : false,
                    type: BetterPlayerSubtitlesSourceType.memory)
              });
            });
          }
        } else {
          if (tvVideoSubs!
              .where((element) => element.language!
                  .startsWith(supportedLanguages[foundIndex].englishName))
              .isNotEmpty) {
            await getVttFileAsString(tvVideoSubs!
                    .where((element) => element.language!
                        .startsWith(supportedLanguages[foundIndex].englishName))
                    .first
                    .url!)
                .then((value) {
              print(processVttFileTimestamps(value));
              subs.addAll({
                BetterPlayerSubtitlesSource(
                    name: tvVideoSubs!
                        .where((element) => element.language!.startsWith(
                            supportedLanguages[foundIndex].englishName))
                        .first
                        .language,
                    content: processVttFileTimestamps(value),
                    selectedByDefault: true,
                    type: BetterPlayerSubtitlesSourceType.memory)
              });
            });
          } else {
            print("EXTERNAL CALLED");
            await fetchSocialLinks(
              Endpoints.getExternalLinksForTV(
                  widget.metadata.elementAt(7), "en"),
            ).then((value) async {
              await getExternalSubtitle(
                      Endpoints.searchExternalEpisodeSubtitles(
                          value.imdbId!,
                          widget.metadata.elementAt(3),
                          widget.metadata.elementAt(4),
                          supportedLanguages[foundIndex].languageCode),
                      appDep.opensubtitlesKey)
                  .then((value) async {
                if (value.isNotEmpty) {
                  await downloadExternalSubtitle(
                          Endpoints.externalSubtitleDownload(),
                          value[0].attr!.files![0].fileId,
                          appDep.opensubtitlesKey)
                      .then((value) async {
                    subs.addAll({
                      BetterPlayerSubtitlesSource(
                          name: supportedLanguages[foundIndex].englishName,
                          urls: [value.link],
                          selectedByDefault: true,
                          type: BetterPlayerSubtitlesSourceType.network)
                    });
                  });
                }
              });
            });
          }
        }
      }

      if (tvVideoLinks != null) {
        for (int k = 0; k < tvVideoLinks!.length; k++) {
          videos.addAll({tvVideoLinks![k].quality!: tvVideoLinks![k].url!});
        }
      }

      List<MapEntry<String, String>> reversedVideoList =
          videos.entries.toList().reversed.toList();
      Map<String, String> reversedVids = Map.fromEntries(reversedVideoList);

      if (tvVideoLinks != null && mounted) {
        if (interstitialAd != null) {
          interstitialAd!.show().then((shown) {
            if (shown) {
              setState(() {
                interstitialAd = null;
                loadInterstitialAd();
              });
            }

            return null;
          }).onError((error, stackTrace) {
            debugPrint("Error showing Interstitial ad: $error");
          });
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) {
              return PlayerOne(
                  mediaType: MediaType.tvShow,
                  sources: reversedVids,
                  subs: subs,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.background
                  ],
                  settings: settings,
                  tvMetadata: widget.metadata);
            },
          ));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) {
              return PlayerOne(
                  mediaType: MediaType.tvShow,
                  sources: reversedVids,
                  subs: subs,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.background
                  ],
                  settings: settings,
                  tvMetadata: widget.metadata);
            },
          ));
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          showModalBottomSheet(
              builder: (context) {
                return ReportErrorWidget(
                  error: tr("tv_vid_404"),
                );
              },
              context: context);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       tr("tv_vid_404"),
          //       maxLines: 3,
          //       style: kTextSmallBodyStyle,
          //     ),
          //     duration: const Duration(seconds: 3),
          //   ),
          // );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
            builder: (context) {
              return ReportErrorWidget(
                error: "${tr("tv_vid_404")}\n$e",
              );
            },
            context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.onBackground,
        ),
        height: 120,
        width: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 65,
              width: 65,
            ),
            const SizedBox(
              height: 15,
            ),
            const SizedBox(width: 160, child: LinearProgressIndicator()),
            Visibility(
              visible: settings.defaultSubtitleLanguage != '' ? false : true,
              child: Text(
                '${loadProgress.toStringAsFixed(0).toString()}%',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.background),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
