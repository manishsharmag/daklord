enum DownloadStatus { queued, preparing, downloading, completed, failed }

extension DownloadStatusX on DownloadStatus {
  String get key => name;

  static DownloadStatus fromKey(String? key) {
    if (key == null) {
      return DownloadStatus.queued;
    }
    return DownloadStatus.values.firstWhere(
      (status) => status.name == key,
      orElse: () => DownloadStatus.queued,
    );
  }
}
