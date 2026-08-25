const config = require('./config');
const store = require('./store');
const supabase = require('./supabase');

const PAGE_SIZE = 50;

function missingColumnError(error) {
  const message = String((error && error.message) || '').toLowerCase();
  return (
    message.indexOf('expense_date') >= 0 ||
    message.indexOf('column') >= 0 ||
    message.indexOf('does not exist') >= 0
  );
}

function generatedInviteCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let index = 0; index < 8; index += 1) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

function nextMonthKey(monthKey) {
  const parts = monthKey.split('-').map(Number);
  const year = parts[1] === 12 ? parts[0] + 1 : parts[0];
  const month = parts[1] === 12 ? 1 : parts[1] + 1;
  return `${year}-${String(month).padStart(2, '0')}`;
}

function toISOWithDate(dateKey) {
  const parsed = new Date(`${dateKey}T12:00:00`);
  return Number.isNaN(parsed.getTime()) ? new Date().toISOString() : parsed.toISOString();
}

function expenseDateKey(expense) {
  return expense.expense_date || String(expense.created_at || '').slice(0, 10);
}

const auth = {
  async signUp({ username, email, password }) {
    return supabase.request('POST', '/auth/v1/signup', {
      body: {
        email: email.trim(),
        password,
        data: { username: username.trim() }
      }
    });
  },

  async signIn(email, password) {
    return supabase.request('POST', '/auth/v1/token?grant_type=password', {
      body: {
        email: email.trim(),
        password
      }
    });
  },

  async signOut() {
    try {
      await supabase.request('POST', '/auth/v1/logout', { body: {} });
    } catch (error) {
      // 本地清除 session 即可，不阻塞退出流程。
    }
    store.setSession(null);
  },

  async fetchProfile(userId) {
    const rows = await supabase.request('GET', '/rest/v1/profiles', {
      params: {
        select: '*',
        id: `eq.${userId}`,
        limit: 1
      }
    });
    if (rows && rows.length) return rows[0];
    const email = store.store.session && store.store.session.user
      ? store.store.session.user.email || ''
      : '';
    return {
      id: userId,
      username: email.split('@')[0] || '成员',
      avatar_url: null
    };
  },

  async updateProfile(userId, payload) {
    return supabase.request('PATCH', `/rest/v1/profiles?id=eq.${userId}`, {
      body: payload,
      headers: { Prefer: 'return=representation' }
    });
  }
};

const dorm = {
  async listMyDormitories() {
    const session = store.store.session;
    if (!session || !session.user) return [];
    const rows = await supabase.request('GET', '/rest/v1/members', {
      params: {
        select: 'dormitory_id',
        user_id: `eq.${session.user.id}`
      }
    });
    const ids = (rows || []).map((row) => row.dormitory_id);
    if (!ids.length) return [];
    const dorms = await supabase.request('GET', '/rest/v1/dormitories', {
      params: {
        select: '*',
        id: `in.(${ids.join(',')})`,
        order: 'created_at.asc'
      }
    });
    return dorms || [];
  },

  async create(name) {
    const session = store.store.session;
    if (!session || !session.user) throw new Error('请先登录');
    const inviteCode = generatedInviteCode();
    const result = await supabase.request('POST', '/rest/v1/dormitories', {
      body: {
        name: name.trim(),
        creator_id: session.user.id,
        invite_code: inviteCode
      },
      headers: { Prefer: 'return=representation' }
    });
    const created = (result || [])[0] || result;
    await supabase.request('POST', '/rest/v1/members', {
      body: {
        dormitory_id: created.id,
        user_id: session.user.id,
        role: 'creator'
      }
    });
    return created;
  },

  async join(code) {
    const result = await supabase.request('POST', '/rest/v1/rpc/join_dormitory', {
      body: {
        p_invite_code: code.trim().toUpperCase()
      }
    });
    if (Array.isArray(result) && result.length) return result[0];
    throw new Error('邀请码不存在或无法加入');
  },

  async getMembers(dormitoryId) {
    const rows = await supabase.request('GET', '/rest/v1/members', {
      params: {
        select: 'id,user_id,role,joined_at,profile:profiles(username,avatar_url)',
        dormitory_id: `eq.${dormitoryId}`,
        order: 'joined_at.asc'
      }
    });
    return (rows || []).map((row) => ({
      id: row.id,
      userId: row.user_id,
      role: row.role,
      joinedAt: row.joined_at,
      username: (row.profile && row.profile.username) || '成员',
      avatarUrl: row.profile ? row.profile.avatar_url : null
    }));
  },

  async deleteDormitory(dormitoryId) {
    await supabase.request('POST', '/rest/v1/rpc/delete_dormitory', {
      body: {
        p_dormitory_id: dormitoryId
      }
    });
  }
};

