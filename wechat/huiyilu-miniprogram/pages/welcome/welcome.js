Page({
  goSelf() {
    wx.navigateTo({ url: '/pages/chat/chat?mode=self' });
  },
  goChild() {
    wx.navigateTo({ url: '/pages/chat/chat?mode=child' });
  }
});
