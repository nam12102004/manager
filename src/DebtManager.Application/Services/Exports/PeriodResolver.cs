using System.Globalization;
using DebtManager.Application.DTOs.Exports;
using DebtManager.Application.Interfaces.Repositories;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services.Exports;

public static class PeriodResolver
{
    public static async Task<(DateTime Start, DateTime EndExclusive, string Label)> ResolveAsync(
        PeriodDto period,
        string reportType,
        IUnitOfWork uow,
        CancellationToken ct = default)
    {
        var mode = (period.Mode ?? "month").ToLowerInvariant();

        switch (mode)
        {
            case "day":
            {
                if (DateTime.TryParseExact(period.Date?.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d))
                {
                    var start = DateTime.SpecifyKind(d.Date, DateTimeKind.Utc);
                    return (start, start.AddDays(1), $"Ngay_{start:ddMMyyyy}");
                }
                var today = DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);
                return (today, today.AddDays(1), $"Ngay_{today:ddMMyyyy}");
            }

            case "dayrange":
            {
                var fOk = DateTime.TryParseExact(period.FromDate?.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var f);
                var tOk = DateTime.TryParseExact(period.ToDate?.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var t);

                var start = fOk ? DateTime.SpecifyKind(f.Date, DateTimeKind.Utc) : DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);
                var end = tOk ? DateTime.SpecifyKind(t.Date.AddDays(1), DateTimeKind.Utc) : start.AddDays(1);

                if (end < start)
                {
                    (start, end) = (end.AddDays(-1), start.AddDays(1));
                }

                return (start, end, $"Tu_{start:ddMMyyyy}_Den_{end.AddDays(-1):ddMMyyyy}");
            }

            case "monthrange":
            {
                var fOk = DateTime.TryParseExact(period.FromMonth?.Trim(), "yyyy-MM", CultureInfo.InvariantCulture, DateTimeStyles.None, out var f);
                var tOk = DateTime.TryParseExact(period.ToMonth?.Trim(), "yyyy-MM", CultureInfo.InvariantCulture, DateTimeStyles.None, out var t);

                var start = fOk ? new DateTime(f.Year, f.Month, 1, 0, 0, 0, DateTimeKind.Utc) : new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var toMonthStart = tOk ? new DateTime(t.Year, t.Month, 1, 0, 0, 0, DateTimeKind.Utc) : start;
                var end = toMonthStart.AddMonths(1);

                if (end < start)
                {
                    (start, end) = (toMonthStart, start.AddMonths(1));
                }

                return (start, end, $"Thang_{start:MM_yyyy}_Den_{end.AddMonths(-1):MM_yyyy}");
            }

            case "year":
            {
                var year = period.Year.GetValueOrDefault(DateTime.UtcNow.Year);
                if (year < 2000 || year > 2100) year = DateTime.UtcNow.Year;

                var start = new DateTime(year, 1, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = new DateTime(year + 1, 1, 1, 0, 0, 0, DateTimeKind.Utc);
                return (start, end, $"Nam_{year}");
            }

            case "all":
            {
                var earliest = await FindEarliestDateAsync(reportType, uow, ct);
                var start = new DateTime(earliest.Year, earliest.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var now = DateTime.UtcNow;
                var end = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(1);

                if (end <= start) end = start.AddMonths(1);
                return (start, end, "Toan_Bo");
            }

            case "month":
            default:
            {
                var monthStr = !string.IsNullOrWhiteSpace(period.Month) ? period.Month.Trim() : DateTime.UtcNow.ToString("yyyy-MM");
                if (DateTime.TryParseExact(monthStr, "yyyy-MM", CultureInfo.InvariantCulture, DateTimeStyles.None, out var m))
                {
                    var start = new DateTime(m.Year, m.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    return (start, start.AddMonths(1), $"Thang_{start:MM_yyyy}");
                }
                var cur = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                return (cur, cur.AddMonths(1), $"Thang_{cur:MM_yyyy}");
            }
        }
    }

    private static async Task<DateTime> FindEarliestDateAsync(string reportType, IUnitOfWork uow, CancellationToken ct)
    {
        DateTime? earliest = null;

        switch (reportType.ToLowerInvariant())
        {
            case "purchases":
                earliest = await uow.ImportVouchers.Query()
                    .Where(v => v.Status != "cancelled")
                    .OrderBy(v => v.Date)
                    .Select(v => (DateTime?)v.Date)
                    .FirstOrDefaultAsync(ct);
                break;

            case "inout":
                var eExp = await uow.ExportVouchers.Query()
                    .Where(v => v.Status != "cancelled")
                    .OrderBy(v => v.Date)
                    .Select(v => (DateTime?)v.Date)
                    .FirstOrDefaultAsync(ct);
                var eImp = await uow.ImportVouchers.Query()
                    .Where(v => v.Status != "cancelled")
                    .OrderBy(v => v.Date)
                    .Select(v => (DateTime?)v.Date)
                    .FirstOrDefaultAsync(ct);
                if (eExp.HasValue && eImp.HasValue) earliest = eExp < eImp ? eExp : eImp;
                else earliest = eExp ?? eImp;
                break;

            case "cashflow":
                var eRec = await uow.Receipts.Query()
                    .OrderBy(r => r.Date)
                    .Select(r => (DateTime?)r.Date)
                    .FirstOrDefaultAsync(ct);
                var ePay = await uow.Payments.Query()
                    .Where(p => p.Status != "cancelled")
                    .OrderBy(p => p.Date)
                    .Select(p => (DateTime?)p.Date)
                    .FirstOrDefaultAsync(ct);
                if (eRec.HasValue && ePay.HasValue) earliest = eRec < ePay ? eRec : ePay;
                else earliest = eRec ?? ePay;
                break;

            case "debt":
                var eCustDebt = await uow.CustomerDebtHistories.Query()
                    .OrderBy(h => h.CreatedAt)
                    .Select(h => (DateTime?)h.CreatedAt)
                    .FirstOrDefaultAsync(ct);
                var eSuppDebt = await uow.SupplierDebtHistories.Query()
                    .OrderBy(h => h.CreatedAt)
                    .Select(h => (DateTime?)h.CreatedAt)
                    .FirstOrDefaultAsync(ct);
                if (eCustDebt.HasValue && eSuppDebt.HasValue) earliest = eCustDebt < eSuppDebt ? eCustDebt : eSuppDebt;
                else earliest = eCustDebt ?? eSuppDebt;
                break;

            case "employee_sales":
            case "sales":
            default:
                earliest = await uow.ExportVouchers.Query()
                    .Where(v => v.Status != "cancelled")
                    .OrderBy(v => v.Date)
                    .Select(v => (DateTime?)v.Date)
                    .FirstOrDefaultAsync(ct);
                break;
        }

        return earliest ?? DateTime.UtcNow.AddYears(-1);
    }
}
