const config = require('./config');

function pad2(value) {
  return String(value).padStart(2, '0');
}

function money(value) {
  const num = Number(value || 0);
  return `¥${num.toFixed(2)}`;
}

function dateKey(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

function monthKey(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}`;
}

function monthLabel(key) {
  const parts = String(key).split('-');
  return `${parts[0]}年${Number(parts[1])}月`;
}

function parseDateKey(key) {
  const parts = String(key).split('-').map(Number);
  return new Date(parts[0], parts[1] - 1, parts[2]);
}

function shortDate(key) {
  const parts = String(key).split('-').map(Number);
  return `${parts[1]}月${parts[2]}日`;
}

function fullDate(key) {
  const parts = String(key).split('-').map(Number);
  return `${parts[0]}年${parts[1]}月${parts[2]}日`;
}

function categoryStyle(category) {
  const styles = {
    '食品': { color: '#E07A5F', icon: '🍜' },
    '日用品': { color: '#7A9E9F', icon: '🧻' },
    '电费': { color: '#F2A33C', icon: '⚡' },
    '水费': { color: '#4A90D9', icon: '💧' },
    '网络费': { color: '#6B7FD7', icon: '📶' },
    '维修费': { color: '#8D6E63', icon: '🔧' },
    '其他': { color: '#94A3B8', icon: '📦' }
  };
  return styles[category] || styles['其他'];
}

module.exports = {
  pad2,
  money,
  dateKey,
  monthKey,
  monthLabel,
  parseDateKey,
  shortDate,
  fullDate,
  categoryStyle,
  categories: config.CATEGORIES
};
