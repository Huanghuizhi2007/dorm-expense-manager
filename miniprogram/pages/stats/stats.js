const api = require('../../utils/api');
const format = require('../../utils/format');
const store = require('../../utils/store');

function dateKeyOf(expense) {
  return expense.expense_date || String(expense.created_at || '').slice(0, 10);
}

function percent(value) {
  const text = value.toFixed(1);
  return text.replace(/\.0$/, '');
}

Page({
  data: {
    year: 0,
    month: 0,
    monthKey: '',
    monthLabel: '',
    loading: false,
    hasDorm: false,
    totalText: '¥0.00',
    count: 0,
    members: [],
    categoryStats: [],
    ranking: [],
    donutStyle: '',
    myPaidText: '¥0.00',
    myShareText: '¥0.00',
    myBalanceText: '¥0.00',
    myBalancePositive: true
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
    this.loadStats(year, month);
  },

  async loadStats(year, month) {
    const dormitory = store.store.currentDormitory;
    const monthKey = format.monthKey(new Date(year, month - 1, 1));
    this.setData({
      year,
      month,
      monthKey,
      monthLabel: `${year}年${month}月`,
      loading: true
    });
    if (!dormitory) {
      this.setData({ loading: false });
      return;
    }
    try {
      const [rows, members] = await Promise.all([
        api.expense.listByMonth(dormitory.id, monthKey),
        store.store.members && store.store.members.length
          ? Promise.resolve(store.store.members)
          : api.dorm.getMembers(dormitory.id)
      ]);
      this.memberMap = {};
      members.forEach((member) => {
        this.memberMap[member.userId] = member.username;
      });
      this.setData(this.buildStats(rows, members));
    } catch (error) {
      wx.showToast({ title: error.message || '加载失败', icon: 'none' });
    } finally {
      this.setData({ loading: false });
    }
  },

  buildStats(rows, members) {
    const monthExpenses = rows.filter(
      (item) => String(dateKeyOf(item)).slice(0, 7) === this.data.monthKey
    );
    const categoryCents = {};
    const payerCents = {};
    let totalCents = 0;
    monthExpenses.forEach((item) => {
      const cents = Math.round(Number(item.amount || 0) * 100);
      totalCents += cents;
      categoryCents[item.category || '其他'] =
        (categoryCents[item.category || '其他'] || 0) + cents;
      payerCents[item.payer_id] = (payerCents[item.payer_id] || 0) + cents;
    });

    const categoryStats = Object.keys(categoryCents)
      .map((name) => {
        const style = format.categoryStyle(name);
        return {
          name,
          cents: categoryCents[name],
          amountText: format.money(categoryCents[name] / 100),
          percent: totalCents ? percent((categoryCents[name] / totalCents) * 100) : 0,
          color: style.color,
          icon: style.icon
        };
      })
      .sort((a, b) => b.cents - a.cents);

    const donutParts = [];
    let cursor = 0;
    categoryStats.forEach((item) => {
      const ratio = totalCents ? item.cents / totalCents : 0;
      const start = cursor;
      cursor += ratio * 100;
      donutParts.push(`${item.color} ${start}% ${cursor}%`);
    });

    const ranking = Object.keys(payerCents)
      .map((userId) => ({
        userId,
        name: this.memberMap[userId] || '成员',
        cents: payerCents[userId],
        amountText: format.money(payerCents[userId] / 100)
      }))
      .sort((a, b) => b.cents - a.cents)
      .map((item, index) =>
        Object.assign({}, item, { rank: index + 1 })
      );

    const session = store.store.session;
    const myId = session && session.user ? session.user.id : '';
    const myPaidCents = payerCents[myId] || 0;
    const shareCents = members.length
      ? Math.round((totalCents / members.length) * 100) / 100
      : 0;
    const balanceCents = Math.round((myPaidCents - shareCents) * 100) / 100;

    return {
      totalText: format.money(totalCents / 100),
      count: monthExpenses.length,
      members,
      categoryStats,
      donutStyle: donutParts.length
        ? `conic-gradient(${donutParts.join(',')})`
        : 'conic-gradient(#e2e8f0 0% 100%)',
      ranking,
      myPaidText: format.money(myPaidCents / 100),
      myShareText: format.money(shareCents / 100),
      myBalanceText: `${balanceCents >= 0 ? '+' : '-'}${format.money(Math.abs(balanceCents) / 100)}`,
      myBalancePositive: balanceCents >= 0
    };
  },

  previousMonth() {
    const previous = new Date(this.data.year, this.data.month - 2, 1);
    this.loadStats(previous.getFullYear(), previous.getMonth() + 1);
  },

  nextMonth() {
    const next = new Date(this.data.year, this.data.month, 1);
    this.loadStats(next.getFullYear(), next.getMonth() + 1);
  },

  onMonthChange(event) {
    const parts = event.detail.value.split('-').map(Number);
    this.loadStats(parts[0], parts[1]);
  },

  goDormSetup() {
    wx.navigateTo({ url: '/pages/dorm-setup/dorm-setup' });
  }
});
