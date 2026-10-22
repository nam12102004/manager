import React, { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';
import { excelExportService } from '../services/excelExportService';
import { useNotification } from './NotificationContext';

const ExportContext = createContext(null);

export function ExportProvider({ children }) {
  const notify = useNotification();
  const [jobs, setJobs] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalConfig, setModalConfig] = useState(null);
  const [isWidgetVisible, setIsWidgetVisible] = useState(true);
  const [isWidgetExpanded, setIsWidgetExpanded] = useState(true);

  const jobsRef = useRef(jobs);
  jobsRef.current = jobs;

  // Poll running jobs every 1500ms
  useEffect(() => {
    const activeJobs = jobs.filter(
      (j) => j.status === 'queued' || j.status === 'processing'
    );

    if (activeJobs.length === 0) return;

    const interval = setInterval(async () => {
      for (const job of activeJobs) {
        try {
          const statusDto = await excelExportService.getStatus(job.jobId);
          if (!statusDto) continue;

          setJobs((prev) =>
            prev.map((item) => {
              if (item.jobId !== job.jobId) return item;
              return {
                ...item,
                status: statusDto.status,
                progressPercentage: statusDto.progressPercentage,
                message: statusDto.message || item.message,
                fileName: statusDto.fileName || item.fileName,
                fileSize: statusDto.fileSize || item.fileSize,
                error: statusDto.error,
              };
            })
          );

          if (statusDto.status === 'completed') {
            const targetFileName = job.customFileName || job.fileName || statusDto.fileName || 'BaoCao_Export.xlsx';
            notify.success(`Đã xuất xong file: ${targetFileName}! Đang tải về...`);
            // Auto download on completion
            try {
              await excelExportService.downloadFile(job.jobId, targetFileName, job.customFileName);
            } catch (dlErr) {
              console.error('Auto download error:', dlErr);
            }
          } else if (statusDto.status === 'failed') {
            notify.error(`Lỗi khi xuất Excel: ${statusDto.message || 'Không thể tạo file'}`);
          }
        } catch (err) {
          console.error(`Error polling status for job ${job.jobId}:`, err);
        }
      }
    }, 1500);

    return () => clearInterval(interval);
  }, [jobs, notify]);

  const openExportModal = useCallback((config = null) => {
    setModalConfig(config);
    setIsModalOpen(true);
  }, []);

  const closeExportModal = useCallback(() => {
    setIsModalOpen(false);
    setModalConfig(null);
  }, []);

  const startReportExport = useCallback(
    async (requestDto, customTitle = 'Báo cáo Excel', customFileName = null) => {
      try {
        const res = await excelExportService.startReport(requestDto);
        if (!res || !res.jobId) {
          throw new Error('Máy chủ không phản hồi mã tác vụ (JobId)');
        }

        const newJob = {
          jobId: res.jobId,
          title: customTitle,
          type: requestDto.reportType || 'report',
          status: res.status || 'queued',
          progressPercentage: res.progressPercentage || 0,
          message: res.message || 'Đang chuẩn bị hàng đợi...',
          fileName: customFileName || res.fileName,
          customFileName: customFileName,
          createdAt: new Date(),
        };

        setJobs((prev) => [newJob, ...prev]);
        setIsWidgetVisible(true);
        setIsWidgetExpanded(true);
        notify.info('Đã bắt đầu tác vụ xuất ngầm. Bạn có thể tiếp tục làm việc bình thường!');
        return res;
      } catch (err) {
        notify.error(err.message || 'Lỗi khi bắt đầu xuất Excel');
        throw err;
      }
    },
    [notify]
  );

  const startDailyMatrixExport = useCallback(
    async (params, customTitle = 'Ma trận xuất hàng theo ngày', customFileName = null) => {
      try {
        const res = await excelExportService.startDailyMatrix(params);
        if (!res || !res.jobId) {
          throw new Error('Máy chủ không phản hồi mã tác vụ (JobId)');
        }

        const newJob = {
          jobId: res.jobId,
          title: customTitle,
          type: 'matrix',
          status: res.status || 'queued',
          progressPercentage: res.progressPercentage || 0,
          message: res.message || 'Đang chuẩn bị hàng đợi...',
          fileName: customFileName || res.fileName,
          customFileName: customFileName,
          createdAt: new Date(),
        };

        setJobs((prev) => [newJob, ...prev]);
        setIsWidgetVisible(true);
        setIsWidgetExpanded(true);
        notify.info('Đã bắt đầu tác vụ xuất ngầm. Bạn có thể tiếp tục làm việc bình thường!');
        return res;
      } catch (err) {
        notify.error(err.message || 'Lỗi khi bắt đầu xuất Excel');
        throw err;
      }
    },
    [notify]
  );

  const startFullDbExport = useCallback(
    async (params, customTitle = 'Sao lưu toàn bộ cơ sở dữ liệu') => {
      try {
        const res = await excelExportService.startFullDb(params);
        if (!res || !res.jobId) {
          throw new Error('Máy chủ không phản hồi mã tác vụ (JobId)');
        }

        const newJob = {
          jobId: res.jobId,
          title: customTitle,
          type: 'full_db',
          status: res.status || 'queued',
          progressPercentage: res.progressPercentage || 0,
          message: res.message || 'Đang chuẩn bị hàng đợi...',
          fileName: res.fileName,
          createdAt: new Date(),
        };

        setJobs((prev) => [newJob, ...prev]);
        setIsWidgetVisible(true);
        setIsWidgetExpanded(true);
        notify.info('Đã bắt đầu tác vụ sao lưu DB. Dữ liệu đang được kết xuất ngầm...');
        return res;
      } catch (err) {
        notify.error(err.message || 'Lỗi khi bắt đầu sao lưu CSDL');
        throw err;
      }
    },
    [notify]
  );

  const updateJobFileName = useCallback((jobId, newFileName) => {
    setJobs((prev) =>
      prev.map((item) => {
        if (item.jobId !== jobId) return item;
        return {
          ...item,
          fileName: newFileName,
          customFileName: newFileName,
        };
      })
    );
  }, []);

  const downloadJob = useCallback(
    async (jobId, fallbackFileName, customFileName = null) => {
      try {
        const currentJob = jobsRef.current.find((j) => j.jobId === jobId);
        const targetName = customFileName || currentJob?.customFileName || fallbackFileName || currentJob?.fileName;
        await excelExportService.downloadFile(jobId, targetName, targetName);
        notify.success('Đang tải file xuống...');
      } catch (err) {
        notify.error(err.message || 'Không thể tải file xuất');
      }
    },
    [notify]
  );

  const dismissJob = useCallback((jobId) => {
    setJobs((prev) => prev.filter((j) => j.jobId !== jobId));
  }, []);

  const clearCompletedJobs = useCallback(() => {
    setJobs((prev) => prev.filter((j) => j.status === 'queued' || j.status === 'processing'));
  }, []);

  return (
    <ExportContext.Provider
      value={{
        jobs,
        isModalOpen,
        modalConfig,
        openExportModal,
        closeExportModal,
        startReportExport,
        startDailyMatrixExport,
        startFullDbExport,
        downloadJob,
        updateJobFileName,
        dismissJob,
        clearCompletedJobs,
        isWidgetVisible,
        setIsWidgetVisible,
        isWidgetExpanded,
        setIsWidgetExpanded,
      }}
    >
      {children}
    </ExportContext.Provider>
  );
}

export function useExport() {
  const context = useContext(ExportContext);
  if (!context) {
    throw new Error('useExport must be used within an ExportProvider');
  }
  return context;
}
