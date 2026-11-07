namespace DebtManager.Application.Common;

/// <summary>
/// Parses the "priorityMetrics" list query parameter sent by the customer/supplier list screens.
/// Format: comma separated tokens "metric" or "metric:warehouse", e.g. "export:all,export:warehouse1,receipt,debt:warehouse2".
/// Records having data for any ticked metric are listed first.
/// </summary>
public sealed class PriorityMetrics
{
    public const string AllWarehouses = "all";

    private readonly Dictionary<string, HashSet<string>> _metrics;

    private PriorityMetrics(Dictionary<string, HashSet<string>> metrics) => _metrics = metrics;

    public bool IsEmpty => _metrics.Count == 0;

    /// <summary>Returns the warehouses requested for a metric ("all" means every warehouse), or an empty set if not requested.</summary>
    public IReadOnlyCollection<string> Get(string metric)
        => _metrics.TryGetValue(metric, out var set) ? set : Array.Empty<string>();

    public bool Has(string metric) => _metrics.ContainsKey(metric);

    public static PriorityMetrics Parse(string? raw)
    {
        var dict = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);
        if (!string.IsNullOrWhiteSpace(raw))
        {
            foreach (var token in raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                var parts = token.Split(':', 2, StringSplitOptions.TrimEntries);
                var metric = parts[0].ToLowerInvariant();
                if (metric.Length == 0) continue;
                var warehouse = parts.Length > 1 && parts[1].Length > 0 ? parts[1].ToLowerInvariant() : AllWarehouses;
                if (!dict.TryGetValue(metric, out var set))
                {
                    set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    dict[metric] = set;
                }
                set.Add(warehouse);
            }
        }
        return new PriorityMetrics(dict);
    }

    public static (DateTime? Start, DateTime? End) ParseDateRange(string? fromDate, string? toDate)
    {
        DateTime? start = null;
        DateTime? end = null;
        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
        }
        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
        }
        return (start, end);
    }
}
