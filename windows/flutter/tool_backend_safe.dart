import 'dart:io';

Future<void> main(List<String> arguments) async {
  final targetPlatform = arguments[0];
  final buildMode = arguments[1].toLowerCase();

  final dartDefines = Platform.environment['DART_DEFINES'];
  final dartObfuscation = Platform.environment['DART_OBFUSCATION'] == 'true';
  final frontendServerStarterPath =
      Platform.environment['FRONTEND_SERVER_STARTER_PATH'];
  final extraFrontEndOptions = Platform.environment['EXTRA_FRONT_END_OPTIONS'];
  final extraGenSnapshotOptions =
      Platform.environment['EXTRA_GEN_SNAPSHOT_OPTIONS'];
  final flutterEngine = Platform.environment['FLUTTER_ENGINE'];
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterTarget =
      Platform.environment['FLUTTER_TARGET'] ??
      _pathJoin(<String>['lib', 'main.dart']);
  final codeSizeDirectory = Platform.environment['CODE_SIZE_DIRECTORY'];
  final localEngine = Platform.environment['LOCAL_ENGINE'];
  final localEngineHost = Platform.environment['LOCAL_ENGINE_HOST'];
  final projectDirectory = Platform.environment['PROJECT_DIR'];
  final splitDebugInfo = Platform.environment['SPLIT_DEBUG_INFO'];
  final trackWidgetCreation =
      Platform.environment['TRACK_WIDGET_CREATION'] == 'true';
  final treeShakeIcons = Platform.environment['TREE_SHAKE_ICONS'] == 'true';
  final verbose = Platform.environment['VERBOSE_SCRIPT_LOGGING'] == 'true';
  final prefixedErrors =
      Platform.environment['PREFIXED_ERROR_LOGGING'] == 'true';

  if (projectDirectory == null) {
    stderr.write(
      'PROJECT_DIR environment variable must be set to the location of Flutter project to be built.',
    );
    exit(1);
  }
  if (flutterRoot == null || flutterRoot.isEmpty) {
    stderr.write(
      'FLUTTER_ROOT environment variable must be set to the location of the Flutter SDK.',
    );
    exit(1);
  }

  Directory.current = projectDirectory;

  if (localEngine != null && !localEngine.contains(buildMode)) {
    stderr.write('Requested local engine is not compatible with build mode.');
    exit(1);
  }
  if (localEngineHost != null && !localEngineHost.contains(buildMode)) {
    stderr.write(
      'Requested local engine host is not compatible with build mode.',
    );
    exit(1);
  }

  final flutterExecutable = _pathJoin(<String>[
    flutterRoot,
    'bin',
    if (Platform.isWindows) 'flutter.bat' else 'flutter',
  ]);
  final target = '${buildMode}_bundle_${targetPlatform}_assets';

  final assembleArgs = <String>[
    if (verbose) '--verbose',
    if (prefixedErrors) '--prefixed-errors',
    if (flutterEngine != null) '--local-engine-src-path=$flutterEngine',
    if (localEngine != null) '--local-engine=$localEngine',
    if (localEngineHost != null) '--local-engine-host=$localEngineHost',
    'assemble',
    '--no-version-check',
    '--output=build',
    '-dTargetPlatform=$targetPlatform',
    '-dTrackWidgetCreation=$trackWidgetCreation',
    '-dBuildMode=$buildMode',
    '-dTargetFile=$flutterTarget',
    '-dTreeShakeIcons="$treeShakeIcons"',
    '-dDartObfuscation=$dartObfuscation',
    if (codeSizeDirectory != null) '-dCodeSizeDirectory=$codeSizeDirectory',
    if (splitDebugInfo != null) '-dSplitDebugInfo=$splitDebugInfo',
    if (dartDefines != null) '--DartDefines=$dartDefines',
    if (extraGenSnapshotOptions != null)
      '--ExtraGenSnapshotOptions=$extraGenSnapshotOptions',
    if (frontendServerStarterPath != null)
      '-dFrontendServerStarterPath=$frontendServerStarterPath',
    if (extraFrontEndOptions != null)
      '--ExtraFrontEndOptions=$extraFrontEndOptions',
    target,
  ];

  final assembleProcess = await Process.start(
    Platform.isWindows ? 'cmd.exe' : flutterExecutable,
    Platform.isWindows
        ? <String>['/d', '/c', 'call', flutterExecutable, ...assembleArgs]
        : assembleArgs,
  );

  final stdoutDone = stdout.addStream(assembleProcess.stdout);
  final stderrDone = stderr.addStream(assembleProcess.stderr);
  final exitCode = await assembleProcess.exitCode;
  await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);

  if (exitCode != 0) {
    exit(exitCode);
  }
}

String _pathJoin(List<String> segments) {
  final separator = Platform.isWindows ? r'\' : '/';
  return segments.join(separator);
}
