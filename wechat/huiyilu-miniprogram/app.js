App({
  onLaunch() {
    if (wx.cloud) {
      wx.cloud.init({
        env: '',            // 留空 = 默认环境；部署时可填具体环境 ID
        traceUser: true
      });
    }
  }
});
