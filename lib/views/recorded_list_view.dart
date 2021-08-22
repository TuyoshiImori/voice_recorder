import 'dart:io';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class RecordListView extends StatefulWidget {
  final List<String> records;
  const RecordListView({
    Key key,
    this.records,
  }) : super(key: key);

  @override
  _RecordListViewState createState() => _RecordListViewState();
}

class _RecordListViewState extends State<RecordListView> {
  int _totalDuration;
  int _currentDuration;
  double _completedPercentage = 0.0;
  bool _isPlaying = false;
  int _selectedIndex = -1;

  Duration _duration = new Duration();
  Duration _position = new Duration();

  IconData playBtn = Icons.play_arrow;
  AudioPlayer audioPlayer;
  AudioCache audioCache;

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  void initPlayer() {
    audioPlayer = new AudioPlayer();
    audioCache = new AudioCache(fixedPlayer: audioPlayer);

    audioPlayer.durationHandler = (d) => setState(() {
      _duration = d;
    });

    audioPlayer.positionHandler = (p) => setState(() {
      _position = p;
    });
  }
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.records.length,
      shrinkWrap: true,
      reverse: true,
      itemBuilder: (BuildContext context, int i) {
        return ExpansionTile(
          title: Text('新規録音 ＃${widget.records.length - i}'),
          subtitle: Text(
              _getDateFromFilePath(
                filePath: widget.records.elementAt(i),
              ),
          ),
          onExpansionChanged: ((newState) {
            if (newState) {
              setState(() {
                _selectedIndex = i;
              });
            }
          }),
          children: [
            Container(
              height: 180,
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Slider(
                  activeColor: Colors.black,
                  inactiveColor: Colors.grey,
                  value: _selectedIndex == i ?_position.inSeconds.toDouble() : 0,
                  min: 0.0,
                  max: _duration.inSeconds.toDouble(),
                  onChanged: (double value) {
                    setState(() {
                      seekToSecond(value.toInt());
                      value = value;
                    });
                  }),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.more_horiz),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.fast_rewind_rounded),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(playBtn),
                        iconSize: 50,
                        onPressed: () {
                          _onPlay(
                              filePath: widget.records.elementAt(i), index: i
                          );
                        },
                        //onPressed: () => _onPlay(filePath: widget.records.elementAt(i), index: i),
                      ),
                      IconButton(
                          icon: Icon(Icons.fast_forward_rounded),
                          onPressed: () {},
                      ),
                      IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            Directory appDirec = Directory(widget.records.elementAt(i));
                            appDirec.delete(recursive: true);
                            //Fluttertoast.showToast(msg: "File Deleted");
                            setState(() {
                              widget.records
                                  .remove(widget.records.elementAt(i));
                            });
                          }
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onPlay({@required String filePath, @required int index}) async {



    if (!_isPlaying) {
      audioPlayer.play(widget.records.elementAt(index),
          isLocal: true);
      setState(() {
        _selectedIndex = index;
        _completedPercentage = 0.0;
        playBtn = Icons.pause;
        _isPlaying = true;
      });

      audioPlayer.onPlayerCompletion.listen((_) {
        setState(() {
          _isPlaying = false;
          _completedPercentage = 0.0;
        });
      });
      audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _totalDuration = duration.inMicroseconds;
        });
      });

      audioPlayer.onAudioPositionChanged.listen((duration) {
        setState(() {
          _currentDuration = duration.inMicroseconds;
          _completedPercentage =
              _currentDuration.toDouble() / _totalDuration.toDouble();
        });
      });
    } else {
      audioPlayer.pause();
      setState(() {
        _selectedIndex = index;
        _completedPercentage = 0.0;
        playBtn = Icons.play_arrow;
        _isPlaying = false;
      });
    }
  }

  Widget slider({@required String filePath, @required int second}) {
    return Slider(
        activeColor: Colors.black38,
        inactiveColor: Colors.grey,
        value: _position.inSeconds.toDouble(),
        min: 0.0,
        max: _duration.inSeconds.toDouble(),
        onChanged: (double value) {
          setState(() {
            seekToSecond(value.toInt());
            value = value;
          });
        });
  }

  void seekToSecond(int second) {
    Duration newDuration = Duration(seconds: second);

    audioPlayer.seek(newDuration);
  }


  String _getDateFromFilePath({@required String filePath}) {
    String fromEpoch = filePath.substring(
        filePath.lastIndexOf('/') + 1, filePath.lastIndexOf('.'));

    DateTime recordedDate =
    DateTime.fromMillisecondsSinceEpoch(int.parse(fromEpoch));
    int year = recordedDate.year;
    int month = recordedDate.month;
    int day = recordedDate.day;
    int hour = recordedDate.hour;
    int minute = recordedDate.minute;
    int second = recordedDate.second;

    return ('$year/$month/$day $hour:$minute:$second');
  }
}
