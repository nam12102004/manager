import { formatVND, formatDate, formatNumber, numberToWordsVN } from './formatters';
import { WAREHOUSE_MAP } from './constants';

/**
 * Helper to parse store & owner info safely
 */
function parseOwner(ownerInfo) {
  let storeName = 'CÔNG TY / CỬA HÀNG KHO VẬT LIỆU';
  let storeAddress = '';
  let storePhone = '';
  let bankName = '';
  let bankAccount = '';
  let accountHolder = '';

  if (ownerInfo) {
    if (typeof ownerInfo === 'string') {
      try {
        const parsed = JSON.parse(ownerInfo);
        storeName = parsed.storeName || storeName;
        storeAddress = parsed.storeAddress || '';
        storePhone = parsed.storePhone || '';
        bankName = parsed.bankName || '';
        bankAccount = parsed.bankAccount || '';
        accountHolder = parsed.accountHolder || '';
      } catch {
        storeName = ownerInfo;
      }
    } else if (typeof ownerInfo === 'object') {
      storeName = ownerInfo.storeName || ownerInfo.info || storeName;
      storeAddress = ownerInfo.storeAddress || '';
      storePhone = ownerInfo.storePhone || '';
      bankName = ownerInfo.bankName || '';
      bankAccount = ownerInfo.bankAccount || '';
      accountHolder = ownerInfo.accountHolder || '';
    }
  }

  return { storeName, storeAddress, storePhone, bankName, bankAccount, accountHolder };
}

/**
 * Generate standard HTML for PHIẾU XUẤT KHO / HÓA ĐƠN BÁN HÀNG
 * Formatted exactly according to Vietnamese standard enterprise receipt layout
 */
