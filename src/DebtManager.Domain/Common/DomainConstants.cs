namespace DebtManager.Domain.Common;

public static class DomainConstants
{
    public static class Warehouses
    {
        public const string Warehouse1 = "warehouse1";
        public const string Warehouse2 = "warehouse2";
        public const string Warehouse3 = "warehouse3";

        public static readonly string[] All = [Warehouse1, Warehouse2, Warehouse3];
    }

    public static class SourceTypes
    {
        public const string Import = "import";
        public const string Export = "export";
        public const string Receipt = "receipt";
        public const string Payment = "payment";
        public const string ManualAdjustment = "manual_adjustment";
    }

    public static class ReferenceTypes
    {
        public const string ExportVoucher = "export_voucher";
        public const string ImportVoucher = "import_voucher";
        public const string Receipt = "receipt";
        public const string Payment = "payment";
    }

    public static class VoucherStatuses
    {
        public const string Active = "active";
        public const string Confirmed = "confirmed";
        public const string Cancelled = "cancelled";
    }
}
