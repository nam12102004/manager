import React, { useState, useEffect } from 'react';
import {
  Settings as SettingsIcon,
  Building,
  CreditCard,
  QrCode,
  Save,
  RefreshCw,
  Phone,
  MapPin,
  CheckCircle,
} from 'lucide-react';
import { useNotification } from '../context/NotificationContext';
import { settingService } from '../services';

export default function Settings() {
  const notify = useNotification();

  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  // Form Fields
  const [storeName, setStoreName] = useState('KHO HÀNG & PHÂN PHỐI TỔNG HỢP');
  const [storePhone, setStorePhone] = useState('0988.123.456');
  const [storeAddress, setStoreAddress] = useState('123 Đường Số 7, KCN Vĩnh Lộc, Bình Chánh, TP.HCM');
  const [bankName, setBankName] = useState('MB');
  const [bankAccount, setBankAccount] = useState('0988123456');
  const [accountHolder, setAccountHolder] = useState('NGUYEN VAN ADMIN');
  const [rawInfo, setRawInfo] = useState('');

  const loadOwnerInfo = async () => {
    setLoading(true);
    try {
      const data = await settingService.getSettings();
      if (data.storeName) setStoreName(data.storeName);
      if (data.storePhone) setStorePhone(data.storePhone);
      if (data.storeAddress) setStoreAddress(data.storeAddress);
      if (data.bankName) setBankName(data.bankName);
      if (data.bankAccount) setBankAccount(data.bankAccount);
      if (data.accountHolder) setAccountHolder(data.accountHolder);
      if (data.rawInfo) setRawInfo(data.rawInfo);
    } catch (err) {
      console.warn('Owner info not yet set:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadOwnerInfo();
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await settingService.saveSettings({
        storeName,
        storePhone,
        storeAddress,
        bankName,
        bankAccount,
        accountHolder,
      });

      notify.success('Cập nhật thông tin cửa hàng thành công!');
      loadOwnerInfo();
    } catch (err) {
      notify.error(err.message || 'Lỗi khi lưu thông tin');
    } finally {
      setSubmitting(false);
    }
  };

  // VietQR dynamic image URL
  const qrUrl = `https://img.vietqr.io/image/${encodeURIComponent(bankName)}-${encodeURIComponent(bankAccount)}-compact2.png?amount=0&addInfo=Thanh%20toan%20tien%20hang&accountName=${encodeURIComponent(accountHolder)}`;

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1 className="page-title">
            <SettingsIcon size={28} color="var(--primary)" />
            <span>Cài Đặt Cửa Hàng & Chủ Tài Khoản</span>
          </h1>
          <p className="page-subtitle">
            Cấu hình thông tin in trên hóa đơn bán hàng và tài khoản nhận thanh toán chuyển khoản VietQR
          </p>
        </div>
        <div className="page-actions">
          <button className="btn btn-outline" onClick={loadOwnerInfo} disabled={loading}>
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            <span>Tải lại</span>
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '1.5rem' }}>
        {/* Left Form: Store Info */}
        <div className="glass-card" style={{ padding: '1.75rem' }}>
          <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Building size={20} color="var(--primary)" />
            <span>Thông Tin Doanh Nghiệp / Kho Hàng</span>
          </h3>

          <form onSubmit={handleSave}>
            <div className="form-group">
              <label className="form-label">
                Tên Cửa Hàng / Đơn Vị Bán Hàng <span className="req">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                value={storeName}
                onChange={(e) => setStoreName(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số Điện Thoại Hotline / Zalo</label>
              <div className="input-with-icon">
                <Phone className="input-icon" size={16} />
                <input
                  type="text"
                  className="form-input mono"
                  value={storePhone}
                  onChange={(e) => setStorePhone(e.target.value)}
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Địa Chỉ Kho Hàng / Văn Phòng</label>
              <div className="input-with-icon">
                <MapPin className="input-icon" size={16} />
                <input
                  type="text"
                  className="form-input"
                  value={storeAddress}
                  onChange={(e) => setStoreAddress(e.target.value)}
                />
              </div>
            </div>

            <div style={{ height: '1px', backgroundColor: 'var(--border-color)', margin: '1.5rem 0' }} />

            <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <CreditCard size={20} color="var(--success)" />
              <span>Tài Khoản Ngân Hàng Thụ Hưởng</span>
            </h3>

            <div className="form-group">
              <label className="form-label">Ngân Hàng</label>
              <input
                type="text"
                className="form-input mono"
                placeholder="VD: MB, VCB, TCB, ACB, VPB, ICB..."
                value={bankName}
                onChange={(e) => setBankName(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số Tài Khoản</label>
              <input
                type="text"
                className="form-input mono"
                value={bankAccount}
                onChange={(e) => setBankAccount(e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Tên Chủ Tài Khoản</label>
              <input
                type="text"
                className="form-input mono"
                value={accountHolder}
                onChange={(e) => setAccountHolder(e.target.value.toUpperCase())}
                required
              />
            </div>

            <button
              type="submit"
              className="btn btn-primary btn-lg"
              style={{ width: '100%', marginTop: '1.25rem' }}
              disabled={submitting}
            >
              <Save size={18} />
              <span>{submitting ? 'Đang lưu...' : 'Lưu Thông Tin Cấu Hình'}</span>
            </button>
          </form>
        </div>

        {/* Right Preview: VietQR & Invoice Preview */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {/* VietQR Card */}
          <div className="glass-card" style={{ padding: '1.75rem', textAlign: 'center' }}>
            <h3 style={{ fontSize: '1.0625rem', fontWeight: 700, marginBottom: '0.5rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
              <QrCode size={20} color="var(--primary)" />
              <span>Mã QR Chuyển Khoản Nhanh</span>
            </h3>
            <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', marginBottom: '1.25rem' }}>
              Khách hàng có thể quét mã này bằng bất kỳ ứng dụng ngân hàng nào để thanh toán tiền hàng.
            </p>

            <div
              style={{
                display: 'inline-block',
                background: '#ffffff',
                padding: '1rem',
                borderRadius: 'var(--radius-lg)',
                boxShadow: 'var(--shadow-md)',
                maxWidth: '260px',
                width: '100%',
              }}
            >
              <img
                src={qrUrl}
                alt="VietQR Chuyển Khoản"
                style={{ width: '100%', height: 'auto', display: 'block', borderRadius: 'var(--radius-md)' }}
                onError={(e) => {
                  e.target.style.display = 'none';
                }}
              />
            </div>

            <div style={{ marginTop: '1rem', fontSize: '0.875rem' }}>
              <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{accountHolder}</div>
              <div className="mono" style={{ color: 'var(--primary)', fontWeight: 600 }}>
                {bankAccount} - {bankName}
              </div>
            </div>
          </div>

          {/* Quick Info Box */}
          <div className="glass-card" style={{ padding: '1.5rem' }}>
            <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.75rem' }}>
              Kiến Trúc & Quy Ước Hệ Thống
            </h4>
            <ul style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', display: 'flex', flexDirection: 'column', gap: '0.5rem', paddingLeft: '1.25rem' }}>
              <li>
                <strong>Quy ước công nợ:</strong> <code>Debt &gt; 0</code> là Phải thu khách hàng, <code>Debt &lt; 0</code> là Phải trả nhà cung cấp.
              </li>
              <li>
                <strong>3 Kho độc lập:</strong> Tồn kho được quản lý riêng biệt tại Kho 1, Kho 2, Kho 3.
              </li>
              <li>
                <strong>Bảo toàn sổ cái:</strong> Mọi biến động kho và công nợ đều được ghi nhật ký tự động vào Sổ kho và Sổ nợ.
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
