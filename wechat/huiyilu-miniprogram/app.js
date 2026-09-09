App({
  onLaunch() {
    if (wx.cloud) {
      wx.cloud.init({
        env: 'cloud1-d9ghre5sqc8a903fd',
        traceUser: true
      });
    }
  }
});
