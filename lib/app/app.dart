import 'package:flutter/material.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/app/widgets/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter_application_1/core/utils.dart';

class PetApp extends StatefulWidget {
  const PetApp({super.key});

  @override
  State<PetApp> createState() => _PetAppState();
}

class _PetAppState extends State<PetApp> {
  late final String url;

  late final Uri uri;
  late final WebSocketChannel channel;
  late ImageStreamConverter streamConverter;

  late final Uri uriState;
  late final WebSocketChannel channelState;

  late final Uri uriData;
  late final WebSocketChannel channelData;

  late final Uri uriPhoto;
  late final WebSocketChannel channelPhoto;
  late ImageStreamConverter photoStreamConverter;

  late final ValueNotifier<bool> isOnBoardVideo1On;
  late final ValueNotifier<bool> isOnBoardLed1On;

  late final CarouselController _carouselController = CarouselController();
  late final List<Image> _images = [];

  @override
  void initState() {
    super.initState();
    url = const String.fromEnvironment(
      'URL',
      defaultValue: "viaduct.proxy.rlwy.net:44691",
    );
    uri = Uri.parse('ws://$url/image_ws');
    channel = WebSocketChannel.connect(uri);

    uriState = Uri.parse('ws://$url/ws');
    channelState = WebSocketChannel.connect(uriState);

    uriData = Uri.parse('ws://$url/data_ws');
    channelData = WebSocketChannel.connect(uriData);

    uriPhoto = Uri.parse('ws://$url/photo_ws');
    channelPhoto = WebSocketChannel.connect(uriPhoto);

    streamConverter = ImageStreamConverter(channel.stream);
    photoStreamConverter = ImageStreamConverter(channelPhoto.stream);

    isOnBoardVideo1On = ValueNotifier<bool>(false);
    isOnBoardLed1On = ValueNotifier<bool>(false);

    initVideoFromSocket();
  }

  @override
  void dispose() {
    channel.sink.close();
    channelPhoto.sink.close();
    channelState.sink.close();
    channelData.sink.close();
    isOnBoardLed1On.dispose();
    isOnBoardVideo1On.dispose();
    streamConverter.imageStream.drain();
    photoStreamConverter.imageStream.drain();
    super.dispose();
  }

  void _enableVideo() {
    channelState.sink.add("ON_BOARD_VIDEO_1=1");
  }

  void _disableVideo() {
    channelState.sink.add("ON_BOARD_VIDEO_1=0");
  }

  void _enableLed() {
    channelState.sink.add("ON_BOARD_LED_1=1");
  }

  void _disableLed() {
    channelState.sink.add("ON_BOARD_LED_1=0");
  }

  void initVideoFromSocket() {
    channelState.stream.listen((event) {
      if (event == "ON_BOARD_VIDEO_1=1") {
        isOnBoardVideo1On.value = true;
      } else if (event == "ON_BOARD_VIDEO_1=0") {
        isOnBoardVideo1On.value = false;
      } else if (event == "ON_BOARD_LED_1=1") {
        isOnBoardLed1On.value = true;
      } else if (event == "ON_BOARD_LED_1=0") {
        isOnBoardLed1On.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green,
        title: const Text(
          'Smart Pet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      backgroundColor: Colors.green[300],
      persistentFooterAlignment: AlignmentDirectional.bottomCenter,
      persistentFooterButtons: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (isOnBoardVideo1On.value) {
                  _disableVideo();
                } else {
                  _enableVideo();
                }
                isOnBoardVideo1On.value = !isOnBoardVideo1On.value;
              },
              child: ValueListenableBuilder(
                valueListenable: isOnBoardVideo1On,
                builder: (context, value, child) {
                  if (value) {
                    return const Text('Apagar video');
                  }
                  return const Text('Encender video');
                },
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                if (isOnBoardLed1On.value) {
                  _disableLed();
                } else {
                  _enableLed();
                }
                isOnBoardLed1On.value = !isOnBoardLed1On.value;
              },
              child: ValueListenableBuilder(
                valueListenable: isOnBoardLed1On,
                builder: (context, value, child) {
                  if (value) {
                    return const Text('Dispersar comida');
                  }
                  return const Text('Dispersar comida');
                },
              ),
            ),
          ],
        )
      ],
      body: Center(
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            const Center(
              child: Text(
                'Ultimas fotos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PhotoAlbum(
              photoStreamConverter: photoStreamConverter,
              images: _images,
              carouselController: _carouselController,
            ),
            const SizedBox(height: 20),
            _LiveVideo(
              isOnBoardVideo1On: isOnBoardVideo1On,
              streamConverter: streamConverter,
            ),
            const SizedBox(height: 20),
            _InfoRow(
              channelData: channelData,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.channelData,
  });

  final WebSocketChannel channelData;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: channelData.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data.toString().split(";");
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InfoCard(
                title: 'Nivel de comida',
                value: '${convertValue(data[1])}%',
                color: Colors.green,
                icon: Icons.food_bank,
              ),
              const SizedBox(width: 8),
              InfoCard(
                title: 'Temperatura',
                value: '${data[2]}°C',
                color: Colors.green,
                icon: Icons.thermostat,
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _LiveVideo extends StatelessWidget {
  const _LiveVideo({
    required this.isOnBoardVideo1On,
    required this.streamConverter,
  });

  final ValueNotifier<bool> isOnBoardVideo1On;
  final ImageStreamConverter streamConverter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isOnBoardVideo1On,
      builder: (context, value, child) {
        if (value) {
          return AnimatedOpacity(
            opacity: value ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  color: Colors.black,
                  height: 240,
                  width: 240,
                  child: Center(
                    child: StreamBuilder<Image>(
                      stream: streamConverter.imageStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return snapshot.data!.animate().flip(
                                duration: const Duration(
                                  milliseconds: 500,
                                ),
                              );
                        }

                        return const CircularProgressIndicator.adaptive();
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 100,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox(
            width: 240,
            height: 240,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Enciende el video para ver a tu mascota en vivo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _PhotoAlbum extends StatelessWidget {
  const _PhotoAlbum({
    required this.photoStreamConverter,
    required List<Image> images,
    required CarouselController carouselController,
  })  : _images = images,
        _carouselController = carouselController;

  final ImageStreamConverter photoStreamConverter;
  final List<Image> _images;
  final CarouselController _carouselController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Container(
          color: Colors.black,
          height: 240,
          width: 240,
          child: Center(
            child: StreamBuilder<Image>(
              stream: photoStreamConverter.imageStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  _images.add(snapshot.data!);
                }

                final images = _images.reversed.toList();

                return CarouselSlider(
                  carouselController: _carouselController,
                  options: CarouselOptions(enableInfiniteScroll: false),
                  items: images,
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 100,
          right: 10,
          child: ElevatedButton(
            onPressed: () {
              _carouselController.nextPage();
            },
            child: const Icon(Icons.arrow_forward_ios),
          ),
        ),
        Positioned(
          top: 100,
          left: 10,
          child: ElevatedButton(
            onPressed: () {
              _carouselController.previousPage();
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
        ),
      ],
    );
  }
}

int convertValue(String value) {
  return double.parse(value) * 100 ~/ 21;
}
