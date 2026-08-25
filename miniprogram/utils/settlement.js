function computeTransfers(entries) {
  const creditors = entries
    .filter((item) => item.balance > 0.005)
    .map((item) => ({ id: item.user_id, name: item.username, amount: item.balance }))
    .sort((a, b) => b.amount - a.amount);
  const debtors = entries
    .filter((item) => item.balance < -0.005)
    .map((item) => ({ id: item.user_id, name: item.username, amount: -item.balance }))
    .sort((a, b) => b.amount - a.amount);

  const transfers = [];
  let ci = 0;
  let di = 0;
  while (ci < creditors.length && di < debtors.length) {
    const amount = Math.min(creditors[ci].amount, debtors[di].amount);
    if (amount > 0.005) {
      transfers.push({
        from: debtors[di].name,
        to: creditors[ci].name,
        amount
      });
    }
    creditors[ci].amount -= amount;
    debtors[di].amount -= amount;
    if (creditors[ci].amount < 0.005) ci += 1;
    if (debtors[di].amount < 0.005) di += 1;
  }
  return transfers;
}

module.exports = {
  computeTransfers
};
