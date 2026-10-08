import React, { useState } from 'react';
import { Printer, Check, X } from 'lucide-react';
import Modal from './Modal';
import { formatVND, formatDate, numberToWordsVN } from '../../utils/formatters';
import { printVoucherViaIframe } from '../../utils/printVoucher';
import { useNotification } from '../../context/NotificationContext';

export default function PrintVoucherModal({
  isOpen,
  onClose,
  voucher,
  type = 'receipt', // 'receipt' | 'payment'
  ownerInfo = null,
}) {
  const notify = useNotification();
  const [printing, setPrinting] = useState(false);

  if (!voucher) return null;

  const isReceipt = type === 'receipt';
  const title = isReceipt ? 'PHIẾU THU' : 'PHIẾU CHI';
  const formCode = isReceipt ? 'Mẫu số 01 - TT' : 'Mẫu số 02 - TT';
  const voucherNum = isReceipt ? (voucher.receiptNumber || voucher.id) : (voucher.paymentNumber || voucher.id);

  const vDate = voucher.date ? new Date(voucher.date) : new Date();
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
  const reason = voucher.notes || (isReceipt ? 'Thu tiền công nợ khách hàng' : 'Chi trả tiền đối tác/khách hàng');
  const amount = Number(voucher.amount || 0);
  const amountStr = formatVND(amount);
  const amountInWords = numberToWordsVN(amount);

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

  const methodLabel = voucher.method === 'bank_transfer' 
    ? 'Chuyển khoản ngân hàng' 
    : voucher.method === 'card' 
    ? 'Quẹt thẻ' 
    : 'Tiền mặt';

  const handlePrint = async () => {
    setPrinting(true);
    try {
      await printVoucherViaIframe({ voucher, type, ownerInfo });
      notify.success(`Đã gửi lệnh in cho ${voucherNum}`);
    } catch (err) {
      console.error('Print error:', err);
      notify.error('Không thể kích hoạt hộp thoại in');
    } finally {
      setPrinting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Xem trước & In ${title} (${voucherNum})`}
      size="lg"
      footer={
        <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center' }}>
          <span style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
            Khổ in tối ưu: Khổ A5 hoặc A4 ngang
          </span>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button className="btn btn-outline" onClick={onClose} disabled={printing}>
              Đóng
            </button>
            <button className="btn btn-primary" onClick={handlePrint} disabled={printing}>
              <Printer size={16} />
              <span>{printing ? 'Đang mở máy in...' : 'In Phiếu'}</span>
            </button>
          </div>
        </div>
      }
    >
      <div
        style={{
          background: '#ffffff',
          color: '#1a1a1a',
          padding: '1.5rem',
          borderRadius: 'var(--radius-md)',
          boxShadow: '0 2px 10px rgba(0,0,0,0.08)',
          fontFamily: '"Times New Roman", Times, serif',
          fontSize: '13pt',
          lineHeight: '1.45',
          border: '1px solid #e2e8f0',
        }}
      >
        {/* Header Unit and Form info */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
          <div style={{ width: '58%' }}>
            <div style={{ fontSize: '11pt', fontWeight: 'bold', textTransform: 'uppercase' }}>
              {storeName}
            </div>
            {storeAddress && <div style={{ fontSize: '9.5pt', color: '#444' }}>Đ/C: {storeAddress}</div>}
            {storePhone && <div style={{ fontSize: '9.5pt', color: '#444' }}>SĐT: {storePhone}</div>}
          </div>
          <div style={{ width: '42%', textAlign: 'center' }}>
            <div style={{ fontSize: '10pt', fontWeight: 'bold' }}>{formCode}</div>
            <div style={{ fontSize: '8.5pt', fontStyle: 'italic' }}>(Ban hành theo TT số 200/2014/TT-BTC)</div>
            <div style={{ fontSize: '10.5pt', fontWeight: 600, marginTop: '3px' }}>
              Số: <strong>{voucherNum}</strong>
            </div>
          </div>
        </div>

        {/* Title Section */}
        <div style={{ textAlign: 'center', margin: '12px 0 16px 0' }}>
          <div style={{ fontSize: '18pt', fontWeight: 'bold', letterSpacing: '1.5px', color: '#0f172a' }}>
            {title}
          </div>
          <div style={{ fontSize: '11pt', fontStyle: 'italic', marginTop: '2px', color: '#475569' }}>
            Ngày {day} tháng {month} năm {year}
          </div>
        </div>

        {/* Details Table */}
        <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '16px' }}>
          <tbody>
            <tr>
              <td style={{ width: '210px', padding: '4px 0', fontSize: '11.5pt', whiteSpace: 'nowrap' }}>
                {partnerLabel}
              </td>
              <td style={{ padding: '4px 0 4px 6px', fontWeight: 'bold', borderBottom: '1px dotted #94a3b8' }}>
                {partnerName}
              </td>
            </tr>
            <tr>
              <td style={{ padding: '4px 0', fontSize: '11.5pt' }}>Địa chỉ:</td>
              <td style={{ padding: '4px 0 4px 6px', borderBottom: '1px dotted #94a3b8' }}>
                {partnerAddress}
              </td>
            </tr>
            <tr>
              <td style={{ padding: '4px 0', fontSize: '11.5pt' }}>Lý do {isReceipt ? 'nộp' : 'chi'}:</td>
              <td style={{ padding: '4px 0 4px 6px', borderBottom: '1px dotted #94a3b8' }}>
                {reason}
              </td>
            </tr>
            <tr>
              <td style={{ padding: '4px 0', fontSize: '11.5pt' }}>Số tiền:</td>
              <td style={{ padding: '4px 0 4px 6px', fontWeight: 'bold', fontSize: '12.5pt', color: '#0f172a', borderBottom: '1px dotted #94a3b8' }}>
                {amountStr}
              </td>
            </tr>
            <tr>
              <td style={{ padding: '4px 0', fontSize: '11.5pt' }}>Viết bằng chữ:</td>
              <td style={{ padding: '4px 0 4px 6px', fontStyle: 'italic', fontWeight: 600, borderBottom: '1px dotted #94a3b8' }}>
                {amountInWords}
              </td>
            </tr>
            <tr>
              <td style={{ padding: '4px 0', fontSize: '11.5pt' }}>Hình thức thanh toán:</td>
              <td style={{ padding: '4px 0 4px 6px', borderBottom: '1px dotted #94a3b8' }}>
                {methodLabel}
              </td>
            </tr>
            <tr>
              <td style={{ padding: '4px 0', fontSize: '11.5pt' }}>Kèm theo:</td>
              <td style={{ padding: '4px 0 4px 6px', borderBottom: '1px dotted #94a3b8' }}>
                Chứng từ gốc liên quan
              </td>
            </tr>
          </tbody>
        </table>

        {/* Signatures Section */}
        <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '16px' }}>
          <tbody>
            <tr>
              <td style={{ width: '20%', textAlign: 'center', verticalAlign: 'top' }}>
                <div style={{ fontWeight: 'bold', fontSize: '10.5pt' }}>Thủ trưởng đơn vị</div>
                <div style={{ fontStyle: 'italic', fontSize: '9pt', color: '#64748b' }}>(Ký, họ tên, đóng dấu)</div>
                <div style={{ height: '55px' }}></div>
              </td>
              <td style={{ width: '20%', textAlign: 'center', verticalAlign: 'top' }}>
                <div style={{ fontWeight: 'bold', fontSize: '10.5pt' }}>Kế toán trưởng</div>
                <div style={{ fontStyle: 'italic', fontSize: '9pt', color: '#64748b' }}>(Ký, họ tên)</div>
                <div style={{ height: '55px' }}></div>
              </td>
              <td style={{ width: '20%', textAlign: 'center', verticalAlign: 'top' }}>
                <div style={{ fontWeight: 'bold', fontSize: '10.5pt' }}>{isReceipt ? 'Người nộp tiền' : 'Người nhận tiền'}</div>
                <div style={{ fontStyle: 'italic', fontSize: '9pt', color: '#64748b' }}>(Ký, họ tên)</div>
                <div style={{ height: '55px' }}></div>
                <div style={{ fontSize: '10pt', fontWeight: 600 }}>{partnerName}</div>
              </td>
              <td style={{ width: '20%', textAlign: 'center', verticalAlign: 'top' }}>
                <div style={{ fontWeight: 'bold', fontSize: '10.5pt' }}>Người lập phiếu</div>
                <div style={{ fontStyle: 'italic', fontSize: '9pt', color: '#64748b' }}>(Ký, họ tên)</div>
                <div style={{ height: '55px' }}></div>
              </td>
              <td style={{ width: '20%', textAlign: 'center', verticalAlign: 'top' }}>
                <div style={{ fontWeight: 'bold', fontSize: '10.5pt' }}>Thủ quỹ</div>
                <div style={{ fontStyle: 'italic', fontSize: '9pt', color: '#64748b' }}>(Ký, họ tên)</div>
                <div style={{ height: '55px' }}></div>
              </td>
            </tr>
          </tbody>
        </table>

        {/* Note */}
        <div style={{ marginTop: '12px', fontSize: '10pt', fontStyle: 'italic', borderTop: '1px dashed #cbd5e1', paddingTop: '6px', color: '#334155' }}>
          + Đã nhận đủ số tiền (viết bằng chữ): <strong>{amountInWords}</strong>
        </div>
      </div>
    </Modal>
  );
}
