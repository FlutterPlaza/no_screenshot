# no_screenshot

Flutter plugin to enable, disable or toggle screenshot support in your application.


## Features
  - Disables screenshot and screen recoding on Android and iOS
  - Enables screenshot and screen recoding on Android and iOS
  - Toggle screenshot and screen recoding on Android and iOS 
## Getting started

If you want to prevent user from taking screenshot or recording of your app. You can turn off the screenshot support from the root `didChangeAppLifecycleState` method. 


```dart 
    class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
    final _noScreenshot = NoScreenshot();

  AppLifecycleState? _notification; 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
      case AppLifecycleState.resumed, :
        print("app in resumed");
        if(app_secure) _noScreenshot.screenshotOff();
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        if(app_secure) _noScreenshot.screenshotOff();

        break;
      case AppLifecycleState.paused:
        print("app in paused");
        if(app_secure) _noScreenshot.screenshotOff();
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    ...
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
```

## Usage
Add `no_screenshot` to your `pubspec.yaml` dependencies

call the singleton `NoScreenshot.instance` anywhere you want to use it. 
For instance;

```dart 

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _noScreenshot = NoScreenshot.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              child: const Text('Press to toggle screenshot'),
              onPressed: () async {
                final result = await _noScreenshot.toggleScreenshot();
                print(result);
              },
            ),
            ElevatedButton(
              child: const Text('Press to turn off screenshot'),
              onPressed: () async {
                final result = await _noScreenshot.screenshotOff();
                print(result);
              },
            ),
            ElevatedButton(
              child: const Text('Press to turn on screenshot'),
              onPressed: () async {
                final result = await _noScreenshot.screenshotOn();
                print(result);
              },
            ),
          ],
        )),
      ),
    );
  }
}
```

## Additional information

check out our repo for Open-Source contribution contributions
