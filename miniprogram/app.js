const store = require('./utils/store');

App({
  onLaunch() {
    const session = wx.getStorageSync('ourbills_session');
    if (session && session.access_token) {
      store.store.session = session;
    }
  },
  globalData: {
    appName: 'ourbills'
  }
});
