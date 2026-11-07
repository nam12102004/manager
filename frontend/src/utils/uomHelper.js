/**
 * Helper utilities for Multi-Unit of Measure (UoM)
 * - Database always stores physical stock in the smallest base unit (conversionRate = 1, isBaseUnit = true).
 * - Larger units always own smaller units (conversionRate > 1, e.g. 1 Hộp = 10 Viên).
 * - Each product can independently select its own Primary Display Unit (e.g. Product A displays Hộp, Product B displays Viên).
 */

const DISPLAY_UNIT_STORAGE_KEY = 'dm_product_display_units_v1';

export function loadDisplayUnitsMap() {
  try {
    const raw = localStorage.getItem(DISPLAY_UNIT_STORAGE_KEY);
    if (!raw) return {};
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch {
    return {};
  }
}

export function getSavedDisplayUnitName(productId) {
  if (!productId) return null;
  const map = loadDisplayUnitsMap();
  return map[String(productId)] || null;
}

export function saveDisplayUnitForProduct(productId, unitName) {
  if (!productId || !unitName) return;
  try {
    const map = loadDisplayUnitsMap();
    map[String(productId)] = unitName.trim();
    localStorage.setItem(DISPLAY_UNIT_STORAGE_KEY, JSON.stringify(map));
  } catch {
    // ignore storage errors
  }
}

/**
 * Chuẩn hóa danh sách đơn vị tính của một sản phẩm (luôn sắp xếp từ đơn vị bé nhất -> lớn nhất).
 * Đơn vị bé nhất luôn có conversionRate = 1 và isBaseUnit = true.
 */
export function getProductUnits(product) {
  if (!product) return [];
  const fallbackName = product.uom?.trim() || 'Cái';

  if (Array.isArray(product.units) && product.units.length > 0) {
    const cleaned = product.units
      .filter((u) => u && String(u.unitName || '').trim() !== '')
      .map((u) => ({
        ...u,
        unitName: String(u.unitName).trim(),
        conversionRate: Number(u.conversionRate) > 0 ? Number(u.conversionRate) : 1,
      }))
      .sort((a, b) => a.conversionRate - b.conversionRate);

    if (cleaned.length > 0) {
      // If the smallest unit has conversionRate !== 1, normalize all rates relative to the smallest unit
      const minRate = cleaned[0].conversionRate > 0 ? cleaned[0].conversionRate : 1;
      return cleaned.map((u, idx) => {
        const normalizedRate = minRate !== 1 ? Number((u.conversionRate / minRate).toFixed(4)) : u.conversionRate;
        const isBase = idx === 0 || normalizedRate === 1;
        return {
          ...u,
          conversionRate: isBase ? 1 : normalizedRate,
          isBaseUnit: isBase,
          retailPrice:
            Number(u.retailPrice) > 0
              ? Number(u.retailPrice)
              : isBase
              ? Number(product.retailPrice || 0)
              : Number(product.retailPrice || 0) * normalizedRate,
          wholesalePrice:
            Number(u.wholesalePrice) > 0
              ? Number(u.wholesalePrice)
              : isBase
              ? Number(product.wholesalePrice || 0)
              : Number(product.wholesalePrice || 0) * normalizedRate,
          canSell: u.canSell !== undefined ? u.canSell : true,
        };
      });
    }
  }

  return [
    {
      id: 0,
      unitName: fallbackName,
      conversionRate: 1,
      isBaseUnit: true,
      retailPrice: Number(product.retailPrice || 0),
      wholesalePrice: Number(product.wholesalePrice || 0),
      canSell: true,
    },
  ];
}

/**
 * Lấy đơn vị cơ sở nhỏ nhất (conversionRate = 1) của sản phẩm.
 */
export function getBaseUnit(product) {
  const units = getProductUnits(product);
  return units.find((u) => u.isBaseUnit || Number(u.conversionRate) === 1) || units[0] || {
    unitName: product?.uom || 'Cái',
    conversionRate: 1,
    isBaseUnit: true,
  };
}

/**
 * Lấy "Đơn vị chính hiển thị" (Primary Display Unit) riêng của từng sản phẩm.
 * Ưu tiên:
 *  1. overrideUnitName truyền vào
 *  2. Lựa chọn đã lưu riêng cho sản phẩm trong localStorage
 *  3. Trường `product.uom` (nếu khớp với một trong các đơn vị trong `product.units`)
 *  4. Đơn vị có cờ `isDefaultDisplay`
 *  5. Đơn vị cơ sở nhỏ nhất
 */
export function getPrimaryDisplayUnit(product, overrideUnitName = null) {
  const units = getProductUnits(product);
  if (units.length === 0) {
    return {
      unitName: product?.uom || 'Cái',
      conversionRate: 1,
      isBaseUnit: true,
      retailPrice: Number(product?.retailPrice || 0),
      wholesalePrice: Number(product?.wholesalePrice || 0),
    };
  }
  if (units.length === 1) {
    return units[0];
  }

  const findByName = (name) => {
    if (!name) return null;
    const target = String(name).trim().toLowerCase();
    return units.find((u) => u.unitName.toLowerCase() === target) || null;
  };

  if (overrideUnitName) {
    const matchedOverride = findByName(overrideUnitName);
    if (matchedOverride) return matchedOverride;
  }

  if (product?.id) {
    const savedName = getSavedDisplayUnitName(product.id);
    const matchedSaved = findByName(savedName);
    if (matchedSaved) return matchedSaved;
  }

  if (product?.uom) {
    const matchedUom = findByName(product.uom);
    if (matchedUom) return matchedUom;
  }

  const flagged = units.find((u) => u.isDefaultDisplay);
  if (flagged) return flagged;

  return getBaseUnit(product);
}

/**
 * Quy đổi một số lượng gốc (tính theo đơn vị bé nhất) sang đơn vị hiển thị đã chọn.
 * Ví dụ: baseQty = 150 (Viên), displayUnit = Hộp (rate = 10) => 15 (Hộp)
 * Nếu lẻ: baseQty = 155 (Viên), displayUnit = Hộp (rate = 10) => 15.5 (Hộp) (15 Hộp + 5 Viên)
 */
export function convertQtyToDisplayUnit(baseQty, displayUnit) {
  const qtyNum = Number(baseQty || 0);
  const rate = Number(displayUnit?.conversionRate || 1);
  if (rate <= 1) return qtyNum;
  return Number((qtyNum / rate).toFixed(2));
}

/**
 * Lấy bộ giá (Giá vốn, Giá sỉ, Giá lẻ) tương ứng với Đơn vị hiển thị đang chọn của sản phẩm.
 */
export function getDisplayPrices(product, displayUnit) {
  if (!product) {
    return { unitCost: 0, wholesalePrice: 0, retailPrice: 0, conversionRate: 1 };
  }
  const unit = displayUnit || getPrimaryDisplayUnit(product);
  const rate = Number(unit?.conversionRate || 1);
  const baseCost = Number(product.unitCost || 0);
  const baseWholesale = Number(product.wholesalePrice || 0);
  const baseRetail = Number(product.retailPrice || 0);

  if (rate <= 1) {
    return {
      unitCost: baseCost,
      wholesalePrice: Number(unit?.wholesalePrice) > 0 ? Number(unit.wholesalePrice) : baseWholesale,
      retailPrice: Number(unit?.retailPrice) > 0 ? Number(unit.retailPrice) : baseRetail,
      conversionRate: 1,
      unitName: unit?.unitName || product.uom || 'Cái',
      isBaseUnit: true,
    };
  }

  return {
    unitCost: baseCost * rate,
    wholesalePrice: Number(unit?.wholesalePrice) > 0 ? Number(unit.wholesalePrice) : baseWholesale * rate,
    retailPrice: Number(unit?.retailPrice) > 0 ? Number(unit.retailPrice) : baseRetail * rate,
    conversionRate: rate,
    unitName: unit?.unitName || product.uom || 'Cái',
    isBaseUnit: false,
  };
}

/**
 * Tính số lượng quy đổi (cho phép số thập phân, tối đa 2 chữ số thập phân) của một đơn vị từ tồn kho gốc.
 * Ví dụ: baseStock = 5 (Viên), conversionRate = 6 (Hộp) => trả về 0.83 (0,83 Hộp).
 */
export function getStockInUnit(totalBaseStock, conversionRate = 1) {
  const stockNum = Number(totalBaseStock || 0);
  const rate = Number(conversionRate || 1);
  if (rate <= 1) return stockNum;

  return Number((stockNum / rate).toFixed(2));
}

/**
 * Trả về mảng danh sách từng đơn vị kèm số lượng khả dụng (`availableQty`) độc lập.
 */
export function getUnitStockBreakdown(totalBaseStock, units = [], baseUom = 'Cái') {
  const stockNum = Number(totalBaseStock || 0);
  const baseName = baseUom || 'Cái';

  let normalizedUnits = [];
  if (Array.isArray(units) && units.length > 0) {
    normalizedUnits = [...units].sort(
      (a, b) => Number(a.conversionRate || 1) - Number(b.conversionRate || 1)
    );
    const hasBase = normalizedUnits.some((u) => u.isBaseUnit || Number(u.conversionRate) === 1);
    if (!hasBase) {
      normalizedUnits.unshift({
        id: 0,
        unitName: baseName,
        conversionRate: 1,
        isBaseUnit: true,
      });
    }
  } else {
    normalizedUnits = [
      {
        id: 0,
        unitName: baseName,
        conversionRate: 1,
        isBaseUnit: true,
      },
    ];
  }

  return normalizedUnits.map((u) => {
    const rate = Number(u.conversionRate || 1);
    const isBase = Boolean(u.isBaseUnit || rate === 1);
    const availableQty = isBase ? stockNum : getStockInUnit(stockNum, rate);
    return {
      ...u,
      unitName: u.unitName || baseName,
      conversionRate: rate,
      isBaseUnit: isBase,
      availableQty,
    };
  });
}

/**
 * Chuỗi hiển thị tồn kho từng đơn vị: "15 Viên | 1,5 Hộp"
 */
export function formatStockDisplay(totalStock, units = [], baseUom = 'Cái') {
  const breakdown = getUnitStockBreakdown(totalStock, units, baseUom);
  if (breakdown.length <= 1) {
    const base = breakdown[0];
    return `${Number(base.availableQty || 0).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ${base.unitName}`;
  }

  return breakdown
    .map((u) => `${Number(u.availableQty || 0).toLocaleString('vi-VN', { maximumFractionDigits: 2 })} ${u.unitName}`)
    .join(' | ');
}
