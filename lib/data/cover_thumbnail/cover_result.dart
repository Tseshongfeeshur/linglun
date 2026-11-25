import 'dart:io';

sealed class CoverResult {}

class CoverFound extends CoverResult {
  final File file;
  new(this.file);
}

class CoverNone extends CoverResult {}

class CoverFailed extends CoverResult {}
