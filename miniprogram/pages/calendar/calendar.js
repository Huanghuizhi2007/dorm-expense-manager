const api = require('../../utils/api');
const format = require('../../utils/format');
const store = require('../../utils/store');

function dateKeyOf(expense) {
  return expense.expense_date || String(expense.created_at || '').slice(0, 10);
}

Page({
  data: {
    year: 0,
    month: 0,
    monthLabel: '',
    weekdays: ['日', '一', '二', '三', '四', '五', '六'],
    cells: [],
    selectedDate: '',
    selectedDateLabel: '',
    dayExpenses: [],
    loading: false,
    hasDorm: false
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
    this.loadMonthWithMembers(year, month);
  },

  async loadMonth(year, month) {
    const dormitory = store.store.currentDormitory;
    this.setData({
      year,
      month,
      monthLabel: `${year}年${month}月`,
      loading: true,
      selectedDate: '',
      selectedDateLabel: '',
      dayExpenses: []
    });
    if (!dormitory) {
      this.setData({ loading: false });
      return;
    }
    try {
      const rows = await api.expense.listByMonth(
        dormitory.id,
        format.monthKey(new Date(year, month - 1, 1))
      );
      this.dayExpensesCache = rows || [];
      const expenseDates = new Set(rows.map(dateKeyOf));
      this.setData({
        cells: this.buildCells(year, month, expenseDates)
      });
    } catch (error) {
      wx.showToast({ title: error.message || '加载失败', icon: 'none' });
    } finally {
      this.setData({ loading: false });
    }
  },

  buildCells(year, month, expenseDates) {
    const firstWeekday = new Date(year, month - 1, 1).getDay();
    const daysInMonth = new Date(year, month, 0).getDate();
    const now = new Date();
    const cells = [];
    for (let index = 0; index < firstWeekday; index += 1) {
      cells.push({
        key: `blank-${index}`,
        isBlank: true,
        day: '',
        dateKey: ''
      });
    }
    for (let day = 1; day <= daysInMonth; day += 1) {
      const dateKey = format.dateKey(new Date(year, month - 1, day));
      cells.push({
        key: dateKey,
        day,
        dateKey,
        isBlank: false,
        hasExpense: expenseDates.has(dateKey),
        isToday:
          year === now.getFullYear() &&
          month === now.getMonth() + 1 &&
          day === now.getDate(),
        isSelected: false
      });
    }
    return cells;
  },

  previousMonth() {
    const year = this.data.year;
    const month = this.data.month;
    const previous = new Date(year, month - 2, 1);
    this.loadMonth(previous.getFullYear(), previous.getMonth() + 1);
  },

  nextMonth() {
    const year = this.data.year;
    const month = this.data.month;
    const next = new Date(year, month, 1);
    this.loadMonth(next.getFullYear(), next.getMonth() + 1);
  },

  backToToday() {
    const now = new Date();
    this.loadMonth(now.getFullYear(), now.getMonth() + 1).then(() => {
      const today = format.dateKey(now);
      this.selectDayByKey(today);
    });
  },

  selectDay(event) {
    const dateKey = event.currentTarget.dataset.date;
    this.selectDayByKey(dateKey);
  },

  selectDayByKey(dateKey) {
    if (!dateKey) return;
    const cells = this.data.cells.map((cell) =>
      Object.assign({}, cell, { isSelected: cell.dateKey === dateKey })
    );
    const dayExpenses = this.dayExpensesCache
      .filter((item) => dateKeyOf(item) === dateKey)
      .map((item) => {
        const style = format.categoryStyle(item.category);
        const memberMap = this.memberMap || {};
        return Object.assign({}, item, {
          amountText: format.money(item.amount),
          payerName: memberMap[item.payer_id] || '成员',
          categoryColor: style.color,
          categoryIcon: style.icon
        });
      });
    this.setData({
      cells,
      selectedDate: dateKey,
      selectedDateLabel: format.fullDate(dateKey),
      dayExpenses
    });
  },

  async loadMonthWithMembers(year, month) {
    const dormitory = store.store.currentDormitory;
    try {
      const members = store.store.members && store.store.members.length
        ? store.store.members
        : await api.dorm.getMembers(dormitory.id);
      this.memberMap = {};
      members.forEach((member) => {
        this.memberMap[member.userId] = member.username;
      });
    } catch (error) {
      // 成员名缺失时显示“成员”。
    }
    await this.loadMonth(year, month);
  },

  goDormSetup() {
    wx.navigateTo({ url: '/pages/dorm-setup/dorm-setup' });
  }
});
