namespace DebtManager.Application.Services.Exports;

public class TimeBucket
{
    public int Index { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Header { get; set; } = string.Empty;
    public DateTime Start { get; set; }
    public DateTime EndExclusive { get; set; }
}

public static class BucketBuilder
{
    public const int MaxBucketsAllowed = 370;

    public static List<TimeBucket> Build(DateTime rangeStart, DateTime rangeEndExclusive, string granularity)
    {
        var gran = (granularity ?? "day").ToLowerInvariant();
        var buckets = new List<TimeBucket>();

        if (rangeEndExclusive <= rangeStart)
        {
            rangeEndExclusive = rangeStart.AddDays(1);
        }

        switch (gran)
        {
            case "week":
            {
                var cur = rangeStart;
                int idx = 0;

                while (cur < rangeEndExclusive)
                {
                    // Find next Monday 00:00:00
                    int daysUntilNextMonday = ((int)DayOfWeek.Monday - (int)cur.DayOfWeek + 7) % 7;
                    if (daysUntilNextMonday == 0) daysUntilNextMonday = 7;

                    var nextMonday = cur.Date.AddDays(daysUntilNextMonday);
                    var bStart = cur;
                    var bEnd = nextMonday < rangeEndExclusive ? nextMonday : rangeEndExclusive;

                    var lastDayOfBucket = bEnd.AddDays(-1);
                    if (lastDayOfBucket < bStart) lastDayOfBucket = bStart;

                    var header = bStart.Date == lastDayOfBucket.Date
                        ? bStart.ToString("dd/MM")
                        : $"{bStart:dd/MM} - {lastDayOfBucket:dd/MM}";

                    buckets.Add(new TimeBucket
                    {
                        Index = idx++,
                        Key = $"w_{bStart:yyyyMMdd}",
                        Header = header,
                        Start = bStart,
                        EndExclusive = bEnd
                    });

                    cur = bEnd;
                    if (buckets.Count > MaxBucketsAllowed) break;
                }
                break;
            }

            case "month":
            {
                var cur = rangeStart;
                int idx = 0;

                while (cur < rangeEndExclusive)
                {
                    var firstOfNextMonth = new DateTime(cur.Year, cur.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(1);
                    var bStart = cur;
                    var bEnd = firstOfNextMonth < rangeEndExclusive ? firstOfNextMonth : rangeEndExclusive;

                    buckets.Add(new TimeBucket
                    {
                        Index = idx++,
                        Key = $"m_{bStart:yyyyMM}",
                        Header = bStart.ToString("MM/yyyy"),
                        Start = bStart,
                        EndExclusive = bEnd
                    });

                    cur = bEnd;
                    if (buckets.Count > MaxBucketsAllowed) break;
                }
                break;
            }

            case "day":
            default:
            {
                var cur = rangeStart.Date;
                int idx = 0;

                while (cur < rangeEndExclusive)
                {
                    var bStart = cur;
                    var bEnd = cur.AddDays(1);

                    buckets.Add(new TimeBucket
                    {
                        Index = idx++,
                        Key = $"d_{bStart:yyyyMMdd}",
                        Header = bStart.ToString("dd/MM"),
                        Start = bStart,
                        EndExclusive = bEnd
                    });

                    cur = bEnd;
                    if (buckets.Count > MaxBucketsAllowed) break;
                }
                break;
            }
        }

        return buckets;
    }

    public static int FindBucketIndex(List<TimeBucket> buckets, DateTime date)
    {
        // Linear scan is very fast for <= 370 elements
        for (int i = 0; i < buckets.Count; i++)
        {
            if (date >= buckets[i].Start && date < buckets[i].EndExclusive)
            {
                return i;
            }
        }
        return -1;
    }
}
