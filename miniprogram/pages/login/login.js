const api = require('../../utils/api');
const config = require('../../utils/config');
const store = require('../../utils/store');

function toast(title) {
  wx.showToast({ title, icon: 'none' });
}

Page({
  data: {
    email: '',
    password: '',
    loading: false,
    wechatLoading: false
  },

  onShow() {
    if (store.store.session && store.store.session.access_token) {
      wx.reLaunch({ url: '/pages/home/home' });
    }
  },

  onEmailInput(event) {
    this.setData({ email: event.detail.value });
  },

  onPasswordInput(event) {
    this.setData({ password: event.detail.value });
  },

  async handleLogin() {
    const email = this.data.email.trim();
    const password = this.data.password;
    if (!email || !password) {
      toast('请输入邮箱和密码');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      toast('邮箱格式不正确');
      return;
    }
    this.setData({ loading: true });
    try {
      const session = await api.auth.signIn(email, password);
      store.setSession(session);
      await this.loadProfile(session.user.id);
      wx.reLaunch({ url: '/pages/home/home' });
    } catch (error) {
      toast(this.friendlyMessage(error.message));
    } finally {
      this.setData({ loading: false });
    }
  },

  async loadProfile(userId) {
    try {
      const profile = await api.auth.fetchProfile(userId);
      store.store.profile = profile;
    } catch (error) {
      // 首页会再次拉取资料，这里失败不阻塞登录。
    }
  },

  friendlyMessage(message) {
    const text = String(message || '');
    if (text.indexOf('Invalid login credentials') >= 0) return '邮箱或密码不正确';
    if (text.indexOf('Email not confirmed') >= 0) return '邮箱尚未验证，请先查收验证邮件';
    return text || '登录失败，请稍后重试';
  },

  handleWechatLogin() {
    this.setData({ wechatLoading: true });
    wx.login({
      success: (loginResult) => {
        if (!loginResult.code) {
          this.wechatFailed();
          return;
        }
        wx.request({
          url: config.WECHAT_LOGIN_URL,
          method: 'POST',
          header: { 'Content-Type': 'application/json' },
          data: { code: loginResult.code },
          success: (response) => {
            if (
              response.statusCode === 200 &&
              response.data &&
              response.data.access_token
            ) {
              store.setSession(response.data);
              this.loadProfile(response.data.user.id).then(() => {
                wx.reLaunch({ url: '/pages/home/home' });
              });
            } else {
              this.wechatFailed();
            }
          },
          fail: () => this.wechatFailed()
        });
      },
      fail: () => this.wechatFailed()
    });
  },

  wechatFailed() {
    this.setData({ wechatLoading: false });
    wx.showModal({
      title: '微信登录暂不可用',
      content: '需要在 Supabase 配置微信 AppID 和 AppSecret，或先使用邮箱登录。',
      showCancel: false
    });
  },

  goRegister() {
    wx.navigateTo({ url: '/pages/register/register' });
  }
});