const expense = {
  async list(dormitoryId, offset = 0, limit = PAGE_SIZE) {
    const rows = await supabase.request('GET', '/rest/v1/expenses', {
      params: {
        select: '*',
        dormitory_id: `eq.${dormitoryId}`,
        order: 'created_at.desc',
        offset,
        limit
      }
    });
    return rows || [];
  },

  async listAll(dormitoryId) {
    const all = [];
    let offset = 0;
    for (;;) {
      const rows = await this.list(dormitoryId, offset, 1000);
      all.push(...rows);
      if (rows.length < 1000) break;
      offset += 1000;
    }
    return all;
  },

  async listByMonth(dormitoryId, monthKey) {
    try {
      const rows = await supabase.request('GET', '/rest/v1/expenses', {
        params: [
          ['select', '*'],
          ['dormitory_id', `eq.${dormitoryId}`],
          ['expense_date', `gte.${monthKey}-01`],
          ['expense_date', `lt.${nextMonthKey(monthKey)}-01`],
          ['order', 'created_at.desc'],
          ['limit', 1000]
        ]
      });
      return rows || [];
    } catch (error) {
      if (!missingColumnError(error)) throw error;
      const all = await this.listAll(dormitoryId);
      return all.filter((item) => expenseDateKey(item).slice(0, 7) === monthKey);
    }
  },

  async add({ dormitoryId, title, amount, category, payerId, creatorId, dateKey }) {
    const payload = {
      dormitory_id: dormitoryId,
      title: title.trim(),
      amount: Number(amount),
      category,
      payer_id: payerId,
      creator_id: creatorId,
      expense_date: dateKey,
      created_at: toISOWithDate(dateKey)
    };
    try {
      const result = await supabase.request('POST', '/rest/v1/expenses', {
        body: payload,
        headers: { Prefer: 'return=representation' }
      });
      return (result || [])[0] || result;
    } catch (error) {
      if (!missingColumnError(error)) throw error;
      delete payload.expense_date;
      const result = await supabase.request('POST', '/rest/v1/expenses', {
        body: payload,
        headers: { Prefer: 'return=representation' }
      });
      return (result || [])[0] || result;
    }
  },

  async update(expenseId, { title, amount, category, payerId, dateKey }) {
    const payload = {
      title: title.trim(),
      amount: Number(amount),
      category,
      payer_id: payerId
    };
    if (dateKey) {
      payload.expense_date = dateKey;
      payload.created_at = toISOWithDate(dateKey);
    }
    try {
      await supabase.request('PATCH', `/rest/v1/expenses?id=eq.${expenseId}`, {
        body: payload
      });
    } catch (error) {
      if (!missingColumnError(error)) throw error;
      delete payload.expense_date;
      await supabase.request('PATCH', `/rest/v1/expenses?id=eq.${expenseId}`, {
        body: payload
      });
    }
  },

  async remove(expenseId) {
    await supabase.request('DELETE', `/rest/v1/expenses?id=eq.${expenseId}`);
  }
};

const settlement = {
  async generate(dormitoryId, monthKey) {
    const result = await supabase.request(
      'POST',
      '/rest/v1/rpc/generate_monthly_settlements',
      {
        body: {
          p_dormitory_id: dormitoryId,
          p_month: monthKey
        }
      }
    );
    return result || [];
  },

  async fetch(dormitoryId, monthKey) {
    const rows = await supabase.request('GET', '/rest/v1/settlements', {
      params: {
        select: '*',
        dormitory_id: `eq.${dormitoryId}`,
        month: `eq.${monthKey}`,
        order: 'balance.desc'
      }
    });
    return rows || [];
  }
};

function uploadAvatar(filePath) {
  return new Promise((resolve, reject) => {
    const session = store.store.session;
    if (!session || !session.user) {
      reject(new Error('请先登录'));
      return;
    }
    const extensionMatch = filePath.match(/\.([a-zA-Z0-9]+)$/);
    const extension = extensionMatch ? extensionMatch[1] : 'jpg';
    const name = `${session.user.id}/${Date.now()}.${extension}`;
    wx.uploadFile({
      url: `${config.SUPABASE_URL}/storage/v1/object/avatars/${name}`,
      filePath,
      name: 'file',
      header: {
        apikey: config.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${session.access_token}`,
        'x-upsert': 'true'
      },
      success(res) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(
            `${config.SUPABASE_URL}/storage/v1/object/public/avatars/${name}`
          );
        } else {
          let message = `上传失败 (${res.statusCode})`;
          try {
            message = supabase.extractMessage(JSON.parse(res.data), res.statusCode);
          } catch (error) {
            // 保留默认错误信息。
          }
          reject(new Error(message));
        }
      },
      fail() {
        reject(new Error('头像上传失败，请检查网络'));
      }
    });
  });
}

module.exports = {
  auth,
  dorm,
  expense,
  settlement,
  uploadAvatar
};
