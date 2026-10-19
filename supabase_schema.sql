-- ============================================================================
-- 1. TẠO BẢNG LOCATIONS (Vị trí vật lý của tài liệu)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    latitude FLOAT8 NOT NULL,
    longitude FLOAT8 NOT NULL,
    address_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tạo Index tăng tốc độ truy vấn theo document_id
CREATE INDEX IF NOT EXISTS idx_locations_document_id ON public.locations(document_id);

-- Bật Row Level Security (RLS) cho locations
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Mọi user đã xác thực có thể xem vị trí tài liệu
DROP POLICY IF EXISTS "Authenticated users can view locations" ON public.locations;
CREATE POLICY "Authenticated users can view locations"
ON public.locations FOR SELECT
TO authenticated
USING (true);

-- Chủ sở hữu tài liệu mới có thể thêm/sửa/xóa vị trí
DROP POLICY IF EXISTS "Owners can manage locations" ON public.locations;
CREATE POLICY "Owners can manage locations"
ON public.locations FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.documents d
        WHERE d.id = locations.document_id 
          AND d.owner_id = auth.uid()
    )
);


-- ============================================================================
-- 2. TẠO BẢNG BORROW_REQUESTS (Yêu cầu mượn tài liệu)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.borrow_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Các Index tối ưu hiệu năng tìm kiếm
CREATE INDEX IF NOT EXISTS idx_borrow_requests_requester ON public.borrow_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_owner ON public.borrow_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_document ON public.borrow_requests(document_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_status ON public.borrow_requests(status);


-- ============================================================================
-- 3. CẤU HÌNH ROW LEVEL SECURITY (RLS) CHO BORROW_REQUESTS
-- ============================================================================
ALTER TABLE public.borrow_requests ENABLE ROW LEVEL SECURITY;

-- 3.1. Requester: Tạo yêu cầu mượn mới (INSERT)
DROP POLICY IF EXISTS "Requester can insert borrow requests" ON public.borrow_requests;
CREATE POLICY "Requester can insert borrow requests"
ON public.borrow_requests FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = requester_id);

-- 3.2. Requester: Xem lại các yêu cầu do chính mình gửi (SELECT)
DROP POLICY IF EXISTS "Requester can view own requests" ON public.borrow_requests;
CREATE POLICY "Requester can view own requests"
ON public.borrow_requests FOR SELECT
TO authenticated
USING (auth.uid() = requester_id);

-- 3.3. Owner: Xem các yêu cầu gửi đến các tài liệu thuộc sở hữu của mình (SELECT)
DROP POLICY IF EXISTS "Owner can view received requests" ON public.borrow_requests;
CREATE POLICY "Owner can view received requests"
ON public.borrow_requests FOR SELECT
TO authenticated
USING (auth.uid() = owner_id);

-- 3.4. Owner: Có quyền cập nhật trạng thái (Duyệt/Từ chối) (UPDATE)
DROP POLICY IF EXISTS "Owner can update request status" ON public.borrow_requests;
CREATE POLICY "Owner can update request status"
ON public.borrow_requests FOR UPDATE
TO authenticated
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);


-- ============================================================================
-- 4. DATABASE FUNCTION TÍNH GỢI Ý TÀI LIỆU (RECOMMENDATION)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_document_recommendations(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    file_url TEXT,
    file_type TEXT,
    file_size BIGINT,
    tags TEXT[],
    matched_tag_count BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH borrowed_doc_ids AS (
        -- 1. Lấy danh sách ID các tài liệu user đã từng mượn
        SELECT DISTINCT br.document_id
        FROM borrow_requests br
        WHERE br.requester_id = p_user_id
    ),
    user_borrowed_tags AS (
        -- 2. Tách và lấy danh sách các tag duy nhất từ các tài liệu đã mượn
        SELECT DISTINCT unnest(d.tags) AS tag
        FROM documents d
        JOIN borrowed_doc_ids b ON d.id = b.document_id
        WHERE d.tags IS NOT NULL AND cardinality(d.tags) > 0
    ),
    candidate_documents AS (
        -- 3. Tìm các tài liệu chưa mượn, có chứa tag trùng khớp và đếm số lượng tag trùng
        SELECT 
            d.id,
            d.title,
            d.file_url,
            d.file_type,
            d.file_size::BIGINT,
            d.tags,
            COUNT(DISTINCT dt.tag) AS matched_count
        FROM documents d
        CROSS JOIN LATERAL unnest(d.tags) AS dt(tag)
        JOIN user_borrowed_tags ubt ON dt.tag = ubt.tag
        WHERE d.id NOT IN (SELECT document_id FROM borrowed_doc_ids)
          AND d.owner_id != p_user_id -- Không gợi ý tài liệu do chính mình tạo
        GROUP BY d.id, d.title, d.file_url, d.file_type, d.file_size, d.tags
    )
    -- 4. Sắp xếp giảm dần theo số lượng tag khớp và lấy tối đa 10 tài liệu
    SELECT 
        cd.id,
        cd.title,
        cd.file_url,
        cd.file_type,
        cd.file_size,
        cd.tags,
        cd.matched_count AS matched_tag_count
    FROM candidate_documents cd
    ORDER BY cd.matched_count DESC, cd.id DESC
    LIMIT 10;
END;
$$;

-- Alias cho tên hàm get_recommended_documents
CREATE OR REPLACE FUNCTION get_recommended_documents(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    file_url TEXT,
    file_type TEXT,
    file_size BIGINT,
    tags TEXT[],
    matched_tag_count BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM get_document_recommendations(p_user_id);
END;
$$;
