const api = require('../../utils/api');
const store = require('../../utils/store');

function toast(title) {
  wx.showToast({ title, icon: 'none' });
}

Page({
  data: {
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
    loading: false
  },

  onUsernameInput(event) {
    this.setData({ username: event.detail.value });
  },

  onEmailInput(event) {
    this.setData({ email: event.detail.value });
  },

  onPasswordInput(event) {
    this.setData({ password: event.detail.value });
  },

  onConfirmPasswordInput(event) {
    this.setData({ confirmPassword: event.detail.value });
  },

  async handleRegister() {
    const username = this.data.username.trim();
    const email = this.data.email.trim();
    const password = this.data.password;
    if (!username) {
      toast('请输入昵称');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      toast('邮箱格式不正确');
      return;
    }
    if (password.length < 6) {
      toast('密码至少需要 6 位');
      return;
    }
    if (password !== this.data.confirmPassword) {
      toast('两次输入的密码不一致');
      return;
    }

    this.setData({ loading: true });
    try {
      const result = await api.auth.signUp({ username, email, password });
      if (result.session && result.session.access_token) {
        store.setSession(result.session);
        const profile = await api.auth.fetchProfile(result.session.user.id);
        store.store.profile = profile;
        wx.showToast({ title: '注册成功', icon: 'success' });
        setTimeout(() => {
          wx.reLaunch({ url: '/pages/home/home' });
        }, 500);
      } else {
        wx.showModal({
          title: '注册成功',
          content: '验证邮件已发送，请先到邮箱完成验证，再返回登录。',
          showCancel: false,
          success: () => wx.navigateBack()
        });
      }
    } catch (error) {
      const message = String(error.message || '');
      if (message.indexOf('already registered') >= 0) {
        toast('该邮箱已经注册，请直接登录');
      } else {
        toast(message || '注册失败，请稍后重试');
      }
    } finally {
      this.setData({ loading: false });
    }
  },

  goLogin() {
    wx.navigateBack();
  }
});