export function generateExportHtml({ exportData, ownerInfo = null, customer = null }) {
  const vDate = exportData.createdAt ? new Date(exportData.createdAt) : (exportData.date ? new Date(exportData.date) : new Date());
  const hours = String(vDate.getHours()).padStart(2, '0');
  const minutes = String(vDate.getMinutes()).padStart(2, '0');
  const day = String(vDate.getDate()).padStart(2, '0');
  const month = String(vDate.getMonth() + 1).padStart(2, '0');
  const year = vDate.getFullYear();
  const dateStr = `${hours}:${minutes} - ${day}/${month}/${year}`;

  const customerName = exportData.customerName || customer?.name || 'Khách lẻ / Khách hàng';
  const customerAddress = exportData.customerAddress || customer?.address || '';
  const customerPhone = exportData.customerPhone || customer?.phone || '';

  const totalSale = Number(exportData.totalSale || exportData.totalAmount || 0);
  const paidAmount = Number(exportData.paidAmount || 0);
  const unpaidThisOrder = Number(exportData.unpaidAmount || (totalSale - paidAmount));
  
  // Calculate old debt and new total debt
  const currentTotalDebt = customer?.debt != null ? Number(customer.debt) : unpaidThisOrder;
  const oldDebt = currentTotalDebt - unpaidThisOrder;
  const finalTotalDebt = currentTotalDebt;

  const totalInWords = numberToWordsVN(finalTotalDebt > 0 ? finalTotalDebt : totalSale);

  const items = exportData.items || [];

  return `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Phiếu Xuất Kho - ${exportData.voucherNumber || exportData.id || ''}</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 10mm 12mm;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: "Times New Roman", Times, serif;
      font-size: 13pt;
      color: #000000;
      line-height: 1.4;
      background: #ffffff;
      padding: 15px;
    }
    .print-container {
      max-width: 800px;
      margin: 0 auto;
    }
    
    /* Top Header Company Info */
    .company-header {
      text-align: center;
      margin-bottom: 8px;
    }
    .company-name {
      font-size: 13pt;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 2px;
    }
    .company-contact {
      font-size: 11pt;
      margin-bottom: 3px;
    }
    .bank-info-line {
      font-size: 11.5pt;
      margin-top: 2px;
    }

    /* Voucher Title */
    .voucher-title-section {
      text-align: center;
      margin: 12px 0 10px 0;
    }
    .voucher-title {
      font-size: 18pt;
      font-weight: bold;
      letter-spacing: 1.5px;
    }
    .voucher-date-code {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 4px;
      font-size: 11.5pt;
    }

    /* Customer Info Section */
    .customer-info-box {
      margin-bottom: 10px;
      font-size: 12pt;
      line-height: 1.5;
    }

    /* Items Table */
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin: 10px 0 14px 0;
    }
    .items-table th, .items-table td {
      border: 1px solid #000000;
      padding: 6px 8px;
      font-size: 11.5pt;
      vertical-align: middle;
    }
    .items-table th {
      background-color: #f4f4f4;
      font-weight: bold;
      text-align: center;
    }
    .col-stt { width: 6%; text-align: center; }
    .col-name { width: 44%; text-align: left; }
    .col-qty { width: 14%; text-align: center; }
    .col-price { width: 18%; text-align: right; }
    .col-total { width: 18%; text-align: right; }

    /* Summary Section */
    .summary-section {
      margin-top: 10px;
      font-size: 12pt;
      line-height: 1.6;
    }
    .summary-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 2px;
    }
    .total-debt-row {
      font-weight: bold;
      font-size: 13pt;
      margin-top: 4px;
      padding-top: 4px;
      border-top: 1px dashed #000;
    }
    .note-text {
      margin-top: 8px;
      font-size: 11pt;
      font-style: italic;
    }
    .return-policy {
      margin-top: 4px;
      font-size: 10.5pt;
    }

    /* Signatures */
    .signatures-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 25px;
      page-break-inside: avoid;
    }
    .signatures-table td {
      width: 25%;
      text-align: center;
      vertical-align: top;
    }
    .sig-role {
      font-weight: bold;
      font-size: 11.5pt;
      margin-bottom: 2px;
    }
    .sig-sub {
      font-style: italic;
      font-size: 9.5pt;
      color: #333;
    }
    .sig-space {
      height: 70px;
    }
    .sig-name {
      font-weight: bold;
      font-size: 11pt;
    }

    @media print {
      body {
        padding: 0;
      }
      .no-print {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="print-container">
    <!-- Header Thông tin Công ty / Cửa hàng -->
    <div class="company-header">
      <div class="company-name">${store.storeName}</div>
      ${store.storeAddress ? `<div class="company-contact">Đ/C: ${store.storeAddress} ${store.storePhone ? ` - ĐT: ${store.storePhone}` : ''}</div>` : (store.storePhone ? `<div class="company-contact">ĐT: ${store.storePhone}</div>` : '')}
      ${store.bankAccount ? `
        <div class="bank-info-line">
          ${store.accountHolder ? `Chủ Tài khoản: <strong>${store.accountHolder}</strong> - ` : ''}
          STK: <strong>${store.bankAccount}</strong> ${store.bankName ? ` - Tại Ngân hàng ${store.bankName}` : ''}
        </div>
      ` : ''}
    </div>

    <!-- Tiêu đề phiếu -->
    <div class="voucher-title-section">
      <div class="voucher-title">PHIẾU XUẤT KHO</div>
      <div class="voucher-date-code">
        <div>Ngày: <strong>${dateStr}</strong></div>
        <div>Mã phiếu: <strong>${exportData.voucherNumber || exportData.id || ''}</strong></div>
      </div>
    </div>

    <!-- Thông tin khách hàng -->
    <div class="customer-info-box">
      <div>Khách hàng: <strong>${customerName}</strong> ${customerPhone ? ` - ${customerPhone}` : ''}</div>
      ${customerAddress ? `<div>Địa chỉ: ${customerAddress}</div>` : ''}
      ${exportData.warehouse ? `<div>Kho xuất: <strong>${WAREHOUSE_MAP[exportData.warehouse] || exportData.warehouse}</strong></div>` : ''}
      ${exportData.notes ? `<div>Ghi chú: ${exportData.notes}</div>` : ''}
    </div>

    <!-- Bảng sản phẩm -->
    <table class="items-table">
      <thead>
        <tr>
          <th class="col-stt">STT</th>
          <th class="col-name">Tên sản phẩm</th>
          <th class="col-qty">SL (${items[0]?.uom || 'ĐVT'})</th>
          <th class="col-price">Đơn giá</th>
          <th class="col-total">Thành tiền</th>
        </tr>
      </thead>
      <tbody>
        ${items.map((it, idx) => `
          <tr>
            <td class="col-stt">${idx + 1}</td>
            <td class="col-name">
              <strong>${it.productName || it.sku || 'Sản phẩm'}</strong>
              ${it.sku ? `<div style="font-size: 9.5pt; color: #444;">Mã SKU: ${it.sku}</div>` : ''}
            </td>
            <td class="col-qty">${formatNumber(it.quantity)}</td>
            <td class="col-price">${formatVND(it.salePrice || it.unitPrice || 0)}</td>
            <td class="col-total"><strong>${formatVND(it.lineTotal || (Number(it.quantity) * Number(it.salePrice || 0)))}</strong></td>
          </tr>
        `).join('')}
      </tbody>
    </table>

    <!-- Tổng tiền & Đã trả -->
    <div class="summary-section">
      <div class="summary-row">
        <span><strong>Tổng tiền thanh toán đơn này:</strong></span>
        <span><strong>${formatVND(totalSale)}</strong></span>
      </div>
      
      <div class="summary-row">
        <span>Tiền khách thanh toán ngay:</span>
        <span>${formatVND(paidAmount)}</span>
      </div>

      <div style="font-style: italic; margin-top: 3px; font-size: 11pt;">
        (Bằng chữ: <strong>${totalInWords}</strong>)
      </div>

      <div class="note-text">
        <u>Chú ý:</u> Quý khách kiểm tra hàng trước khi ký nhận.
      </div>
      <div class="return-policy">
        - Hàng trả lại trong vòng 30 ngày kể từ ngày nhận hàng; Không nhận hàng trả lại với các sản phẩm cắt lô và hàng ôm kho.
      </div>
    </div>

    <!-- Chữ ký 4 bên -->
    <table class="signatures-table">
      <tr>
        <td>
          <div class="sig-role">Thủ kho</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-role">Kế toán</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-role">Lái xe giao hàng</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-role">Người nhận</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
          <div class="sig-name">${customerName}</div>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>
  `;
}

