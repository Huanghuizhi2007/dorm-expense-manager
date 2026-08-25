const api = require('../../utils/api');
const store = require('../../utils/store');

function toast(title) {
  wx.showToast({ title, icon: 'none' });
}

Page({
  data: {
    mode: 'create',
    name: '',
    code: '',
    dorms: [],
    currentDormId: '',
    loading: false
  },

  onShow() {
    this.loadDorms();
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
      this.setData({
        dorms,
        currentDormId: currentId
      });
    } catch (error) {
      toast(error.message || '加载宿舍失败');
    }
  },

  switchMode(event) {
    this.setData({ mode: event.currentTarget.dataset.mode });
  },

  onNameInput(event) {
    this.setData({ name: event.detail.value });
  },

  onCodeInput(event) {
    this.setData({ code: event.detail.value });
  },

  switchDorm(event) {
    const id = event.currentTarget.dataset.id;
    const dorm = this.data.dorms.find((item) => item.id === id);
    if (!dorm) return;
    store.store.currentDormitory = dorm;
    this.setData({ currentDormId: id });
    toast('已切换宿舍');
  },

  async handleCreate() {
    const name = this.data.name.trim();
    if (!name) {
      toast('请输入宿舍名称');
      return;
    }
    this.setData({ loading: true });
    try {
      const dorm = await api.dorm.create(name);
      store.store.currentDormitory = dorm;
      this.setData({ name: '' });
      toast('宿舍创建成功');
      setTimeout(() => wx.navigateBack(), 500);
    } catch (error) {
      toast(error.message || '创建失败');
    } finally {
      this.setData({ loading: false });
    }
  },

  async handleJoin() {
    const code = this.data.code.trim().toUpperCase();
    if (!code) {
      toast('请输入邀请码');
      return;
    }
    this.setData({ loading: true });
    try {
      const dorm = await api.dorm.join(code);
      store.store.currentDormitory = dorm;
      this.setData({ code: '' });
      toast('加入成功');
      setTimeout(() => wx.navigateBack(), 500);
    } catch (error) {
      const message = String(error.message || '');
      toast(message.indexOf('INVITE_NOT_FOUND') >= 0 ? '邀请码不存在' : message);
    } finally {
      this.setData({ loading: false });
    }
  },

  handleDelete() {
    const dorm = this.data.dorms.find((item) => item.id === this.data.currentDormId);
    if (!dorm) return;
    wx.showModal({
      title: '删除宿舍',
      content: `确定删除「${dorm.name}」吗？此操作不可恢复。`,
      confirmColor: '#D9534F',
      success: async (result) => {
        if (!result.confirm) return;
        try {
          await api.dorm.deleteDormitory(dorm.id);
          if (
            store.store.currentDormitory &&
            store.store.currentDormitory.id === dorm.id
          ) {
            store.store.currentDormitory = null;
          }
          toast('宿舍已删除');
          this.loadDorms();
        } catch (error) {
          const message = String(error.message || '');
          toast(message.indexOf('NOT_DORMITORY_CREATOR') >= 0 ? '只有创建者可以删除宿舍' : message);
        }
      }
    });
  }
});
