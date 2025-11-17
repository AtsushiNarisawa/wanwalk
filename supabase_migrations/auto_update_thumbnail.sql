-- ====================================================================
-- Auto-update thumbnail_url when route_photos are inserted
-- ====================================================================
-- Purpose: Automatically set the first photo as the route's thumbnail
-- Trigger: Fires AFTER INSERT on route_photos table
-- ====================================================================

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS trg_auto_update_thumbnail ON public.route_photos;
DROP FUNCTION IF EXISTS fn_auto_update_thumbnail();

-- Create function to update thumbnail_url
CREATE OR REPLACE FUNCTION fn_auto_update_thumbnail()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the route's thumbnail_url with the first photo's storage_path
    -- Only update if the route doesn't have a thumbnail yet, or if this is the first photo
    UPDATE public.routes
    SET thumbnail_url = NEW.storage_path
    WHERE id = NEW.route_id
    AND (
        thumbnail_url IS NULL  -- No thumbnail set yet
        OR NEW.display_order = 0  -- This is explicitly the first photo
        OR NOT EXISTS (  -- Or this is the earliest photo
            SELECT 1 
            FROM public.route_photos 
            WHERE route_id = NEW.route_id 
            AND id != NEW.id
            AND (display_order < NEW.display_order OR created_at < NEW.created_at)
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on route_photos table
CREATE TRIGGER trg_auto_update_thumbnail
    AFTER INSERT ON public.route_photos
    FOR EACH ROW
    EXECUTE FUNCTION fn_auto_update_thumbnail();

-- Add comment for documentation
COMMENT ON FUNCTION fn_auto_update_thumbnail() IS 
'Automatically updates routes.thumbnail_url when a photo is added to route_photos. 
Sets the thumbnail to the first photo (by display_order or created_at).';

-- ====================================================================
-- Test the trigger (optional - can be run to verify)
-- ====================================================================
-- SELECT 
--     r.id, 
--     r.title, 
--     r.thumbnail_url,
--     COUNT(rp.id) as photo_count
-- FROM public.routes r
-- LEFT JOIN public.route_photos rp ON r.id = rp.route_id
-- WHERE r.is_public = true
-- GROUP BY r.id, r.title, r.thumbnail_url;
-- ====================================================================
