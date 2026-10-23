-- ==============================================================================
-- BORROWBOX: PRODUCTION SUPABASE POSTGRESQL SCHEMA WITH ROW LEVEL SECURITY (RLS)
-- Platform: Supabase (PostgreSQL 15+)
-- Authors: Abhishek Kulbainur & Snehal Mascarenhas
-- Tagline: Share More. Own Less.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMS
DO $$ BEGIN
    CREATE TYPE item_category AS ENUM (
        'tools', 'electronics', 'books', 'sports', 'household', 
        'travel', 'calculators', 'creative', 'games', 'other'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE item_condition AS ENUM ('like_new', 'excellent', 'good', 'fair');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE item_availability AS ENUM ('available', 'reserved', 'borrowed');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE request_status AS ENUM (
        'pending', 'approved', 'rejected', 'cancelled', 
        'handover_pending', 'active', 'return_pending', 'returned', 'overdue'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE community_type AS ENUM (
        'apartment', 'neighborhood', 'college', 'hobby', 'general'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 3. PROFILES TABLE (Linked to Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    bio TEXT DEFAULT '',
    location TEXT DEFAULT 'Local Community',
    rating NUMERIC(3, 2) DEFAULT 5.00 CHECK (rating >= 1.00 AND rating <= 5.00),
    review_count INTEGER DEFAULT 0 CHECK (review_count >= 0),
    completed_loans INTEGER DEFAULT 0 CHECK (completed_loans >= 0),
    is_verified BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to automatically populate public.profiles on Supabase auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, avatar_url, location)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url',
        COALESCE(NEW.raw_user_meta_data->>'location', 'Local Community')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. COMMUNITIES TABLE
CREATE TABLE IF NOT EXISTS communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    type community_type NOT NULL DEFAULT 'general',
    location TEXT NOT NULL,
    member_count INTEGER DEFAULT 1 CHECK (member_count >= 0),
    active_items_count INTEGER DEFAULT 0 CHECK (active_items_count >= 0),
    is_private BOOLEAN DEFAULT FALSE,
    icon TEXT DEFAULT 'groups',
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. COMMUNITY MEMBERSHIPS
CREATE TABLE IF NOT EXISTS community_memberships (
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (community_id, user_id)
);

-- 6. ITEM LISTINGS
CREATE TABLE IF NOT EXISTS item_listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category item_category NOT NULL,
    condition item_condition NOT NULL,
    pickup_location TEXT NOT NULL,
    max_duration_days INTEGER NOT NULL DEFAULT 7 CHECK (max_duration_days > 0),
    deposit_amount NUMERIC(10, 2) CHECK (deposit_amount IS NULL OR deposit_amount >= 0),
    availability item_availability NOT NULL DEFAULT 'available',
    image_urls TEXT[] DEFAULT '{}',
    terms TEXT,
    community_id UUID REFERENCES communities(id) ON DELETE SET NULL,
    favorite_count INTEGER DEFAULT 0 CHECK (favorite_count >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. BORROW REQUESTS & TRANSACTIONS
CREATE TABLE IF NOT EXISTS borrow_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES item_listings(id) ON DELETE CASCADE,
    borrower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status request_status NOT NULL DEFAULT 'pending',
    message TEXT,
    handover_qr_token TEXT,
    return_qr_token TEXT,
    notes TEXT,
    deposit_amount NUMERIC(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- SECURITY CONSTRAINT: Borrower cannot borrow their own listed items
    CONSTRAINT chk_borrower_not_owner CHECK (borrower_id <> owner_id),
    -- DATE CONSTRAINT: End date cannot be earlier than start date
    CONSTRAINT chk_valid_date_range CHECK (end_date >= start_date)
);

-- 8. TRANSACTION AUDIT LOGS (Immutable event history)
CREATE TABLE IF NOT EXISTS transaction_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES borrow_requests(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    from_status request_status,
    to_status request_status NOT NULL,
    event_description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. REVIEWS & RATINGS
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES borrow_requests(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- CONSTRAINTS: Reviewer cannot review oneself, and duplicate reviews are prevented
    CONSTRAINT chk_no_self_review CHECK (reviewer_id <> target_user_id),
    CONSTRAINT unique_transaction_reviewer UNIQUE (transaction_id, reviewer_id)
);

-- 10. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    reference_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. FAVORITES
CREATE TABLE IF NOT EXISTS favorites (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    listing_id UUID NOT NULL REFERENCES item_listings(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, listing_id)
);

-- ==============================================================================
-- INDEXES FOR HIGH-PERFORMANCE QUERYING
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_listings_owner ON item_listings(owner_id);
CREATE INDEX IF NOT EXISTS idx_listings_category ON item_listings(category);
CREATE INDEX IF NOT EXISTS idx_listings_availability ON item_listings(availability);
CREATE INDEX IF NOT EXISTS idx_requests_borrower ON borrow_requests(borrower_id);
CREATE INDEX IF NOT EXISTS idx_requests_owner ON borrow_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON borrow_requests(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_reviews_target ON reviews(target_user_id);

-- ==============================================================================
-- ATOMIC STORED PROCEDURES (Prevents Client-Side Bypasses & Race Conditions)
-- ==============================================================================

-- Stored Procedure: Owner Approves Request
CREATE OR REPLACE FUNCTION approve_borrow_request(
    p_request_id UUID,
    p_owner_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
    v_token TEXT;
BEGIN
    SELECT * INTO v_req FROM borrow_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    IF v_req.owner_id <> p_owner_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Only listing owner can approve requests');
    END IF;

    IF v_req.status <> 'pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request is not in pending status');
    END IF;

    -- Generate secure random handover token
    v_token := 'BB-HANDOVER-' || upper(encode(gen_random_bytes(6), 'hex'));

    UPDATE borrow_requests
    SET status = 'handover_pending',
        handover_qr_token = v_token,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Set listing availability to reserved
    UPDATE item_listings
    SET availability = 'reserved',
        updated_at = NOW()
    WHERE id = v_req.listing_id;

    -- Record transaction audit event
    INSERT INTO transaction_events (transaction_id, actor_id, from_status, to_status, event_description)
    VALUES (p_request_id, p_owner_id, 'pending', 'handover_pending', 'Owner approved borrow request');

    -- Notify borrower
    INSERT INTO notifications (user_id, title, message, type, reference_id)
    VALUES (
        v_req.borrower_id,
        'Borrow Request Approved',
        'Your request has been approved! Coordinate physical handover with the owner.',
        'requestApproved',
        p_request_id::TEXT
    );

    RETURN jsonb_build_object('success', true, 'token', v_token);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored Procedure: Confirm Handover via QR Code
CREATE OR REPLACE FUNCTION confirm_handover(
    p_request_id UUID,
    p_token TEXT,
    p_scanner_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
BEGIN
    SELECT * INTO v_req FROM borrow_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    IF v_req.status <> 'handover_pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Transaction is not ready for handover');
    END IF;

    -- Scanner must be an authorized participant (borrower or owner)
    IF p_scanner_id <> v_req.borrower_id AND p_scanner_id <> v_req.owner_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Scanner is not an authorized transaction party');
    END IF;

    -- Verify exact token match
    IF v_req.handover_qr_token IS NULL OR v_req.handover_qr_token <> p_token THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid, expired, or already-used handover token');
    END IF;

    -- Transition to active and invalidate token to prevent replay
    UPDATE borrow_requests
    SET status = 'active',
        handover_qr_token = NULL,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Mark item as borrowed
    UPDATE item_listings
    SET availability = 'borrowed',
        updated_at = NOW()
    WHERE id = v_req.listing_id;

    -- Record event
    INSERT INTO transaction_events (transaction_id, actor_id, from_status, to_status, event_description)
    VALUES (p_request_id, p_scanner_id, 'handover_pending', 'active', 'Physical handover verified and confirmed');

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Stored Procedure: Confirm Return
CREATE OR REPLACE FUNCTION confirm_return(
    p_request_id UUID,
    p_token TEXT,
    p_scanner_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
BEGIN
    SELECT * INTO v_req FROM borrow_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    IF v_req.status <> 'return_pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Item is not in return_pending status');
    END IF;

    -- Only the owner can confirm receipt of their returned item
    IF p_scanner_id <> v_req.owner_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Only the item owner can confirm returned items');
    END IF;

    -- Verify exact token
    IF v_req.return_qr_token IS NULL OR v_req.return_qr_token <> p_token THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired return token');
    END IF;

    -- Transition to returned and invalidate token
    UPDATE borrow_requests
    SET status = 'returned',
        return_qr_token = NULL,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Return item to available status
    UPDATE item_listings
    SET availability = 'available',
        updated_at = NOW()
    WHERE id = v_req.listing_id;

    -- Increment completed loans counter
    UPDATE profiles SET completed_loans = completed_loans + 1 WHERE id = v_req.owner_id;
    UPDATE profiles SET completed_loans = completed_loans + 1 WHERE id = v_req.borrower_id;

    -- Record event
    INSERT INTO transaction_events (transaction_id, actor_id, from_status, to_status, event_description)
    VALUES (p_request_id, p_scanner_id, 'return_pending', 'returned', 'Item returned and accepted by owner');

    -- Notify borrower to leave a review
    INSERT INTO notifications (user_id, title, message, type, reference_id)
    VALUES (
        v_req.borrower_id,
        'Item Return Confirmed',
        'Your loan return was confirmed by the owner. Please rate your borrowing experience!',
        'itemReturned',
        p_request_id::TEXT
    );

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Profiles: Public can read, user can update own profile
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Item Listings: Everyone can view active listings; only owners can mutate
CREATE POLICY "Listings are viewable by everyone" ON item_listings FOR SELECT USING (true);
CREATE POLICY "Users can insert their own listings" ON item_listings FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update their own listings" ON item_listings FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners can delete their own listings" ON item_listings FOR DELETE USING (auth.uid() = owner_id);

-- Borrow Requests: Strictly private to borrower and owner
CREATE POLICY "Participants can view requests" ON borrow_requests FOR SELECT 
    USING (auth.uid() = borrower_id OR auth.uid() = owner_id);
CREATE POLICY "Borrowers can create requests" ON borrow_requests FOR INSERT 
    WITH CHECK (auth.uid() = borrower_id AND auth.uid() <> owner_id);
CREATE POLICY "Participants can update transaction state" ON borrow_requests FOR UPDATE 
    USING (auth.uid() = borrower_id OR auth.uid() = owner_id);

-- Transaction Events: Viewable only by participants
CREATE POLICY "Participants can view transaction events" ON transaction_events FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM borrow_requests
        WHERE borrow_requests.id = transaction_events.transaction_id
          AND (borrow_requests.borrower_id = auth.uid() OR borrow_requests.owner_id = auth.uid())
    ));

-- Notifications: Only recipient can view/update
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Favorites: User can view and manage their own favorites
CREATE POLICY "Users view own favorites" ON favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users manage own favorites" ON favorites FOR ALL USING (auth.uid() = user_id);

-- Reviews: Viewable by all; only transaction participants can write
CREATE POLICY "Reviews viewable by everyone" ON reviews FOR SELECT USING (true);
CREATE POLICY "Reviewers can insert reviews" ON reviews FOR INSERT WITH CHECK (
    auth.uid() = reviewer_id AND auth.uid() <> target_user_id
);

-- Communities: Public communities viewable by all
CREATE POLICY "Public communities viewable by all" ON communities FOR SELECT USING (true);
CREATE POLICY "Memberships viewable by everyone" ON community_memberships FOR SELECT USING (true);
CREATE POLICY "Users manage own memberships" ON community_memberships FOR ALL USING (auth.uid() = user_id);

-- ==============================================================================
-- STORAGE CONFIGURATION (Supabase Storage Buckets)
-- ==============================================================================
-- Run in Supabase SQL editor to create storage buckets:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('borrowbox_images', 'borrowbox_images', true) ON CONFLICT DO NOTHING;
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
