const store = {
  session: null,
  profile: null,
  dormitories: [],
  currentDormitory: null,
  members: [],
  expenses: []
};

function setSession(session) {
  store.session = session;
  if (session) {
    wx.setStorageSync('ourbills_session', session);
  } else {
    wx.removeStorageSync('ourbills_session');
  }
}

module.exports = {
  store,
  setSession
};
