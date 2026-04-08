(function () {
  const config = {
    downloadUrl: "https://github.com/rubybear-lgtm/posture-check/releases/latest/download/PostureCheck-macOS.zip",
    showDownloadNote: false
  };

  const links = [
    document.getElementById("download-link"),
    document.getElementById("download-link-footer")
  ];

  for (const link of links) {
    if (!link) continue;
    link.href = config.downloadUrl;
  }

  const note = document.getElementById("download-note");
  if (note && !config.showDownloadNote) {
    note.hidden = true;
  }
})();
