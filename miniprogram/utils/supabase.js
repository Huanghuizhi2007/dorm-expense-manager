const config = require('./config');
const store = require('./store');

function getSession() {
  if (store.store.session && store.store.session.access_token) {
    return store.store.session;
  }
  const cached = wx.getStorageSync('ourbills_session');
  if (cached && cached.access_token) {
    store.store.session = cached;
    return cached;
  }
  return null;
}

function buildQuery(params) {
  if (!params) return '';
  const pairs = Array.isArray(params)
    ? params
    : Object.keys(params).map((key) => [key, params[key]]);
  const parts = pairs
    .filter((pair) => pair[1] !== undefined && pair[1] !== null)
    .map((pair) => `${encodeURIComponent(pair[0])}=${encodeURIComponent(pair[1])}`);
  return parts.length ? `?${parts.join('&')}` : '';
}

function extractMessage(data, statusCode) {
  if (!data) return `请求失败 (${statusCode})`;
  if (typeof data === 'string') return data;
  if (data.message) return data.message;
  if (data.error_description) return data.error_description;
  if (data.msg) return data.msg;
  if (data.error && typeof data.error === 'string') return data.error;
  if (data.code && data.details) return `${data.code}: ${data.details}`;
  return `请求失败 (${statusCode})`;
}

function isAuthPage() {
  const pages = getCurrentPages();
  const current = pages[pages.length - 1];
  const route = current ? current.route : '';
  return route === 'pages/login/login' || route === 'pages/register/register';
}

function request(method, path, options = {}) {
  return new Promise((resolve, reject) => {
    const session = getSession();
    const header = Object.assign(
      {
        apikey: config.SUPABASE_ANON_KEY,
        'Content-Type': 'application/json'
      },
      options.headers || {}
    );
    if (session && session.access_token) {
      header.Authorization = `Bearer ${session.access_token}`;
    }

    wx.request({
      url: `${config.SUPABASE_URL}${path}${buildQuery(options.params)}`,
      method,
      data: options.body,
      header,
      success(res) {
        if (res.statusCode === 401 && !isAuthPage()) {
          store.setSession(null);
          wx.reLaunch({ url: '/pages/login/login' });
          reject(new Error('登录已过期，请重新登录'));
          return;
        }
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(res.data);
          return;
        }
        reject(new Error(extractMessage(res.data, res.statusCode)));
      },
      fail(err) {
        const message =
          err.errMsg && err.errMsg.indexOf('timeout') >= 0
            ? '网络连接超时，请稍后重试'
            : '网络连接失败，请检查网络后重试';
        reject(new Error(message));
      }
    });
  });
}

module.exports = {
  request,
  extractMessage
};
