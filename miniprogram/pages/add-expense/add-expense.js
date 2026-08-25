const api = require('../../utils/api');
const config = require('../../utils/config');
const format = require('../../utils/format');
const store = require('../../utils/store');

function toast(title) {
  wx.showToast({ title, icon: 'none' });
}

Page({
  data: {
    id: '',
    title: '',
    amount: '',
    category: '食品',
    categories: config.CATEGORIES,
    members: [],
    memberNames: [],
    payerIndex: -1,
    payerName: '',
    payerId: '',
    dateKey: format.dateKey(new Date()),
    dateText: format.fullDate(format.dateKey(new Date())),
    saving: false,
    loading: false
  },

  onLoad(options) {
    this.setData({ id: options.id || '' });
    if (options.id) {
      wx.setNavigationBarTitle({ title: '编辑支出' });
    }
    this.init();
  },

  async init() {
    const session = store.store.session;
    const dormitory = store.store.currentDormitory;
    if (!session || !session.access_token) {
      wx.reLaunch({ url: '/pages/login/login' });
      return;
    }
    if (!dormitory) {
      toast('请先加入宿舍');
      setTimeout(() => wx.navigateBack(), 600);
      return;
    }
    this.setData({ loading: true });
    try {
      await this.loadMembers();
      if (this.data.id) await this.loadExpense();
    } catch (error) {
      toast(error.message || '加载失败');
    } finally {
      this.setData({ loading: false });
    }
  },

  async loadMembers() {
    const dormitory = store.store.currentDormitory;
    const members = await api.dorm.getMembers(dormitory.id);
    store.store.members = members;
    const memberNames = members.map((item) => item.username);
    const session = store.store.session;
    let index = members.findIndex((item) => item.userId === session.user.id);
    if (index < 0) index = 0;
    const payerId = members[index] ? members[index].userId : '';
    this.setData({
      members,
      memberNames,
      payerIndex: index,
      payerId,
      payerName: memberNames[index] || ''
    });
  },

  async loadExpense() {
    const dormitory = store.store.currentDormitory;
    const all = await api.expense.listAll(dormitory.id);
    const expense = all.find((item) => item.id === this.data.id);
    if (!expense) {
      toast('未找到这笔支出');
      setTimeout(() => wx.navigateBack(), 600);
      return;
    }
    const dateKey = expense.expense_date || String(expense.created_at).slice(0, 10);
    const index = this.data.members.findIndex(
      (item) => item.userId === expense.payer_id
    );
    this.setData({
      title: expense.title,
      amount: String(expense.amount),
      category: expense.category,
      dateKey,
      dateText: format.fullDate(dateKey),
      payerIndex: index >= 0 ? index : this.data.payerIndex,
      payerId: expense.payer_id,
      payerName: index >= 0 ? this.data.memberNames[index] : '成员'
    });
  },

  onTitleInput(event) {
    this.setData({ title: event.detail.value });
  },

  onAmountInput(event) {
    this.setData({ amount: event.detail.value });
  },

  onCategoryTap(event) {
    this.setData({ category: event.currentTarget.dataset.category });
  },

  onPayerChange(event) {
    const index = Number(event.detail.value);
    const member = this.data.members[index];
    this.setData({
      payerIndex: index,
      payerId: member ? member.userId : '',
      payerName: member ? member.username : ''
    });
  },

  onDateChange(event) {
    const dateKey = event.detail.value;
    this.setData({
      dateKey,
      dateText: format.fullDate(dateKey)
    });
  },

  async handleSave() {
    const title = this.data.title.trim();
    const amount = Number(this.data.amount);
    const session = store.store.session;
    const dormitory = store.store.currentDormitory;
    if (!title) {
      toast('请输入支出名称');
      return;
    }
    if (!this.data.amount || Number.isNaN(amount) || amount <= 0) {
      toast('请输入正确的金额');
      return;
    }
    if (!this.data.payerId) {
      toast('请选择代付人');
      return;
    }

    this.setData({ saving: true });
    try {
      const payload = {
        title,
        amount,
        category: this.data.category,
        payerId: this.data.payerId,
        dateKey: this.data.dateKey
      };
      if (this.data.id) {
        await api.expense.update(this.data.id, payload);
        toast('已保存');
      } else {
        await api.expense.add(
          Object.assign({}, payload, {
            dormitoryId: dormitory.id,
            creatorId: session.user.id
          })
        );
        toast('已添加');
      }
      setTimeout(() => wx.navigateBack(), 500);
    } catch (error) {
      toast(error.message || '保存失败');
    } finally {
      this.setData({ saving: false });
    }
  },

  handleDelete() {
    wx.showModal({
      title: '删除支出',
      content: '确定删除这笔支出吗？',
      confirmColor: '#D9534F',
      success: async (result) => {
        if (!result.confirm) return;
        try {
          await api.expense.remove(this.data.id);
          toast('已删除');
          setTimeout(() => wx.navigateBack(), 500);
        } catch (error) {
          toast(error.message || '删除失败');
        }
      }
    });
  }
});