/**
 * Generate standard HTML for PHIẾU NHẬP KHO
 */
export function generateImportHtml({ importData, ownerInfo = null, supplier = null }) {
  const store = parseOwner(ownerInfo);
  const vDate = importData.createdAt ? new Date(importData.createdAt) : (importData.date ? new Date(importData.date) : new Date());
  const hours = String(vDate.getHours()).padStart(2, '0');
  const minutes = String(vDate.getMinutes()).padStart(2, '0');
  const day = String(vDate.getDate()).padStart(2, '0');
  const month = String(vDate.getMonth() + 1).padStart(2, '0');
  const year = vDate.getFullYear();
  const dateStr = `${hours}:${minutes} - ${day}/${month}/${year}`;

  const supplierName = importData.supplierName || supplier?.name || 'Nhà cung cấp';
  const supplierAddress = importData.supplierAddress || supplier?.address || '';
  const supplierPhone = importData.supplierPhone || supplier?.phone || '';

  const totalAmount = Number(importData.totalAmount || 0);
  const paidAmount = Number(importData.paidAmount || 0);
  const unpaidAmount = Number(importData.unpaidAmount || (totalAmount - paidAmount));
  const currentTotalDebt = supplier?.debt != null ? Number(supplier.debt) : unpaidAmount;

  const totalInWords = numberToWordsVN(totalAmount);
  const items = importData.items || [];

  return `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Phiếu Nhập Kho - ${importData.voucherNumber || importData.id || ''}</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 10mm 12mm;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: "Times New Roman", Times, serif;
      font-size: 13pt;
      color: #000000;
      line-height: 1.4;
      background: #ffffff;
      padding: 15px;
    }
    .print-container {
      max-width: 800px;
      margin: 0 auto;
    }
    .company-header {
      text-align: center;
      margin-bottom: 8px;
    }
    .company-name {
      font-size: 13pt;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 2px;
    }
    .company-contact {
      font-size: 11pt;
      margin-bottom: 3px;
    }
    .voucher-title-section {
      text-align: center;
      margin: 12px 0 10px 0;
    }
    .voucher-title {
      font-size: 18pt;
      font-weight: bold;
      letter-spacing: 1.5px;
    }
    .voucher-date-code {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 4px;
      font-size: 11.5pt;
    }
    .partner-info-box {
      margin-bottom: 10px;
      font-size: 12pt;
      line-height: 1.5;
    }
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin: 10px 0 14px 0;
    }
    .items-table th, .items-table td {
      border: 1px solid #000000;
      padding: 6px 8px;
      font-size: 11.5pt;
      vertical-align: middle;
    }
    .items-table th {
      background-color: #f4f4f4;
      font-weight: bold;
      text-align: center;
    }
    .col-stt { width: 6%; text-align: center; }
    .col-name { width: 44%; text-align: left; }
    .col-qty { width: 14%; text-align: center; }
    .col-price { width: 18%; text-align: right; }
    .col-total { width: 18%; text-align: right; }
    .summary-section {
      margin-top: 10px;
      font-size: 12pt;
      line-height: 1.6;
    }
    .summary-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 2px;
    }
    .signatures-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 25px;
      page-break-inside: avoid;
    }
    .signatures-table td {
      width: 25%;
      text-align: center;
      vertical-align: top;
    }
    .sig-role {
      font-weight: bold;
      font-size: 11.5pt;
      margin-bottom: 2px;
    }
    .sig-sub {
      font-style: italic;
      font-size: 9.5pt;
      color: #333;
    }
    .sig-space {
      height: 70px;
    }
    .sig-name {
      font-weight: bold;
      font-size: 11pt;
    }
    @media print {
      body {
        padding: 0;
      }
      .no-print, .no-print * {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="print-container">
    <div class="company-header">
      <div class="company-name">${store.storeName}</div>
      ${store.storeAddress ? `<div class="company-contact">Đ/C: ${store.storeAddress} ${store.storePhone ? ` - ĐT: ${store.storePhone}` : ''}</div>` : (store.storePhone ? `<div class="company-contact">ĐT: ${store.storePhone}</div>` : '')}
    </div>

    <div class="voucher-title-section">
      <div class="voucher-title">PHIẾU NHẬP KHO HÀNG HÓA</div>
      <div class="voucher-date-code">
        <div>Ngày: <strong>${dateStr}</strong></div>
        <div>Mã phiếu: <strong>${importData.voucherNumber || importData.id || ''}</strong></div>
      </div>
    </div>

    <div class="partner-info-box">
      <div>Nhà cung cấp: <strong>${supplierName}</strong> ${supplierPhone ? ` - ${supplierPhone}` : ''}</div>
      ${supplierAddress ? `<div>Địa chỉ: ${supplierAddress}</div>` : ''}
      ${importData.warehouse ? `<div>Kho nhập: <strong>${WAREHOUSE_MAP[importData.warehouse] || importData.warehouse}</strong></div>` : ''}
      ${importData.notes ? `<div>Ghi chú: ${importData.notes}</div>` : ''}
    </div>

    <table class="items-table">
      <thead>
        <tr>
          <th class="col-stt">STT</th>
          <th class="col-name">Tên sản phẩm</th>
          <th class="col-qty">SL (${items[0]?.uom || 'ĐVT'})</th>
          <th class="col-price">Đơn giá nhập</th>
          <th class="col-total">Thành tiền</th>
        </tr>
      </thead>
      <tbody>
        ${items.map((it, idx) => `
          <tr>
            <td class="col-stt">${idx + 1}</td>
            <td class="col-name">
              <strong>${it.productName || it.sku || 'Sản phẩm'}</strong>
              ${it.sku ? `<div style="font-size: 9.5pt; color: #444;">Mã SKU: ${it.sku}</div>` : ''}
            </td>
            <td class="col-qty">${formatNumber(it.quantity)}</td>
            <td class="col-price">${formatVND(it.unitPrice || 0)}</td>
            <td class="col-total"><strong>${formatVND(it.lineTotal || (Number(it.quantity) * Number(it.unitPrice || 0)))}</strong></td>
          </tr>
        `).join('')}
      </tbody>
    </table>

    <div class="summary-section">
      <div class="summary-row">
        <span><strong>Tổng tiền hàng nhập:</strong></span>
        <span><strong>${formatVND(totalAmount)}</strong></span>
      </div>
      <div class="summary-row">
        <span>Đã trả nhà cung cấp:</span>
        <span>${formatVND(paidAmount)}</span>
      </div>
      <div style="font-style: italic; margin-top: 4px; font-size: 11pt;">
        (Bằng chữ: <strong>${totalInWords}</strong>)
      </div>
    </div>

    <table class="signatures-table">
      <tr>
        <td>
          <div class="sig-role">Người giao hàng</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
          <div class="sig-name">${supplierName}</div>
        </td>
        <td>
          <div class="sig-role">Thủ kho</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-role">Kế toán</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-role">Giám đốc / Quản lý</div>
          <div class="sig-sub">(Ký, đóng dấu)</div>
          <div class="sig-space"></div>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>
  `;
}

