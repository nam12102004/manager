import React from 'react';
import {
  FileSpreadsheet,
  Download,
  Loader2,
  CheckCircle2,
  AlertCircle,
  X,
  ChevronDown,
  ChevronUp,
  RefreshCw,
  Clock,
} from 'lucide-react';
import { useExport } from '../../context/ExportContext';
import { formatNumber } from '../../utils/formatters';

export default function FloatingExportWidget() {
  const {
    jobs,
    downloadJob,
    dismissJob,
    clearCompletedJobs,
    isWidgetVisible,
    setIsWidgetVisible,
    isWidgetExpanded,
    setIsWidgetExpanded,
  } = useExport();

  if (!isWidgetVisible || jobs.length === 0) {
    return null;
  }

  const activeCount = jobs.filter(
    (j) => j.status === 'queued' || j.status === 'processing'
  ).length;

  const formatBytes = (bytes) => {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };

  return (
    <div
      style={{
        position: 'fixed',
        bottom: '24px',
        right: '24px',
        width: isWidgetExpanded ? '380px' : 'auto',
        maxWidth: 'calc(100vw - 32px)',
        zIndex: 9999,
        background: 'var(--bg-card, #ffffff)',
        border: '1px solid var(--border-color, #e2e8f0)',
        borderRadius: '12px',
        boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.2), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
        overflow: 'hidden',
        transition: 'all 0.25s ease',
        color: 'var(--text-primary, #1e293b)',
        fontFamily: 'inherit',
      }}
    >
      {/* Widget Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '10px 14px',
          background: 'var(--bg-secondary, #f8fafc)',
          borderBottom: isWidgetExpanded ? '1px solid var(--border-color, #e2e8f0)' : 'none',
          cursor: 'pointer',
          userSelect: 'none',
        }}
        onClick={() => setIsWidgetExpanded(!isWidgetExpanded)}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {activeCount > 0 ? (
            <Loader2 size={18} className="animate-spin" color="var(--primary, #3b82f6)" />
          ) : (
            <FileSpreadsheet size={18} color="var(--success, #10b981)" />
          )}
          <span style={{ fontWeight: 600, fontSize: '0.875rem' }}>
            {activeCount > 0 ? `Đang xuất Excel · ${activeCount}` : 'Xuất Excel hoàn tất'}
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setIsWidgetExpanded(!isWidgetExpanded);
            }}
            style={{
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              color: 'var(--text-muted, #64748b)',
              padding: '4px',
              display: 'flex',
              alignItems: 'center',
            }}
            title={isWidgetExpanded ? 'Thu gọn' : 'Mở rộng'}
          >
            {isWidgetExpanded ? <ChevronDown size={16} /> : <ChevronUp size={16} />}
          </button>

          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              if (activeCount > 0) {
                // If jobs are active, just hide widget from view
                setIsWidgetVisible(false);
              } else {
                clearCompletedJobs();
              }
            }}
            style={{
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              color: 'var(--text-muted, #64748b)',
              padding: '4px',
              display: 'flex',
              alignItems: 'center',
            }}
            title="Đóng bảng thông báo"
          >
            <X size={16} />
          </button>
        </div>
      </div>

      {/* Widget Body */}
      {isWidgetExpanded && (
        <div
          style={{
            maxHeight: '340px',
            overflowY: 'auto',
            padding: '12px',
            display: 'flex',
            flexDirection: 'column',
            gap: '10px',
          }}
        >
          {jobs.map((job) => {
            const isFinished = job.status === 'completed';
            const isFailed = job.status === 'failed';
            const isProcessing = job.status === 'processing' || job.status === 'queued';

            return (
              <div
                key={job.jobId}
                style={{
                  padding: '10px 12px',
                  borderRadius: '8px',
                  background: 'var(--bg-primary, #ffffff)',
                  border: '1px solid var(--border-color, #e2e8f0)',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '6px',
                  fontSize: '0.8125rem',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '8px' }}>
                  <div style={{ fontWeight: 600, color: 'var(--text-primary)', lineHeight: 1.3 }}>
                    {job.title}
                  </div>
                  <button
                    type="button"
                    onClick={() => dismissJob(job.jobId)}
                    style={{
                      background: 'transparent',
                      border: 'none',
                      cursor: 'pointer',
                      color: 'var(--text-muted)',
                      padding: '2px',
                    }}
                    title="Xóa thông báo này"
                  >
                    <X size={14} />
                  </button>
                </div>

                {/* Status text & Progress */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                    {isProcessing && <Clock size={13} color="var(--primary)" />}
                    {isFinished && <CheckCircle2 size={13} color="var(--success, #10b981)" />}
                    {isFailed && <AlertCircle size={13} color="var(--danger, #ef4444)" />}
                    <span>{job.message || (isFinished ? 'Hoàn tất' : 'Đang xử lý')}</span>
                  </div>
                  <span style={{ fontWeight: 700, color: isFinished ? 'var(--success, #10b981)' : 'var(--text-primary)' }}>
                    {job.progressPercentage || 0}%
                  </span>
                </div>

                {/* Progress bar */}
                <div
                  style={{
                    width: '100%',
                    height: '6px',
                    backgroundColor: 'var(--bg-secondary, #e2e8f0)',
                    borderRadius: '3px',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      width: `${Math.min(100, Math.max(0, job.progressPercentage || 0))}%`,
                      height: '100%',
                      backgroundColor: isFailed
                        ? 'var(--danger, #ef4444)'
                        : isFinished
                        ? 'var(--success, #10b981)'
                        : 'var(--primary, #3b82f6)',
                      transition: 'width 0.4s ease',
                    }}
                  />
                </div>

                {/* Completed Details & Download Button */}
                {isFinished && (
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      marginTop: '4px',
                      paddingTop: '6px',
                      borderTop: '1px dashed var(--border-color, #e2e8f0)',
                    }}
                  >
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      {job.fileSize ? formatBytes(job.fileSize) : 'Sẵn sàng'}
                    </span>
                    <button
                      type="button"
                      className="btn btn-primary"
                      onClick={() => downloadJob(job.jobId, job.fileName)}
                      style={{
                        padding: '4px 10px',
                        fontSize: '0.75rem',
                        gap: '4px',
                        height: 'auto',
                      }}
                    >
                      <Download size={13} />
                      <span>Tải file</span>
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
