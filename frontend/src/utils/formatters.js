/**
 * Format currency to Vietnamese Dong (VND)
 * @param {number|string} amount 
 * @returns {string} e.g. "1.250.000 ₫"
 */
export function formatVND(amount) {
  if (amount === undefined || amount === null || isNaN(amount)) return '0 ₫';
  const num = Number(amount);
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0
  }).format(num);
}

/**
 * Format standard number with thousands separator
 * @param {number|string} value 
 * @param {number} maxDecimals 
 * @returns {string}
 */
export function formatNumber(value, maxDecimals = 2) {
  if (value === undefined || value === null || isNaN(value)) return '0';
  const num = Number(value);
  return new Intl.NumberFormat('vi-VN', {
    maximumFractionDigits: maxDecimals
  }).format(num);
}

/**
 * Format date time string to localized Vietnamese format
 * @param {string|Date} dateStr 
 * @param {boolean} includeTime 
 * @returns {string}
 */
export function formatDate(dateStr, includeTime = false) {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '—';
    
    if (includeTime) {
      return new Intl.DateTimeFormat('vi-VN', {
        hour: '2-digit',
        minute: '2-digit',
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }).format(d);
    }
    
    return new Intl.DateTimeFormat('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    }).format(d);
  } catch {
    return '—';
  }
}

/**
 * Get current year-month string: YYYY-MM
 * @param {Date} date 
 * @returns {string}
 */
export function getCurrentMonthStr(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

/**
 * Get current year-month-day string: YYYY-MM-DD
 * @param {Date} date 
 * @returns {string}
 */
export function getCurrentDateStr(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Debt helper:
 * Debt > 0: Phải thu (Receivable)
 * Debt < 0: Phải trả (Payable)
 * Debt = 0: Hết nợ
 */
export function getDebtStatus(debt) {
  const val = Number(debt || 0);
  if (val > 0) {
    return {
      type: 'receivable',
      label: 'Phải thu',
      amount: val,
      color: 'danger', // Khách còn nợ mình
    };
  } else if (val < 0) {
    return {
      type: 'payable',
      label: 'Phải trả',
      amount: Math.abs(val),
      color: 'warning', // Mình nợ khách/NCC
    };
  }
  return {
    type: 'balanced',
    label: 'Cân bằng',
    amount: 0,
    color: 'neutral',
  };
}

/**
 * Helper to safely parse JSON arrays from backend PhonesJson or AddressesJson
 * @param {string|Array} jsonStr 
 * @returns {string}
 */
export function parseJsonList(jsonStr) {
  if (!jsonStr) return '';
  if (Array.isArray(jsonStr)) return jsonStr.join(', ');
  try {
    const parsed = JSON.parse(jsonStr);
    if (Array.isArray(parsed)) return parsed.join(', ');
    return String(parsed);
  } catch {
    return String(jsonStr);
  }
}

/**
 * Convert number into Vietnamese words for vouchers and financial receipts
 * e.g. 1500000 -> "Một triệu năm trăm nghìn đồng chẵn."
 * @param {number|string} number
 * @returns {string}
 */
export function numberToWordsVN(number) {
  const n = Math.round(Number(number || 0));
  if (isNaN(n) || n === 0) return 'Không đồng chẵn.';

  const isNegative = n < 0;
  const absN = Math.abs(n);

  const digits = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];
  const units = ['', 'nghìn', 'triệu', 'tỷ', 'nghìn tỷ', 'triệu tỷ'];

  const readGroup3 = (group, isHighest) => {
    let [h, t, u] = [Math.floor(group / 100), Math.floor((group % 100) / 10), group % 10];
    let res = [];

    if (h > 0 || !isHighest) {
      res.push(`${digits[h]} trăm`);
    }

    if (t > 1) {
      res.push(`${digits[t]} mươi`);
      if (u === 1) res.push('mốt');
      else if (u === 4) res.push('tư');
      else if (u === 5) res.push('lăm');
      else if (u > 0) res.push(digits[u]);
    } else if (t === 1) {
      res.push('mười');
      if (u === 5) res.push('lăm');
      else if (u > 0) res.push(digits[u]);
    } else if (t === 0) {
      if (u > 0) {
        if (h > 0 || !isHighest) res.push('linh');
        res.push(digits[u]);
      }
    }

    return res.join(' ');
  };

  let numStr = String(absN);
  let groups = [];
  while (numStr.length > 0) {
    groups.unshift(parseInt(numStr.slice(-3), 10));
    numStr = numStr.slice(0, -3);
  }

  let words = [];
  const totalGroups = groups.length;
  for (let i = 0; i < totalGroups; i++) {
    const groupVal = groups[i];
    if (groupVal > 0) {
      const isHighest = i === 0;
      const groupText = readGroup3(groupVal, isHighest);
      const unitIndex = totalGroups - 1 - i;
      const unitText = units[unitIndex];
      words.push(`${groupText} ${unitText}`.trim());
    }
  }

  let result = words.join(' ').trim();
  result = (isNegative ? 'Âm ' : '') + result.charAt(0).toUpperCase() + result.slice(1) + ' đồng chẵn.';
  return result;
}

/**
 * Remove Vietnamese accents and lower-case text for diacritics-insensitive instant search
 * @param {string} str
 * @returns {string}
 */
export function normalizeText(str) {
  if (!str) return '';
  return String(str)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'd')
    .trim();
}