/**
 * Generate standard Vietnamese accounting voucher HTML (Mẫu 01-TT cho Phiếu Thu, Mẫu 02-TT cho Phiếu Chi)
 */
export function generateVoucherHtml({ voucher, type = 'receipt', ownerInfo = null }) {
  const isReceipt = type === 'receipt';
  const title = isReceipt ? 'PHIẾU THU' : 'PHIẾU CHI';
  const formCode = isReceipt ? 'Mẫu số 01 - TT' : 'Mẫu số 02 - TT';
  const voucherNum = isReceipt ? (voucher.receiptNumber || voucher.id) : (voucher.paymentNumber || voucher.id);
  
  const vDate = voucher.createdAt ? new Date(voucher.createdAt) : (voucher.date ? new Date(voucher.date) : new Date());
  const hours = String(vDate.getHours()).padStart(2, '0');
  const minutes = String(vDate.getMinutes()).padStart(2, '0');
  const day = String(vDate.getDate()).padStart(2, '0');
  const month = String(vDate.getMonth() + 1).padStart(2, '0');
  const year = vDate.getFullYear();

  const partnerLabel = isReceipt ? 'Họ và tên người nộp tiền:' : 'Họ và tên người nhận tiền:';
  const partnerName = voucher.customerName 
    ? voucher.customerName 
    : voucher.supplierName 
    ? voucher.supplierName 
    : (voucher.partnerName || 'Khách vãng lai / Đối tác');

  const partnerAddress = voucher.customerAddress || voucher.supplierAddress || voucher.address || '—';
  const reason = voucher.notes || (isReceipt ? 'Thu tiền công nợ khách hàng' : 'Chi trả tiền cho nhà cung cấp/khách hàng');
  const amount = Number(voucher.amount || 0);
  const amountStr = formatVND(amount);
  const amountInWords = numberToWordsVN(amount);
  const store = parseOwner(ownerInfo);

  const methodLabel = voucher.method === 'bank_transfer' 
    ? 'Chuyển khoản ngân hàng' 
    : voucher.method === 'card' 
    ? 'Quẹt thẻ' 
    : 'Tiền mặt';

  return `
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>${title} - ${voucherNum}</title>
  <style>
    @page {
      size: A5 landscape;
      margin: 10mm 15mm;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: "Times New Roman", Times, serif;
      font-size: 13pt;
      color: #000000;
      line-height: 1.45;
      background: #ffffff;
      padding: 10px;
    }
    .voucher-container {
      max-width: 820px;
      margin: 0 auto;
    }
    .header-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 8px;
    }
    .header-table td {
      vertical-align: top;
    }
    .unit-info {
      width: 58%;
      text-align: left;
    }
    .unit-name {
      font-size: 11pt;
      font-weight: bold;
      text-transform: uppercase;
      margin-bottom: 2px;
    }
    .unit-detail {
      font-size: 9.5pt;
      color: #333;
    }
    .form-info {
      width: 42%;
      text-align: center;
    }
    .form-code {
      font-size: 10pt;
      font-weight: bold;
    }
    .form-circular {
      font-size: 8.5pt;
      font-style: italic;
    }
    .voucher-number {
      font-size: 10.5pt;
      margin-top: 4px;
      font-weight: 600;
    }
    .title-section {
      text-align: center;
      margin: 10px 0 14px 0;
    }
    .voucher-title {
      font-size: 18pt;
      font-weight: bold;
      letter-spacing: 1.5px;
    }
    .voucher-date {
      font-size: 11pt;
      font-style: italic;
      margin-top: 3px;
    }
    .content-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 14px;
    }
    .content-table td {
      padding: 3.5px 0;
      font-size: 11.5pt;
      vertical-align: baseline;
    }
    .content-label {
      width: 220px;
      white-space: nowrap;
    }
    .content-val {
      font-weight: 500;
      border-bottom: 1px dotted #888;
      padding-left: 6px;
    }
    .strong-val {
      font-weight: bold;
    }
    .amount-highlight {
      font-size: 12.5pt;
      font-weight: bold;
    }
    .signatures-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 15px;
      page-break-inside: avoid;
    }
    .signatures-table td {
      width: 20%;
      text-align: center;
      vertical-align: top;
      padding: 2px;
    }
    .sig-title {
      font-weight: bold;
      font-size: 10.5pt;
      margin-bottom: 2px;
    }
    .sig-sub {
      font-style: italic;
      font-size: 9pt;
      color: #555;
    }
    .sig-space {
      height: 65px;
    }
    .sig-name {
      font-weight: 600;
      font-size: 10pt;
    }
    .receipt-note {
      margin-top: 12px;
      font-size: 10pt;
      font-style: italic;
      border-top: 1px dashed #aaa;
      padding-top: 6px;
    }
    @media print {
      body {
        padding: 0;
      }
      .no-print, .no-print * {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="voucher-container">
    <table class="header-table">
      <tr>
        <td class="unit-info">
          <div class="unit-name">${store.storeName}</div>
          ${store.storeAddress ? `<div class="unit-detail">Đ/C: ${store.storeAddress}</div>` : ''}
          ${store.storePhone ? `<div class="unit-detail">SĐT: ${store.storePhone}</div>` : ''}
        </td>
        <td class="form-info">
          <div class="form-code">${formCode}</div>
          <div class="form-circular">(Ban hành theo TT số 200/2014/TT-BTC)</div>
          <div class="voucher-number">Số: <strong>${voucherNum}</strong></div>
        </td>
      </tr>
    </table>

    <div class="title-section">
      <div class="voucher-title">${title}</div>
      <div class="voucher-date">Ngày ${day} tháng ${month} năm ${year} (${hours}:${minutes})</div>
    </div>

    <table class="content-table">
      <tr>
        <td class="content-label">${partnerLabel}</td>
        <td class="content-val strong-val">${partnerName}</td>
      </tr>
      <tr>
        <td class="content-label">Địa chỉ:</td>
        <td class="content-val">${partnerAddress}</td>
      </tr>
      <tr>
        <td class="content-label">Lý do ${isReceipt ? 'nộp' : 'chi'}:</td>
        <td class="content-val">${reason}</td>
      </tr>
      <tr>
        <td class="content-label">Số tiền:</td>
        <td class="content-val strong-val amount-highlight">${amountStr}</td>
      </tr>
      <tr>
        <td class="content-label">Viết bằng chữ:</td>
        <td class="content-val" style="font-style: italic; font-weight: 600;">${amountInWords}</td>
      </tr>
      <tr>
        <td class="content-label">Hình thức thanh toán:</td>
        <td class="content-val">${methodLabel}</td>
      </tr>
      <tr>
        <td class="content-label">Kèm theo:</td>
        <td class="content-val">Chứng từ gốc liên quan</td>
      </tr>
    </table>

    <table class="signatures-table">
      <tr>
        <td>
          <div class="sig-title">Thủ trưởng đơn vị</div>
          <div class="sig-sub">(Ký, họ tên, đóng dấu)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-title">Kế toán trưởng</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-title">${isReceipt ? 'Người nộp tiền' : 'Người nhận tiền'}</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
          <div class="sig-name">${partnerName}</div>
        </td>
        <td>
          <div class="sig-title">Người lập phiếu</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
        <td>
          <div class="sig-title">Thủ quỹ</div>
          <div class="sig-sub">(Ký, họ tên)</div>
          <div class="sig-space"></div>
        </td>
      </tr>
    </table>

    <div class="receipt-note">
      + Đã nhận đủ số tiền (viết bằng chữ): <strong>${amountInWords}</strong>
    </div>
  </div>
</body>
</html>
  `;
}

