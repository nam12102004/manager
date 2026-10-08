import { formatVND, formatDate, numberToWordsVN } from './formatters';

/**
 * Generate standard Vietnamese accounting voucher HTML (Mẫu 01-TT cho Phiếu Thu, Mẫu 02-TT cho Phiếu Chi)
 */
export function generateVoucherHtml({ voucher, type = 'receipt', ownerInfo = null }) {
  const isReceipt = type === 'receipt';
  const title = isReceipt ? 'PHIẾU THU' : 'PHIẾU CHI';
  const formCode = isReceipt ? 'Mẫu số 01 - TT' : 'Mẫu số 02 - TT';
  const voucherNum = isReceipt ? (voucher.receiptNumber || voucher.id) : (voucher.paymentNumber || voucher.id);
  
  // Date calculation
  const vDate = voucher.date ? new Date(voucher.date) : new Date();
  const day = String(vDate.getDate()).padStart(2, '0');
  const month = String(vDate.getMonth() + 1).padStart(2, '0');
  const year = vDate.getFullYear();

  // Partner info
  const partnerLabel = isReceipt ? 'Họ và tên người nộp tiền:' : 'Họ và tên người nhận tiền:';
  const partnerName = voucher.customerName 
    ? voucher.customerName 
    : voucher.supplierName 
    ? voucher.supplierName 
    : (voucher.partnerName || 'Khách vãng lai / Đối tác');

  const partnerAddress = voucher.customerAddress || voucher.supplierAddress || voucher.address || '—';
  
  // Reason & amounts
  const reason = voucher.notes || (isReceipt ? 'Thu tiền công nợ khách hàng' : 'Chi trả tiền cho nhà cung cấp/khách hàng');
  const amount = Number(voucher.amount || 0);
  const amountStr = formatVND(amount);
  const amountInWords = numberToWordsVN(amount);

  // Store information
  let storeName = 'CỬA HÀNG / KHO HÀNG PHÂN PHỐI';
  let storeAddress = '';
  let storePhone = '';

  if (ownerInfo) {
    if (typeof ownerInfo === 'string') {
      try {
        const parsed = JSON.parse(ownerInfo);
        storeName = parsed.storeName || storeName;
        storeAddress = parsed.storeAddress || '';
        storePhone = parsed.storePhone || '';
      } catch {
        storeName = ownerInfo;
      }
    } else if (typeof ownerInfo === 'object') {
      storeName = ownerInfo.storeName || ownerInfo.info || storeName;
      storeAddress = ownerInfo.storeAddress || '';
      storePhone = ownerInfo.storePhone || '';
    }
  }

  // Payment method
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
      .no-print {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="voucher-container">
    <!-- Header -->
    <table class="header-table">
      <tr>
        <td class="unit-info">
          <div class="unit-name">${storeName}</div>
          ${storeAddress ? `<div class="unit-detail">Đ/C: ${storeAddress}</div>` : ''}
          ${storePhone ? `<div class="unit-detail">SĐT: ${storePhone}</div>` : ''}
        </td>
        <td class="form-info">
          <div class="form-code">${formCode}</div>
          <div class="form-circular">(Ban hành theo TT số 200/2014/TT-BTC)</div>
          <div class="voucher-number">Số: <strong>${voucherNum}</strong></div>
        </td>
      </tr>
    </table>

    <!-- Title -->
    <div class="title-section">
      <div class="voucher-title">${title}</div>
      <div class="voucher-date">Ngày ${day} tháng ${month} năm ${year}</div>
    </div>

    <!-- Body Information -->
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

    <!-- Signatures -->
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

    <!-- Receipt Acknowledgement -->
    <div class="receipt-note">
      + Đã nhận đủ số tiền (viết bằng chữ): <strong>${amountInWords}</strong>
    </div>
  </div>
</body>
</html>
  `;
}

/**
 * Print voucher asynchronously via an isolated hidden iframe.
 * Does NOT freeze React, does NOT disrupt open modals or state.
 * Returns a promise that resolves when print dialog opens or finishes.
 */
export function printVoucherViaIframe({ voucher, type = 'receipt', ownerInfo = null }) {
  return new Promise((resolve) => {
    try {
      const html = generateVoucherHtml({ voucher, type, ownerInfo });

      // Create an invisible iframe
      const iframe = document.createElement('iframe');
      iframe.style.position = 'fixed';
      iframe.style.right = '0';
      iframe.style.bottom = '0';
      iframe.style.width = '0';
      iframe.style.height = '0';
      iframe.style.border = 'none';
      iframe.setAttribute('title', 'Voucher Print Window');

      document.body.appendChild(iframe);

      const doc = iframe.contentWindow?.document || iframe.contentDocument;
      if (!doc) {
        document.body.removeChild(iframe);
        resolve(false);
        return;
      }

      doc.open();
      doc.write(html);
      doc.close();

      // Ensure content is loaded and styles evaluated before printing
      setTimeout(() => {
        try {
          iframe.contentWindow?.focus();
          iframe.contentWindow?.print();
        } catch (printErr) {
          console.error('Error invoking print dialog:', printErr);
        } finally {
          // Remove iframe safely after a delay to ensure print dialog finishes opening
          setTimeout(() => {
            if (document.body.contains(iframe)) {
              document.body.removeChild(iframe);
            }
            resolve(true);
          }, 1500);
        }
      }, 350);
    } catch (err) {
      console.error('Failed to print voucher via iframe:', err);
      resolve(false);
    }
  });
}
