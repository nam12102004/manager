import { exportApi } from '../api/endpoints';

/**
 * Service for managing background streamed Excel exports
 */
export const excelExportService = {
  /**
   * Start a customizable report export (sales, purchases, inout, cashflow, debt)
   */
  async startReport(params) {
    return await exportApi.startReport(params);
  },

  /**
   * Start a daily matrix export (Days 1..31 for Revenue and Quantity)
   */
  async startDailyMatrix(params) {
    return await exportApi.startMatrix(params);
  },

  /**
   * Start a full database multi-sheet export
   */
  async startFullDb(params) {
    return await exportApi.startFullDb(params);
  },

  /**
   * Check status of a running export job
   */
  async getStatus(jobId) {
    return await exportApi.getStatus(jobId);
  },

  /**
   * Download the generated Excel file by Job ID
   */
  async downloadFile(jobId, defaultFileName = 'BaoCao_Export.xlsx', customFileName = null) {
    const response = await exportApi.downloadFile(jobId);
    
    // Determine filename: prefer customFileName if provided
    let filename = (customFileName && customFileName.trim()) || defaultFileName;
    if (!customFileName) {
      const disposition = response.headers?.['content-disposition'];
      if (disposition && disposition.includes('filename=')) {
        const match = disposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
        if (match && match[1]) {
          filename = match[1].replace(/['"]/g, '');
        }
      }
    }

    // Ensure valid extension
    if (!filename.toLowerCase().endsWith('.xlsx') && !filename.toLowerCase().endsWith('.csv')) {
      filename += '.xlsx';
    }

    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
    return filename;
  },
};
