const api = require('../../utils/api');
const format = require('../../utils/format');
const settlementUtil = require('../../utils/settlement');
const store = require('../../utils/store');

Page({
  data: {
    year: 0,
    month: 0,
    monthKey: '',
    monthLabel: '',
    loading: false,
    generating: false,
    hasDorm: false,
    entries: [],
    transfers: [],
    totalText: '¥0.00',
    count: 0
  },

  onShow() {
    const session = store.store.session;
    const dormitory = store.store.currentDormitory;
    if (!session || !session.access_token) {
      wx.reLaunch({ url: '/pages/login/login' });
      return;
    }
    const now = new Date();
    const year = this.data.year || now.getFullYear();
    const month = this.data.month || now.getMonth() + 1;
    this.setData({ hasDorm: Boolean(dormitory) });
    this.loadMonth(year, month);
  },

  async loadMonth(year, month) {
    const monthKey = format.monthKey(new Date(year, month - 1, 1));
    this.setData({
      year,
      month,
      monthKey,
      monthLabel: `${year}年${month}月`
    });
    await this.loadMembers();
    await this.loadExisting();
  },

  async loadMembers() {
    const dormitory = store.store.currentDormitory;
    if (!dormitory) return;
    try {
      const members =
        store.store.members && store.store.members.length
          ? store.store.members
          : await api.dorm.getMembers(dormitory.id);
      this.memberMap = {};
      members.forEach((member) => {
        this.memberMap[member.userId] = member.username;
      });
    } catch (error) {
      this.memberMap = {};
    }
  },

  async loadExisting() {
    const dormitory = store.store.currentDormitory;
    if (!dormitory) return;
    try {
      const rows = await api.settlement.fetch(
        dormitory.id,
        this.data.monthKey
      );
      this.setData(this.decorate(rows));
    } catch (error) {
      wx.showToast({ title: error.message || '加载失败', icon: 'none' });
    }
  },

  decorate(rows) {
    const entries = rows.map((row) => {
      const balance = Number(row.balance || 0);
      const username = this.memberMap[row.user_id] || '成员';
      const paid = row.paid_amount !== undefined ? row.paid_amount : row.paid;
      const share = row.share_amount !== undefined ? row.share_amount : row.share;
      return Object.assign({}, row, {
        username,
        initial: username.slice(0, 1),
        paidText: format.money(paid),
        shareText: format.money(share),
        balanceText: format.money(Math.abs(balance)),
        balance
      });
    });
    const transfers = settlementUtil
      .computeTransfers(entries)
      .map((item, index) =>
        Object.assign({}, item, {
          amountText: format.money(item.amount),
          index
        })
      );
    const total = entries.reduce(
      (sum, item) => sum + Math.round(Number(item.paid_amount || 0) * 100),
      0
    );
    return {
      entries,
      transfers,
      totalText: format.money(total / 100),
      count: 0
    };
  },

  async generateSettlement() {
    const dormitory = store.store.currentDormitory;
    if (!dormitory) return;
    this.setData({ generating: true });
    try {
      const rows = await api.settlement.generate(
        dormitory.id,
        this.data.monthKey
      );
      rows.forEach((row) => {
        this.memberMap[row.user_id] = row.username;
      });
      this.setData(this.decorate(rows));
      wx.showToast({ title: '结算已生成', icon: 'success' });
    } catch (error) {
      wx.showToast({ title: error.message || '生成失败', icon: 'none' });
    } finally {
      this.setData({ generating: false });
    }
  },

  previousMonth() {
    const previous = new Date(this.data.year, this.data.month - 2, 1);
    this.loadMonth(previous.getFullYear(), previous.getMonth() + 1);
  },

  nextMonth() {
    const next = new Date(this.data.year, this.data.month, 1);
    this.loadMonth(next.getFullYear(), next.getMonth() + 1);
  },

  onMonthChange(event) {
    const parts = event.detail.value.split('-').map(Number);
    this.loadMonth(parts[0], parts[1]);
  },

  goDormSetup() {
    wx.navigateTo({ url: '/pages/dorm-setup/dorm-setup' });
  }
});
