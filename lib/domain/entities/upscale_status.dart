enum UpscaleStatus {
  queued('queued'),
  preparing('preparing'),
  extractingFrames('extracting_frames'),
  upscaling('upscaling'),
  encoding('encoding'),
  completed('completed'),
  failed('failed');

  const UpscaleStatus(this.wireValue);

  final String wireValue;

  static UpscaleStatus fromWireValue(String value) {
    return UpscaleStatus.values.firstWhere(
      (status) => status.wireValue == value,
      orElse: () => UpscaleStatus.queued,
    );
  }
}
