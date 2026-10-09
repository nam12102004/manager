namespace DebtManager.Domain.Entities;

public class Product
{
    public int Id { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public string? Barcode { get; set; }
    public int? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public decimal UnitCost { get; set; } = 0;
    public decimal WholesalePrice { get; set; } = 0;
    public decimal RetailPrice { get; set; } = 0;

    public decimal StockWarehouse1 { get; set; } = 0;
    public decimal StockWarehouse2 { get; set; } = 0;
    public decimal StockWarehouse3 { get; set; } = 0;
    public string? WarehouseStocks { get; set; }
    public decimal TotalStock { get; set; } = 0;
    public decimal ReorderPoint { get; set; } = 0;

    public decimal GetWarehouseStock(string warehouse)
    {
        if (warehouse == "warehouse1") return StockWarehouse1;
        if (warehouse == "warehouse2") return StockWarehouse2;
        if (warehouse == "warehouse3") return StockWarehouse3;

        if (!string.IsNullOrWhiteSpace(WarehouseStocks))
        {
            try
            {
                var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, decimal>>(WarehouseStocks);
                if (dict != null && dict.TryGetValue(warehouse, out var val))
                    return val;
            }
            catch { }
        }
        return 0;
    }

    public void SetWarehouseStock(string warehouse, decimal quantity)
    {
        if (warehouse == "warehouse1")
        {
            StockWarehouse1 = quantity;
        }
        else if (warehouse == "warehouse2")
        {
            StockWarehouse2 = quantity;
        }
        else if (warehouse == "warehouse3")
        {
            StockWarehouse3 = quantity;
        }
        else
        {
            Dictionary<string, decimal> dict = new();
            if (!string.IsNullOrWhiteSpace(WarehouseStocks))
            {
                try
                {
                    dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, decimal>>(WarehouseStocks) ?? new();
                }
                catch { dict = new(); }
            }
            dict[warehouse] = quantity;
            WarehouseStocks = System.Text.Json.JsonSerializer.Serialize(dict);
        }

        // Recalculate TotalStock
        decimal extraTotal = 0;
        if (!string.IsNullOrWhiteSpace(WarehouseStocks))
        {
            try
            {
                var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, decimal>>(WarehouseStocks);
                if (dict != null)
                {
                    foreach (var kvp in dict)
                    {
                        if (kvp.Key != "warehouse1" && kvp.Key != "warehouse2" && kvp.Key != "warehouse3")
                            extraTotal += kvp.Value;
                    }
                }
            }
            catch { }
        }
        TotalStock = StockWarehouse1 + StockWarehouse2 + StockWarehouse3 + extraTotal;
    }

    public Dictionary<string, decimal> GetAllWarehouseStocks()
    {
        var dict = new Dictionary<string, decimal>
        {
            ["warehouse1"] = StockWarehouse1,
            ["warehouse2"] = StockWarehouse2,
            ["warehouse3"] = StockWarehouse3
        };

        if (!string.IsNullOrWhiteSpace(WarehouseStocks))
        {
            try
            {
                var extra = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, decimal>>(WarehouseStocks);
                if (extra != null)
                {
                    foreach (var kvp in extra)
                    {
                        dict[kvp.Key] = kvp.Value;
                    }
                }
            }
            catch { }
        }
        return dict;
    }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<StockHistory> StockHistories { get; set; } = new List<StockHistory>();
    public ICollection<ExportVoucherItem> ExportVoucherItems { get; set; } = new List<ExportVoucherItem>();
    public ICollection<ImportVoucherItem> ImportVoucherItems { get; set; } = new List<ImportVoucherItem>();
}
