/**
 * Helper utilities for Multi-Unit of Measure (UoM)
 */

export function getProductUnits(product) {
  if (!product) return [];
  if (Array.isArray(product.units) && product.units.length > 0) {
    return product.units;
  }
  return [
    {
      id: 0,
      unitName: product.uom || 'Cái',
      conversionRate: 1,
      isBaseUnit: true,
      retailPrice: product.retailPrice || 0,
      wholesalePrice: product.wholesalePrice || 0,
      canSell: true,
    },
  ];
}

export function formatStockDisplay(totalStock, units = [], baseUom = 'Cái') {
  const stockNum = Number(totalStock || 0);
  const baseName = baseUom || 'Cái';

  if (!Array.isArray(units) || units.length <= 1) {
    return `${stockNum.toLocaleString('vi-VN')} ${baseName}`;
  }

  // Find pack unit with largest conversionRate > 1
  const packUnit = [...units]
    .filter((u) => !u.isBaseUnit && Number(u.conversionRate) > 1)
    .sort((a, b) => Number(b.conversionRate) - Number(a.conversionRate))[0];

  if (!packUnit) {
    return `${stockNum.toLocaleString('vi-VN')} ${baseName}`;
  }

  const rate = Number(packUnit.conversionRate);
  const wholePacks = Math.floor(stockNum / rate);
  const remainder = stockNum % rate;

  if (wholePacks > 0 && remainder > 0) {
    return `${wholePacks} ${packUnit.unitName}, ${remainder} ${baseName} (${stockNum.toLocaleString('vi-VN')} ${baseName})`;
  }
  if (wholePacks > 0 && remainder === 0) {
    return `${wholePacks} ${packUnit.unitName} (${stockNum.toLocaleString('vi-VN')} ${baseName})`;
  }
  return `${stockNum.toLocaleString('vi-VN')} ${baseName}`;
}