/**
 * Chèn thanh công cụ in tiện lợi và script tự động kích hoạt in vào nội dung HTML.
 * Thanh công cụ được ẩn khi in bằng CSS @media print.
 */
function preparePrintHtml(htmlContent) {
  const toolbarAndScript = `
  <style>
    @media print {
      .print-actions-toolbar,
      .print-actions-toolbar * {
        display: none !important;
      }
    }
    .print-actions-toolbar {
      position: fixed;
      top: 14px;
      right: 14px;
      display: flex;
      align-items: center;
      gap: 8px;
      z-index: 999999;
      background: rgba(255, 255, 255, 0.98);
      padding: 8px 12px;
      border-radius: 8px;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
      border: 1px solid #cbd5e1;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    .print-actions-toolbar button {
      padding: 7px 14px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 500;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      border: 1px solid transparent;
      transition: all 0.15s ease;
    }
    .print-actions-toolbar .btn-print-now {
      background: #0284c7;
      color: #ffffff;
    }
    .print-actions-toolbar .btn-print-now:hover {
      background: #0369a1;
    }
    .print-actions-toolbar .btn-close-tab {
      background: #f1f5f9;
      color: #334155;
      border-color: #cbd5e1;
    }
    .print-actions-toolbar .btn-close-tab:hover {
      background: #e2e8f0;
    }
  </style>

  <div class="print-actions-toolbar no-print">
    <button class="btn-print-now" onclick="window.focus(); window.print();" title="Bấm để in lại nếu bạn vô tình đóng hộp thoại in">
      🖨️ In Phiếu (Ctrl + P)
    </button>
    <button class="btn-close-tab" onclick="window.close();" title="Đóng tab in này">
      ✕ Đóng tab
    </button>
  </div>

  <script>
    (function() {
      var triggered = false;
      function launchPrint() {
        if (triggered) return;
        triggered = true;
        setTimeout(function() {
          try {
            window.focus();
            window.print();
          } catch (e) {
            console.error('Print trigger error:', e);
          }
        }, 350);
      }

      if (document.readyState === 'complete' || document.readyState === 'interactive') {
        launchPrint();
      } else {
        window.addEventListener('DOMContentLoaded', launchPrint);
        window.addEventListener('load', launchPrint);
      }
    })();
  </script>
  `;

  if (htmlContent.includes('</body>')) {
    return htmlContent.replace('</body>', `${toolbarAndScript}</body>`);
  }
  return htmlContent + toolbarAndScript;
}

