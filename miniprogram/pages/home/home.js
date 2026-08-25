const api = require('../../utils/api');
const format = require('../../utils/format');
const store = require('../../utils/store');

const PAGE_SIZE = 50;

function expenseDateOf(expense) {
  if (expense.expense_date) return expense.expense_date;
  if (expense.created_at) return String(expense.created_at).slice(0, 10);
  return '';
}

function toast(title) {
  wx.showToast({ title, icon: 'none' });
}

Page({
  data: {
    session: null,
    dormitory: null,
    members: [],
    memberMap: {},
    expenses: [],
    monthTotal: '¥0.00',
    expenseCount: 0,
    loading: true,
    loadingMore: false,
    hasMore: true,
    page: 0
  },

  onShow() {
    const session = store.store.session;
    if (!session || !session.access_token) {
      wx.reLaunch({ url: '/pages/login/login' });
      return;
    }
    this.setData({ session });
    this.refreshAll();
  },

  async refreshAll() {
    this.setData({ loading: true });
    try {
      await this.loadDormitories();
      if (!this.data.dormitory) {
        this.setData({ loading: false });
        return;
      }
      await Promise.all([
        this.loadMembers(),
        this.loadMonthSummary(),
        this.loadExpenses(true)
      ]);
    } catch (error) {
      toast(error.message || '加载失败，请稍后重试');
    } finally {
      this.setData({ loading: false });
      wx.stopPullDownRefresh();
    }
  },

  async loadDormitories() {
    const dorms = await api.dorm.listMyDormitories();
    store.store.dormitories = dorms;
    let current = store.store.currentDormitory;
    if (!current || !dorms.some((item) => item.id === current.id)) {
      current = dorms.length ? dorms[0] : null;
      store.store.currentDormitory = current;
    }
    this.setData({ dormitory: current });
  },

  async loadMembers() {
    const dormitory = this.data.dormitory;
    if (!dormitory) return;
    const members = await api.dorm.getMembers(dormitory.id);
    const memberMap = {};
    members.forEach((member) => {
      memberMap[member.userId] = member.username;
    });
    store.store.members = members;
    this.setData({ members, memberMap });
  },

  async loadMonthSummary() {
    const dormitory = this.data.dormitory;
    if (!dormitory) return;
    const currentMonth = format.monthKey(new Date());
    try {
      const rows = await api.expense.listByMonth(dormitory.id, currentMonth);
      const cents = rows.reduce(
        (sum, item) => sum + Math.round(Number(item.amount || 0) * 100),
        0
      );
      this.setData({
        monthTotal: format.money(cents / 100),
        expenseCount: rows.length
      });
    } catch (error) {
      const all = await api.expense.listAll(dormitory.id);
      const rows = all.filter(
        (item) => String(expenseDateOf(item)).slice(0, 7) === currentMonth
      );
      const cents = rows.reduce(
        (sum, item) => sum + Math.round(Number(item.amount || 0) * 100),
        0
      );
      this.setData({
        monthTotal: format.money(cents / 100),
        expenseCount: rows.length
      });
    }
  },

  decorateExpenses(rows) {
    const memberMap = this.data.memberMap;
    const expenses = rows.map((item) => {
      const dateKey = expenseDateOf(item);
      const style = format.categoryStyle(item.category);
      const payerName = memberMap[item.payer_id] || '成员';
      return Object.assign({}, item, {
        dateText: format.shortDate(dateKey),
        amountText: format.money(item.amount),
        payerName,
        categoryColor: style.color,
        categoryIcon: style.icon,
        dateKey
      });
    });
    return { expenses };
  },

  async loadExpenses(reset) {
    const dormitory = this.data.dormitory;
    if (!dormitory) return;
    const page = reset ? 0 : this.data.page;
    const rows = await api.expense.list(dormitory.id, page * PAGE_SIZE, PAGE_SIZE);
    const decorated = this.decorateExpenses(rows);
    this.setData({
      expenses: reset ? decorated.expenses : this.data.expenses.concat(decorated.expenses),
      page: page + 1,
      hasMore: rows.length === PAGE_SIZE,
      loadingMore: false
    });
  },

  onPullDownRefresh() {
    this.refreshAll();
  },

  onReachBottom() {
    if (!this.data.dormitory || !this.data.hasMore || this.data.loadingMore) return;
    this.setData({ loadingMore: true });
    this.loadExpenses(false).catch((error) => {
      toast(error.message || '加载失败');
      this.setData({ loadingMore: false });
    });
  },

  goAddExpense() {
    wx.navigateTo({ url: '/pages/add-expense/add-expense' });
  },

  goDormSetup() {
    wx.navigateTo({ url: '/pages/dorm-setup/dorm-setup' });
  },

  goSettlement() {
    wx.navigateTo({ url: '/pages/settlement/settlement' });
  },

  copyInviteCode() {
    const code = this.data.dormitory.invite_code || '';
    wx.setClipboardData({
      data: code,
      success: () => wx.showToast({ title: '邀请码已复制', icon: 'success' })
    });
  },

  onLongPressExpense(event) {
    const id = event.currentTarget.dataset.id;
    const expense = this.data.expenses.find((item) => item.id === id);
    if (!expense) return;
    wx.showActionSheet({
      itemList: ['编辑这笔支出', '删除这笔支出'],
      success: (result) => {
        if (result.tapIndex === 0) {
          wx.navigateTo({
            url: `/pages/add-expense/add-expense?id=${id}`
          });
        } else if (result.tapIndex === 1) {
          this.confirmDelete(expense);
        }
      }
    });
  },

  confirmDelete(expense) {
    wx.showModal({
      title: '删除支出',
      content: `确定删除「${expense.title}」吗？`,
      confirmColor: '#D9534F',
      success: async (result) => {
        if (!result.confirm) return;
        try {
          await api.expense.remove(expense.id);
          toast('已删除');
          this.refreshAll();
        } catch (error) {
          toast(error.message || '删除失败');
        }
      }
    });
  }
});
