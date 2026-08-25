const api = require('../../utils/api');
const store = require('../../utils/store');

function toast(title) {
  wx.showToast({ title, icon: 'none' });
}

Page({
  data: {
    profile: {},
    email: '',
    avatarInitial: 'OB',
    dorms: [],
    currentDormId: ''
  },

  onShow() {
    const session = store.store.session;
    if (!session || !session.access_token) {
      wx.reLaunch({ url: '/pages/login/login' });
      return;
    }
    this.loadProfile();
    this.loadDorms();
  },

  async loadProfile() {
    const session = store.store.session;
    try {
      const profile = store.store.profile ||
        await api.auth.fetchProfile(session.user.id);
      store.store.profile = profile;
      this.setData({
        profile,
        email: session.user.email || '',
        avatarInitial: (profile.username || 'OB').slice(0, 1).toUpperCase()
      });
    } catch (error) {
      toast(error.message || '加载资料失败');
    }
  },

  async loadDorms() {
    try {
      const dorms = await api.dorm.listMyDormitories();
      store.store.dormitories = dorms;
      const current = store.store.currentDormitory;
      const currentId = current && dorms.some((item) => item.id === current.id)
        ? current.id
        : dorms.length
          ? dorms[0].id
          : '';
      this.setData({ dorms, currentDormId: currentId });
    } catch (error) {
      toast(error.message || '加载宿舍失败');
    }
  },

  switchDorm(event) {
    const id = event.currentTarget.dataset.id;
    const dorm = this.data.dorms.find((item) => item.id === id);
    if (!dorm) return;
    store.store.currentDormitory = dorm;
    this.setData({ currentDormId: id });
    toast('已切换到' + dorm.name);
  },

  editUsername() {
    const current = (this.data.profile.username || '').trim();
    wx.showModal({
      title: '修改昵称',
      editable: true,
      placeholderText: '请输入新昵称',
      content: current,
      success: async (result) => {
        if (!result.confirm) return;
        const username = (result.content || '').trim();
        if (!username) {
          toast('昵称不能为空');
          return;
        }
        try {
          const rows = await api.auth.updateProfile(
            store.store.session.user.id,
            { username }
          );
          const updated = (rows || [])[0] || {};
          store.store.profile = Object.assign(
            {},
            this.data.profile,
            updated,
            { username }
          );
          this.setData({
            profile: store.store.profile,
            avatarInitial: username.slice(0, 1).toUpperCase()
          });
          toast('昵称已更新');
        } catch (error) {
          toast(error.message || '修改失败');
        }
      }
    });
  },

  changeAvatar() {
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sourceType: ['album'],
      sizeType: ['compressed'],
      success: async (result) => {
        const file = result.tempFiles && result.tempFiles[0];
        if (!file) return;
        wx.showLoading({ title: '上传中...' });
        try {
          const url = await api.uploadAvatar(file.tempFilePath);
          await api.auth.updateProfile(store.store.session.user.id, {
            avatar_url: url
          });
          const profile = Object.assign({}, this.data.profile, {
            avatar_url: url
          });
          store.store.profile = profile;
          this.setData({ profile });
          wx.hideLoading();
          toast('头像已更新');
        } catch (error) {
          wx.hideLoading();
          toast(error.message || '头像上传失败');
        }
      }
    });
  },

  goDormSetup() {
    wx.navigateTo({ url: '/pages/dorm-setup/dorm-setup' });
  },

  goSettlement() {
    wx.navigateTo({ url: '/pages/settlement/settlement' });
  },

  goStats() {
    wx.switchTab({ url: '/pages/stats/stats' });
  },

  handleLogout() {
    wx.showModal({
      title: '退出登录',
      content: '确定退出当前账号吗？',
      confirmColor: '#D9534F',
      success: async (result) => {
        if (!result.confirm) return;
        await api.auth.signOut();
        store.store.profile = null;
        store.store.dormitories = [];
        store.store.currentDormitory = null;
        store.store.members = [];
        store.store.expenses = [];
        wx.reLaunch({ url: '/pages/login/login' });
      }
    });
  }
});