/**
 * Mở trang in ở tab trình duyệt mới một cách hoàn toàn ĐỘC LẬP (Decoupled Browsing Context).
 * Sử dụng Blob URL với rel="noopener noreferrer" để cắt đứt liên kết window.opener với trang gốc.
 * Điều này đảm bảo trang web cũ HOÀN TOÀN TƯƠNG TÁC ĐƯỢC BÌNH THƯỜNG (không bị đơ, không bị freeze giao diện)
 * ngay cả khi hộp thoại in đang mở ở tab mới.
 */
export function printInNewTab(htmlContent) {
  try {
    const fullHtml = preparePrintHtml(htmlContent);

    // Sử dụng Blob URL kết hợp liên kết rel="noopener noreferrer"
    // Cắt đứt quan hệ window.opener để Chromium không khóa (freeze) event loop của tab gốc
    const blob = new Blob([fullHtml], { type: 'text/html;charset=utf-8' });
    const blobUrl = URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = blobUrl;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();

    // Thu hồi bộ nhớ và dọn dẹp sau 60 giây
    setTimeout(() => {
      try {
        if (link.parentNode) {
          link.parentNode.removeChild(link);
        }
        URL.revokeObjectURL(blobUrl);
      } catch (_) {}
    }, 60000);

    return true;
  } catch (err) {
    console.error('Lỗi khi mở tab in tách biệt, chuyển sang fallback:', err);
    try {
      const fullHtml = preparePrintHtml(htmlContent);
      const printWindow = window.open('', '_blank');
      if (!printWindow) {
        alert('Vui lòng cho phép trình duyệt mở tab mới (Pop-up) để in hóa đơn.');
        return false;
      }
      try {
        printWindow.opener = null;
      } catch (_) {}
      printWindow.document.open();
      printWindow.document.write(fullHtml);
      printWindow.document.close();
      return true;
    } catch (fallbackErr) {
      console.error('Fallback print error:', fallbackErr);
      return false;
    }
  }
}

/**
 * Tùy chọn In trực tiếp qua iframe ẩn trên trang hiện tại (không cần mở tab mới)
 */
export function printDirect(htmlContent) {
  try {
    let iframe = document.getElementById('__app_silent_print_frame__');
    if (!iframe) {
      iframe = document.createElement('iframe');
      iframe.id = '__app_silent_print_frame__';
      iframe.style.position = 'fixed';
      iframe.style.top = '-9999px';
      iframe.style.left = '-9999px';
      iframe.style.width = '1px';
      iframe.style.height = '1px';
      iframe.style.opacity = '0';
      iframe.style.border = 'none';
      iframe.style.pointerEvents = 'none';
      document.body.appendChild(iframe);
    }

    const doc = iframe.contentWindow || iframe.contentDocument;
    const iframeDoc = doc.document || doc;
    iframeDoc.open();
    iframeDoc.write(htmlContent);
    iframeDoc.close();

    setTimeout(() => {
      iframe.contentWindow.focus();
      iframe.contentWindow.print();
    }, 300);

    return true;
  } catch (err) {
    console.error('In trực tiếp thất bại, chuyển sang mở tab mới:', err);
    return printInNewTab(htmlContent);
  }
}

