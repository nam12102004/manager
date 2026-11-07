import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Layers, Info, ArrowRight, CheckCircle2 } from 'lucide-react';
import { formatVND } from '../../utils/formatters';

// Thứ bậc phổ biến của đơn vị tính (số nhỏ = đơn vị bé, số lớn = đơn vị lớn)
// Giúp tự động gợi ý chiều "1 Hộp = N Viên" khi người dùng thêm Viên sau Hộp
const UNIT_HIERARCHY_RANK = {
  viên: 1,
  vien: 1,
  cái: 1,
  cai: 1,
  chiếc: 1,
  chiec: 1,
  ống: 1,
  ong: 1,
  gói: 2,
  goi: 2,
  vỉ: 2,
  vi: 2,
  chai: 2,
  lọ: 2,
  lo: 2,
  lon: 2,
  tuýp: 2,
  tuyp: 2,
  hộp: 3,
  hop: 3,
  lốc: 3,
  loc: 3,
  dây: 3,
  day: 3,
  lố: 4,
  bịch: 4,
  bich: 4,
  túi: 4,
  tui: 4,
  thùng: 5,
  thung: 5,
  kiện: 6,
  kien: 6,
  bao: 6,
};

function getUnitRank(name) {
  if (!name) return null;
  const key = String(name).trim().toLowerCase();
  return UNIT_HIERARCHY_RANK[key] ?? null;
}

