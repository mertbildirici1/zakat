export const institutions = [
  { id: "chase", name: "Chase", detail: "Checking, savings, card" },
  { id: "fidelity", name: "Fidelity", detail: "Brokerage and 401(k)" },
  { id: "coinbase", name: "Coinbase", detail: "Crypto" },
];

export function account(id, institutionName, name, mask, type, currentBalance) {
  return {
    id,
    institution_name: institutionName,
    name,
    mask,
    type,
    current_balance: currentBalance,
    iso_currency_code: "USD",
  };
}

export function catalogItem(institutionID) {
  switch (institutionID) {
    case "fidelity":
      return {
        item_id: "item-fidelity",
        institution_id: "fidelity",
        institution_name: "Fidelity",
        accounts: [
          account("fid-brokerage", "Fidelity", "Brokerage", "8821", "brokerage", 33100),
          account("fid-401k", "Fidelity", "401(k)", "1044", "retirement", 88000),
        ],
      };
    case "coinbase":
      return {
        item_id: "item-coinbase",
        institution_id: "coinbase",
        institution_name: "Coinbase",
        accounts: [account("cb-btc", "Coinbase", "Bitcoin", null, "crypto", 2140)],
      };
    default:
      return {
        item_id: "item-chase",
        institution_id: "chase",
        institution_name: "Chase",
        accounts: [
          account("ch-checking", "Chase", "Total Checking", "1234", "checking", 4250),
          account("ch-savings", "Chase", "Savings", "9876", "savings", 12800),
          account("ch-card", "Chase", "Freedom", "4411", "credit", -1240),
        ],
      };
  }
}

export function generateTransactions(institutionID, now = new Date()) {
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const start = addDays(end, -354);
  const rows = [];

  if (institutionID === "chase" || institutionID === undefined) {
    for (let day = 0; day <= 354; day += 14) {
      const date = addDays(start, day);
      rows.push(tx("pay-" + day, "ch-checking", date, "Payroll", 3180, "income"));
    }
    for (let month = 0; month < 12; month += 1) {
      const date = addDays(start, 8 + month * 30);
      rows.push(tx("rent-" + month, "ch-checking", date, "Rent", -1850, "spending"));
      rows.push(tx("util-" + month, "ch-checking", date, "Utilities", -140, "spending"));
      rows.push(tx("save-" + month, "ch-checking", date, "Transfer to savings", -400, "transfer"));
      rows.push(tx("save-in-" + month, "ch-savings", date, "Transfer from checking", 400, "transfer"));
    }
    for (let week = 0; week < 50; week += 1) {
      const date = addDays(start, 3 + week * 7);
      rows.push(tx("groc-" + week, "ch-checking", date, "Groceries", -92 - (week % 5) * 4, "spending"));
    }
    rows.push(tx("card-pay", "ch-checking", addDays(end, -12), "Card payment", -1240, "transfer"));
  }

  if (institutionID === "fidelity") {
    for (let month = 0; month < 12; month += 1) {
      const date = addDays(start, 4 + month * 30);
      rows.push(tx("401k-" + month, "fid-401k", date, "401(k) contribution", 500, "investment"));
      rows.push(tx("broker-" + month, "fid-brokerage", date, "Brokerage deposit", 300, "investment"));
    }
    for (let q = 0; q < 4; q += 1) {
      rows.push(tx("div-" + q, "fid-brokerage", addDays(start, 40 + q * 90), "Dividend", 165, "income"));
    }
  }

  if (institutionID === "coinbase") {
    rows.push(tx("cb-buy-1", "cb-btc", addDays(start, 40), "Buy Bitcoin", 400, "investment"));
    rows.push(tx("cb-buy-2", "cb-btc", addDays(start, 180), "Buy Bitcoin", 250, "investment"));
  }

  return rows.filter((row) => row.date >= start.toISOString().slice(0, 10) && row.date <= end.toISOString().slice(0, 10));
}

function addDays(date, days) {
  const next = new Date(date.getTime());
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function tx(id, accountID, date, name, amount, kind) {
  return {
    id,
    account_id: accountID,
    date: date.toISOString(),
    name,
    amount,
    kind,
  };
}

export function snapshotFromItems(items) {
  const accounts = [];
  const transactions = [];
  for (const item of items) {
    accounts.push(...(item.accounts ?? []));
    transactions.push(...(item.transactions ?? generateTransactions(item.institution_id)));
  }
  transactions.sort((a, b) => (a.date < b.date ? 1 : -1));
  return { accounts, transactions };
}
