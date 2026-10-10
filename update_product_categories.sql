-- Update Product Categories
-- Gắn 5 danh mục ngẫu nhiên cho tất cả sản phẩm

WITH CategoryAssignment AS (
  SELECT 
    "Id",
    CASE (row_number() OVER (ORDER BY "Id")) % 5
      WHEN 0 THEN 'Nước uống & Đồ uống'
      WHEN 1 THEN 'Hóa mỹ phẩm & Chăm sóc'
      WHEN 2 THEN 'Thực phẩm & Gia vị'
      WHEN 3 THEN 'Điện tử & Phụ kiện'
      WHEN 4 THEN 'Vật liệu & Công cụ'
    END AS new_category
  FROM "Products"
)
UPDATE "Products" p
SET "Category" = ca.new_category
FROM CategoryAssignment ca
WHERE p."Id" = ca."Id"
  AND (p."Category" IS NULL OR p."Category" = '');