export default function SubUnitsEditor({
  baseUom = 'Cái',
  onBaseUomChange,
  units = [],
  onChange,
  disabled = false,
}) {
  const currentPrimaryName = baseUom?.trim() || 'Cái';

  // Chuẩn hóa danh sách đơn vị:
  // - Đơn vị bé nhất luôn có conversionRate = 1 và isBaseUnit = true
  // - Các đơn vị lớn hơn có conversionRate > 1 và isBaseUnit = false
  // - Không ghi đè tên đơn vị cơ sở bằng baseUom khi đã có nhiều đơn vị (vì baseUom có thể là Đơn vị chính hiển thị như "Hộp")
  const normalizedUnits = React.useMemo(() => {
    if (!Array.isArray(units) || units.length === 0) {
      return [
        {
          unitName: currentPrimaryName,
          conversionRate: 1,
          isBaseUnit: true,
          retailPrice: 0,
          wholesalePrice: 0,
        },
      ];
    }

    const valid = units
      .filter((u) => u && String(u.unitName || '').trim() !== '')
      .map((u) => ({
        ...u,
        unitName: String(u.unitName).trim(),
        conversionRate: Number(u.conversionRate) > 0 ? Number(u.conversionRate) : 1,
      }))
      .sort((a, b) => a.conversionRate - b.conversionRate);

    if (valid.length === 0) {
      return [
        {
          unitName: currentPrimaryName,
          conversionRate: 1,
          isBaseUnit: true,
          retailPrice: 0,
          wholesalePrice: 0,
        },
      ];
    }

    const minRate = valid[0].conversionRate > 0 ? valid[0].conversionRate : 1;
    return valid.map((u, idx) => {
      const rate = minRate !== 1 ? Number((u.conversionRate / minRate).toFixed(4)) : u.conversionRate;
      const isBase = idx === 0;
      return {
        ...u,
        conversionRate: isBase ? 1 : rate,
        isBaseUnit: isBase,
      };
    });
  }, [units, currentPrimaryName]);

  const smallestUnit = normalizedUnits[0] || {
    unitName: currentPrimaryName,
    conversionRate: 1,
    isBaseUnit: true,
  };
  const smallestUnitName = smallestUnit.unitName || 'Cái';

  // Khi chỉ có duy nhất 1 đơn vị và người dùng gõ đổi ô "Đơn vị tính" ở form trên -> đồng bộ tên đơn vị đó
  useEffect(() => {
    if (Array.isArray(units) && units.length === 1) {
      const onlyUnit = units[0];
      if (onlyUnit && onlyUnit.unitName !== currentPrimaryName && currentPrimaryName) {
        onChange?.([
          {
            ...onlyUnit,
            unitName: currentPrimaryName,
            conversionRate: 1,
            isBaseUnit: true,
          },
        ]);
      }
    }
  }, [currentPrimaryName]);

  // Xác định đơn vị nào đang được chọn làm "Đơn vị hiển thị chính" (Primary Display Unit)
  const activePrimaryUnitName = React.useMemo(() => {
    const found = normalizedUnits.find(
      (u) => u.unitName.toLowerCase() === currentPrimaryName.toLowerCase()
    );
    return found ? found.unitName : smallestUnitName;
  }, [normalizedUnits, currentPrimaryName, smallestUnitName]);

  // Form thêm đơn vị mới
  // relationMode:
  //   - 'larger': Đơn vị mới LỚN HƠN đơn vị liên kết (1 Mới = N Cũ, VD: 1 Hộp = 10 Viên)
  //   - 'smaller': Đơn vị mới BÉ HƠN đơn vị liên kết (1 Cũ = N Mới, VD: Đã có Hộp -> thêm Viên: 1 Hộp = 10 Viên)
  const [newSubUnit, setNewSubUnit] = useState({
    unitName: '',
    linkedUnitName: smallestUnitName,
    relationMode: 'larger',
    linkedRate: '',
    retailPrice: '',
    wholesalePrice: '',
    barcode: '',
  });

  const [addError, setAddError] = useState('');

  // Đảm bảo linkedUnitName luôn trỏ tới một đơn vị hợp lệ trong danh sách
  useEffect(() => {
    const exists = normalizedUnits.some((u) => u.unitName === newSubUnit.linkedUnitName);
    if (!exists) {
      setNewSubUnit((prev) => ({
        ...prev,
        linkedUnitName: normalizedUnits[normalizedUnits.length - 1]?.unitName || smallestUnitName,
      }));
    }
  }, [normalizedUnits, smallestUnitName, newSubUnit.linkedUnitName]);

  // Tự động gợi ý chiều quy đổi khi người dùng nhập tên đơn vị mới (VD: đang có Hộp mà gõ Viên -> tự bật 'smaller': 1 Hộp = N Viên)
  const handleNewUnitNameChange = (val) => {
    const linkedName = newSubUnit.linkedUnitName || smallestUnitName;
    const newRank = getUnitRank(val);
    const linkedRank = getUnitRank(linkedName);
    let suggestedMode = newSubUnit.relationMode;
    if (newRank !== null && linkedRank !== null && newRank !== linkedRank) {
      suggestedMode = newRank < linkedRank ? 'smaller' : 'larger';
    }
    setNewSubUnit((prev) => ({
      ...prev,
      unitName: val,
      relationMode: suggestedMode,
    }));
  };

  const handleLinkedUnitChange = (linkedName) => {
    const newRank = getUnitRank(newSubUnit.unitName);
    const linkedRank = getUnitRank(linkedName);
    let suggestedMode = newSubUnit.relationMode;
    if (newRank !== null && linkedRank !== null && newRank !== linkedRank) {
      suggestedMode = newRank < linkedRank ? 'smaller' : 'larger';
    }
    setNewSubUnit((prev) => ({
      ...prev,
      linkedUnitName: linkedName,
      relationMode: suggestedMode,
    }));
  };

  const handleAddSubUnit = (e) => {
    e?.preventDefault();
    setAddError('');

    const name = newSubUnit.unitName?.trim();
    if (!name) {
      setAddError('Vui lòng nhập tên đơn vị tính (VD: Viên, Hộp, Thùng, Vỉ...)');
      return;
    }

    if (
      normalizedUnits.some(
        (u) => u.unitName.toLowerCase() === name.toLowerCase()
      )
    ) {
      setAddError(`Đơn vị "${name}" đã tồn tại trong danh sách`);
      return;
    }

    const linkedRateNum = Number(newSubUnit.linkedRate);
    if (!linkedRateNum || linkedRateNum <= 1) {
      setAddError('Hệ số quy đổi giữa đơn vị lớn và đơn vị bé phải lớn hơn 1 (VD: 1 Hộp = 10 Viên)');
      return;
    }

    const linkedName = newSubUnit.linkedUnitName || smallestUnitName;
    const targetParent = normalizedUnits.find((u) => u.unitName === linkedName) || smallestUnit;
    const parentRate = Number(targetParent?.conversionRate || 1);

    let nextUnits = [];

    if (newSubUnit.relationMode === 'larger') {
      // 1 [Đơn vị mới] = linkedRateNum [Đơn vị đã có]
      const finalConversionRate = Number((parentRate * linkedRateNum).toFixed(4));
      const unitItem = {
        unitName: name,
        conversionRate: finalConversionRate,
        isBaseUnit: false,
        retailPrice: newSubUnit.retailPrice ? Number(newSubUnit.retailPrice) : 0,
        wholesalePrice: newSubUnit.wholesalePrice ? Number(newSubUnit.wholesalePrice) : 0,
        barcode: newSubUnit.barcode?.trim() || null,
      };
      nextUnits = [...normalizedUnits, unitItem];
    } else {
      // relationMode === 'smaller':
      // 1 [Đơn vị đã có (VD: Hộp)] = linkedRateNum [Đơn vị mới (VD: Viên)]
      // Tức là Đơn vị đã có LỚN HƠN và SỞ HỮU Đơn vị mới!
      const rawRateRelativeToCurrentSmallest = parentRate / linkedRateNum;

      if (rawRateRelativeToCurrentSmallest < 1) {
        // Đơn vị mới (VD: Viên) còn NHỎ HƠN đơn vị cơ sở hiện tại (VD: Hộp đang có rate = 1)
        // => Đôn Đơn vị mới (Viên) lên làm Đơn vị cơ sở nhỏ nhất (conversionRate = 1, isBaseUnit = true)
        // => Nhân toàn bộ các đơn vị hiện có (Hộp, Thùng...) với hệ số scaleFactor
        const scaleFactor = linkedRateNum / parentRate;
        const scaledExistingUnits = normalizedUnits.map((u) => ({
          ...u,
          conversionRate: Number((Number(u.conversionRate || 1) * scaleFactor).toFixed(4)),
          isBaseUnit: false,
        }));

        const newSmallestUnit = {
          unitName: name,
          conversionRate: 1,
          isBaseUnit: true,
          retailPrice: newSubUnit.retailPrice ? Number(newSubUnit.retailPrice) : 0,
          wholesalePrice: newSubUnit.wholesalePrice ? Number(newSubUnit.wholesalePrice) : 0,
          barcode: newSubUnit.barcode?.trim() || null,
        };

        nextUnits = [newSmallestUnit, ...scaledExistingUnits];
      } else {
        // Đơn vị mới nằm trung gian (VD: Đã có Viên (x1) và Thùng (x200), thêm Hộp với 1 Thùng = 20 Hộp => Hộp = x10 Viên)
        const intermediateRate = Number(rawRateRelativeToCurrentSmallest.toFixed(4));
        if (normalizedUnits.some((u) => Number(u.conversionRate) === intermediateRate)) {
          setAddError(`Đã có đơn vị với hệ số quy đổi x${intermediateRate} ${smallestUnitName}`);
          return;
        }
        const unitItem = {
          unitName: name,
          conversionRate: intermediateRate,
          isBaseUnit: false,
          retailPrice: newSubUnit.retailPrice ? Number(newSubUnit.retailPrice) : 0,
          wholesalePrice: newSubUnit.wholesalePrice ? Number(newSubUnit.wholesalePrice) : 0,
          barcode: newSubUnit.barcode?.trim() || null,
        };
        nextUnits = [...normalizedUnits, unitItem];
      }
    }

    // Sắp xếp lại từ đơn vị bé nhất -> lớn nhất
    nextUnits.sort((a, b) => Number(a.conversionRate) - Number(b.conversionRate));
    const minRate = Number(nextUnits[0]?.conversionRate || 1);
    const finalizedUnits = nextUnits.map((u, idx) => ({
      ...u,
      conversionRate: idx === 0 ? 1 : Number((Number(u.conversionRate) / minRate).toFixed(4)),
      isBaseUnit: idx === 0,
    }));

    onChange?.(finalizedUnits);

    // Reset form
    setNewSubUnit({
      unitName: '',
      linkedUnitName: finalizedUnits[0]?.unitName || smallestUnitName,
      relationMode: 'larger',
      linkedRate: '',
      retailPrice: '',
      wholesalePrice: '',
      barcode: '',
    });
  };

  // Xóa một đơn vị (cho phép xóa cả đơn vị cơ sở nếu đang có >= 2 đơn vị: đơn vị kế tiếp sẽ tự động thành đơn vị cơ sở x1)
  const handleDeleteSubUnit = (unitNameToDelete) => {
    if (normalizedUnits.length <= 1) return;
    const remaining = normalizedUnits
      .filter((u) => u.unitName.toLowerCase() !== unitNameToDelete.toLowerCase())
      .sort((a, b) => Number(a.conversionRate) - Number(b.conversionRate));

    if (remaining.length === 0) return;

    const newMinRate = Number(remaining[0].conversionRate || 1);
    const rebased = remaining.map((u, idx) => ({
      ...u,
      conversionRate: idx === 0 ? 1 : Number((Number(u.conversionRate) / newMinRate).toFixed(4)),
      isBaseUnit: idx === 0,
    }));

    onChange?.(rebased);

    // Nếu xóa đúng đơn vị đang được chọn làm Đơn vị hiển thị chính -> chuyển về đơn vị đầu tiên còn lại
    if (activePrimaryUnitName.toLowerCase() === unitNameToDelete.toLowerCase()) {
      onBaseUomChange?.(rebased[0].unitName);
    }
  };

  // Đổi trực tiếp tên của một đơn vị trong bảng (VD: sửa "Hộp" -> "Viên")
  const handleRenameUnitInline = (index, newNameVal) => {
    const oldName = normalizedUnits[index]?.unitName;
    const updated = normalizedUnits.map((u, idx) =>
      idx === index ? { ...u, unitName: newNameVal } : u
    );
    onChange?.(updated);

    if (
      oldName &&
      activePrimaryUnitName.toLowerCase() === oldName.toLowerCase() &&
      newNameVal.trim()
    ) {
      onBaseUomChange?.(newNameVal.trim());
    }
  };

  // Sửa trực tiếp giá bán lẻ / giá bán sỉ / mã vạch trên bảng
  const handleUpdateUnitField = (index, field, val) => {
    const updated = normalizedUnits.map((u, idx) => {
      if (idx !== index) return u;
      if (field === 'retailPrice' || field === 'wholesalePrice') {
        return { ...u, [field]: val === '' ? 0 : Number(val) };
      }
      return { ...u, [field]: val };
    });
    onChange?.(updated);
  };

  // Chọn Đơn vị hiển thị chính cho sản phẩm này
  const handleSelectPrimaryDisplayUnit = (unitName) => {
    if (!unitName) return;
    onBaseUomChange?.(unitName);
  };

  // Tính toán preview quy đổi
  const linkedName = newSubUnit.linkedUnitName || smallestUnitName;
  const targetParent = normalizedUnits.find((u) => u.unitName === linkedName) || smallestUnit;
  const parentRate = Number(targetParent?.conversionRate || 1);
  const userRate = Number(newSubUnit.linkedRate || 0);

  return (
    <div style={{ marginTop: '0.5rem' }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '0.5rem',
          marginBottom: '0.75rem',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Layers size={16} color="var(--primary)" />
          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, margin: 0 }}>
            Cấu Hình Đơn Vị Tính & Chọn Đơn Vị Hiển Thị Chính
          </h4>
        </div>
        <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
          Đơn vị bé nhất (gốc kho): <strong style={{ color: '#16a34a' }}>{smallestUnitName} (x1)</strong>
          {' • '}
          Hiển thị chính trên bảng: <strong style={{ color: 'var(--primary)' }}>{activePrimaryUnitName}</strong>
        </div>
      </div>

      <div
        style={{
          marginBottom: '1rem',
          padding: '0.625rem 0.875rem',
          background: 'var(--bg-tertiary)',
          borderRadius: 'var(--radius-md)',
          fontSize: '0.8125rem',
          color: 'var(--text-secondary)',
          display: 'flex',
          alignItems: 'flex-start',
          gap: '0.5rem',
        }}
      >
        <Info size={15} color="var(--primary)" style={{ flexShrink: 0, marginTop: '2px' }} />
        <div>
          <div>
            • <strong>Quy tắc:</strong> Đơn vị lớn luôn sở hữu đơn vị bé (VD: <strong>1 Hộp = 10 Viên</strong>). Nếu bạn lỡ thêm <strong>Hộp</strong> trước, bạn vẫn có thể thêm <strong>Viên</strong> sau bằng cách chọn chiều <em>&quot;1 Hộp = N Viên&quot;</em> bên dưới.
          </div>
          <div style={{ marginTop: '2px' }}>
            • <strong>Đơn vị hiển thị chính:</strong> Tích chọn cột <strong>&quot;Hiển Thị Chính&quot;</strong> để quyết định sản phẩm này hiển thị theo <strong>Hộp</strong> hay <strong>Viên</strong> ngoài trang Kho &amp; Sản phẩm.
          </div>
        </div>
      </div>

      {/* Bảng danh sách đơn vị */}
      <div style={{ overflowX: 'auto', marginBottom: '1rem' }}>
        <table
          className="data-table"
          style={{ width: '100%', fontSize: '0.8125rem' }}
        >
          <thead>
            <tr>
              <th style={{ width: '16%', textAlign: 'center' }}>Hiển Thị Chính</th>
              <th style={{ width: '22%' }}>Tên Đơn Vị (Sửa trực tiếp)</th>
              <th style={{ width: '22%' }}>Quy Đổi (Đơn vị lớn sở hữu bé)</th>
              <th style={{ width: '17%' }}>Giá Bán Lẻ</th>
              <th style={{ width: '17%' }}>Giá Bán Sỉ</th>
              <th style={{ width: '6%', textAlign: 'center' }}>Xóa</th>
            </tr>
          </thead>
          <tbody>
            {normalizedUnits.map((u, idx) => {
              const isSmallest = idx === 0 || u.isBaseUnit || Number(u.conversionRate) === 1;
              const isPrimaryDisplay =
                u.unitName.toLowerCase() === activePrimaryUnitName.toLowerCase();

              return (
                <tr
                  key={idx}
                  style={{
                    backgroundColor: isPrimaryDisplay ? 'rgba(37, 99, 235, 0.05)' : undefined,
                  }}
                >
                  <td style={{ textAlign: 'center' }}>
                    <label
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '5px',
                        cursor: disabled ? 'default' : 'pointer',
                        fontWeight: isPrimaryDisplay ? 700 : 500,
                        color: isPrimaryDisplay ? 'var(--primary)' : 'var(--text-secondary)',
                        fontSize: '0.75rem',
                      }}
                      title={`Chọn "${u.unitName}" làm đơn vị hiển thị chính của sản phẩm này trên bảng Kho & Sản phẩm`}
                    >
                      <input
                        type="radio"
                        name="primaryDisplayUnitRadio"
                        checked={isPrimaryDisplay}
                        disabled={disabled}
                        onChange={() => handleSelectPrimaryDisplayUnit(u.unitName)}
                        style={{ cursor: 'pointer', accentColor: 'var(--primary)' }}
                      />
                      <span>{isPrimaryDisplay ? 'ĐV Chính' : 'Chọn'}</span>
                    </label>
                  </td>

                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <input
                        type="text"
                        className="form-input"
                        style={{
                          padding: '0.25rem 0.5rem',
                          fontSize: '0.8125rem',
                          fontWeight: 700,
                          width: '110px',
                          color: isPrimaryDisplay ? 'var(--primary)' : 'inherit',
                        }}
                        disabled={disabled}
                        value={u.unitName}
                        onChange={(e) => handleRenameUnitInline(idx, e.target.value)}
                        title="Bấm để đổi tên đơn vị trực tiếp (VD: đổi Hộp thành Viên)"
                      />
                      {isSmallest && (
                        <span
                          className="badge badge-success"
                          style={{ fontSize: '0.6875rem', whiteSpace: 'nowrap' }}
                          title="Đơn vị bé nhất làm gốc quy đổi tồn kho"
                        >
                          ĐV Bé Nhất (x1)
                        </span>
                      )}
                    </div>
                  </td>

                  <td className="mono">
                    {isSmallest ? (
                      <span style={{ color: 'var(--text-muted)' }}>1 {u.unitName} (Đơn vị bé nhất)</span>
                    ) : (
                      <span style={{ fontWeight: 700, color: '#0f172a' }}>
                        1 {u.unitName} = {u.conversionRate} {smallestUnitName}
                      </span>
                    )}
                  </td>

                  <td>
                    <input
                      type="number"
                      min="0"
                      className="form-input mono"
                      style={{ padding: '0.25rem 0.5rem', fontSize: '0.8125rem', width: '115px' }}
                      placeholder="Theo tỷ lệ"
                      disabled={disabled}
                      value={u.retailPrice || ''}
                      onChange={(e) => handleUpdateUnitField(idx, 'retailPrice', e.target.value)}
                    />
                  </td>

                  <td>
                    <input
                      type="number"
                      min="0"
                      className="form-input mono"
                      style={{ padding: '0.25rem 0.5rem', fontSize: '0.8125rem', width: '115px' }}
                      placeholder="Theo tỷ lệ"
                      disabled={disabled}
                      value={u.wholesalePrice || ''}
                      onChange={(e) => handleUpdateUnitField(idx, 'wholesalePrice', e.target.value)}
                    />
                  </td>

                  <td style={{ textAlign: 'center' }}>
                    {normalizedUnits.length > 1 && !disabled ? (
                      <button
                        type="button"
                        className="btn btn-ghost btn-icon"
                        style={{ color: 'var(--danger)', width: '26px', height: '26px' }}
                        title={`Xóa đơn vị ${u.unitName}`}
                        onClick={() => handleDeleteSubUnit(u.unitName)}
                      >
                        <Trash2 size={13} />
                      </button>
                    ) : (
                      <span style={{ color: 'var(--text-muted)' }}>—</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Form thêm đơn vị tính mới */}
      {!disabled && (
        <div
          style={{
            border: '1px dashed var(--border-color)',
            borderRadius: 'var(--radius-md)',
            padding: '0.875rem',
            background: 'rgba(37, 99, 235, 0.02)',
          }}
        >
          <div
            style={{
              fontSize: '0.8125rem',
              fontWeight: 700,
              marginBottom: '0.625rem',
              color: 'var(--text-primary)',
            }}
          >
            + Thêm Đơn Vị Tính Mới (Hỗ trợ thêm cả đơn vị lớn hơn hoặc đơn vị bé hơn)
          </div>

          {/* Chọn chiều quy đổi: Đơn vị mới LỚN HƠN hay BÉ HƠN đơn vị đã có */}
          <div
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: '0.5rem',
              marginBottom: '0.75rem',
            }}
          >
            <label
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '0.4rem 0.75rem',
                borderRadius: 'var(--radius-md)',
                border:
                  newSubUnit.relationMode === 'larger'
                    ? '1.5px solid var(--primary)'
                    : '1px solid var(--border-color)',
                backgroundColor:
                  newSubUnit.relationMode === 'larger' ? 'rgba(37, 99, 235, 0.08)' : '#ffffff',
                fontSize: '0.78rem',
                fontWeight: newSubUnit.relationMode === 'larger' ? 700 : 500,
                cursor: 'pointer',
              }}
            >
              <input
                type="radio"
                name="unitRelationMode"
                checked={newSubUnit.relationMode === 'larger'}
                onChange={() => setNewSubUnit({ ...newSubUnit, relationMode: 'larger' })}
              />
              <span>
                Thêm đơn vị <strong>LỚN HƠN {linkedName}</strong>{' '}
                <em>
                  (1 {newSubUnit.unitName || 'ĐV mới'} = N {linkedName})
                </em>
              </span>
            </label>

            <label
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '0.4rem 0.75rem',
                borderRadius: 'var(--radius-md)',
                border:
                  newSubUnit.relationMode === 'smaller'
                    ? '1.5px solid #16a34a'
                    : '1px solid var(--border-color)',
                backgroundColor:
                  newSubUnit.relationMode === 'smaller' ? 'rgba(22, 163, 74, 0.08)' : '#ffffff',
                fontSize: '0.78rem',
                fontWeight: newSubUnit.relationMode === 'smaller' ? 700 : 500,
                cursor: 'pointer',
              }}
            >
              <input
                type="radio"
                name="unitRelationMode"
                checked={newSubUnit.relationMode === 'smaller'}
                onChange={() => setNewSubUnit({ ...newSubUnit, relationMode: 'smaller' })}
              />
              <span>
                Thêm đơn vị <strong>BÉ HƠN {linkedName}</strong> — {linkedName} sở hữu ĐV mới{' '}
                <em>
                  (1 {linkedName} = N {newSubUnit.unitName || 'ĐV mới'})
                </em>
              </span>
            </label>
          </div>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
              gap: '0.625rem',
            }}
          >
            <div className="form-group" style={{ margin: 0 }}>
              <label className="form-label" style={{ fontSize: '0.75rem' }}>
                Tên Đơn Vị Mới <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                placeholder="VD: Viên, Hộp, Thùng..."
                value={newSubUnit.unitName}
                onChange={(e) => handleNewUnitNameChange(e.target.value)}
              />
            </div>

            <div className="form-group" style={{ margin: 0 }}>
              <label className="form-label" style={{ fontSize: '0.75rem' }}>
                Quy Đổi Với Đơn Vị Đã Có
              </label>
              <select
                className="form-select"
                value={linkedName}
                onChange={(e) => handleLinkedUnitChange(e.target.value)}
              >
                {normalizedUnits.map((u) => (
                  <option key={u.unitName} value={u.unitName}>
                    {u.unitName} (x{u.conversionRate})
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group" style={{ margin: 0 }}>
              <label className="form-label" style={{ fontSize: '0.75rem', fontWeight: 700 }}>
                {newSubUnit.relationMode === 'larger' ? (
                  <>
                    1 {newSubUnit.unitName || 'ĐV mới'} = Bao Nhiêu {linkedName}?{' '}
                    <span className="req">*</span>
                  </>
                ) : (
                  <>
                    1 {linkedName} = Bao Nhiêu {newSubUnit.unitName || 'ĐV mới'}?{' '}
                    <span className="req">*</span>
                  </>
                )}
              </label>
              <input
                type="number"
                min="2"
                step="any"
                className="form-input mono"
                placeholder="VD: 10"
                value={newSubUnit.linkedRate}
                onChange={(e) => setNewSubUnit({ ...newSubUnit, linkedRate: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ margin: 0 }}>
              <label className="form-label" style={{ fontSize: '0.75rem' }}>
                Giá Bán Lẻ ({newSubUnit.unitName || 'ĐV mới'})
              </label>
              <input
                type="number"
                min="0"
                className="form-input mono"
                placeholder="VD: 50000"
                value={newSubUnit.retailPrice}
                onChange={(e) => setNewSubUnit({ ...newSubUnit, retailPrice: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ margin: 0 }}>
              <label className="form-label" style={{ fontSize: '0.75rem' }}>
                Giá Bán Sỉ ({newSubUnit.unitName || 'ĐV mới'})
              </label>
              <input
                type="number"
                min="0"
                className="form-input mono"
                placeholder="VD: 45000"
                value={newSubUnit.wholesalePrice}
                onChange={(e) => setNewSubUnit({ ...newSubUnit, wholesalePrice: e.target.value })}
              />
            </div>

            <div className="form-group" style={{ margin: 0 }}>
              <label className="form-label" style={{ fontSize: '0.75rem' }}>
                Mã Vạch Barcode
              </label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: 893..."
                value={newSubUnit.barcode}
                onChange={(e) => setNewSubUnit({ ...newSubUnit, barcode: e.target.value })}
              />
            </div>
          </div>

          {newSubUnit.unitName && userRate > 1 && (
            <div
              style={{
                marginTop: '0.5rem',
                fontSize: '0.8125rem',
                color: newSubUnit.relationMode === 'smaller' ? '#16a34a' : 'var(--primary)',
                fontWeight: 600,
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              <ArrowRight size={14} />
              {newSubUnit.relationMode === 'larger' ? (
                <span>
                  1 <strong>{newSubUnit.unitName}</strong> = {userRate} {linkedName} ={' '}
                  <strong>
                    {Number((parentRate * userRate).toFixed(4))} {smallestUnitName}
                  </strong>
                </span>
              ) : (
                <span>
                  1 <strong>{linkedName}</strong> = <strong>{userRate} {newSubUnit.unitName}</strong>{' '}
                  (Đơn vị lớn <strong>{linkedName}</strong> sở hữu đơn vị bé{' '}
                  <strong>{newSubUnit.unitName}</strong>)
                </span>
              )}
            </div>
          )}

          {addError && (
            <div
              style={{
                marginTop: '0.5rem',
                fontSize: '0.75rem',
                color: 'var(--danger)',
                fontWeight: 600,
              }}
            >
              {addError}
            </div>
          )}

          <button
            type="button"
            className="btn btn-outline btn-sm"
            style={{ marginTop: '0.625rem' }}
            onClick={handleAddSubUnit}
          >
            <Plus size={14} />
            <span>Thêm vào danh sách đơn vị</span>
          </button>
        </div>
      )}
    </div>
  );
}
